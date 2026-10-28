; Multiplicacion interactiva en formato fijo Q8.8 para LC-3.
; Las entradas se escriben como numeros decimales con hasta una cifra
; decimal, por ejemplo 10.5. Internamente se almacenan como valor * 256.
; El producto se guarda como Q16.16 en dos palabras R1:R0.

.ORIG x3000

        BR      INICIO

OPERANDO_A:      .FILL #0
RESULTADO_BAJO:  .FILL #0
RESULTADO_ALTO:  .FILL #0

INICIO:
        LEA     R0, MENSAJE_A
        PUTS
        JSR     LEER_Q8_8
        ST      R0, OPERANDO_A

        LEA     R0, MENSAJE_B
        PUTS
        JSR     LEER_Q8_8
        ADD     R2, R0, #0
        LD      R0, OPERANDO_A
        JSR     MULTIPLICAR_Q8_8

        LEA     R6, RESULTADO_BAJO
        STR     R0, R6, #0
        LEA     R6, RESULTADO_ALTO
        STR     R1, R6, #0

        LEA     R0, MENSAJE_ALTO
        PUTS
        ADD     R0, R1, #0
        JSR     IMPRIMIR_HEX

        LEA     R0, MENSAJE_BAJO
        PUTS
        LD      R0, RESULTADO_BAJO
        JSR     IMPRIMIR_HEX

        LEA     R0, MENSAJE_ESCALA
        PUTS
        LEA     R0, MENSAJE_FIN
        PUTS
        HALT

MENSAJE_A:       .STRINGZ "\nIngrese el primer valor (Q8.8, ejemplo 12.3): "
MENSAJE_B:       .STRINGZ "\nIngrese el segundo valor (Q8.8, ejemplo 14.5): "
MENSAJE_ALTO:    .STRINGZ "\nProducto Q16.16 alto: x"
MENSAJE_BAJO:    .STRINGZ "\nProducto Q16.16 bajo: x"
MENSAJE_ESCALA:  .STRINGZ "\nEl producto usa 16 bits fraccionarios (/65536).\n"
MENSAJE_FIN:     .STRINGZ "Fin del programa.\n"
MENSAJE_ERROR:   .STRINGZ "\nEntrada invalida. Use, por ejemplo, 10.5\n"
FRACCIONES_Q:    .FILL #0
                 .FILL #26
                 .FILL #51
                 .FILL #77
                 .FILL #102
                 .FILL #128
                 .FILL #154
                 .FILL #179
                 .FILL #205
                 .FILL #230
ASCII_CERO:      .FILL x0030
ASCII_MENOS:     .FILL x002D
ASCII_PUNTO:     .FILL x002E
RETORNO_LEER:    .FILL #0

; -----------------------------------------------------------------
; LEER_Q8_8
; Lee entero o entero.decima, con signo.
; La decima se convierte a la fraccion binaria mas cercana por defecto.
; Ejemplo: 10.5 -> 10 * 256 + 128 = x0A80.
; Salida: R0 = valor Q8.8 en complemento a dos.
; -----------------------------------------------------------------
LEER_Q8_8:
        ST      R7, RETORNO_LEER
LEER_Q_REINICIAR:
        AND     R1, R1, #0      ; parte entera decimal
        AND     R2, R2, #0      ; signo
        AND     R3, R3, #0      ; fraccion Q
        GETC
        OUT
        LD      R5, ASCII_MENOS
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5
        BRz     LEER_Q_NEGATIVO
        BR      LEER_Q_ENTERO

LEER_Q_NEGATIVO:
        ADD     R2, R2, #1
        GETC
        OUT

LEER_Q_ENTERO:
        ADD     R4, R0, #-10
        BRz     LEER_Q_ESCALAR
        ADD     R4, R0, #-13
        BRz     LEER_Q_ESCALAR
        LD      R5, ASCII_PUNTO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5
        BRz     LEER_Q_FRACCION
        LD      R5, ASCII_CERO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5
        BRn     LEER_Q_INVALIDO
        ADD     R5, R4, #-10
        BRzp    LEER_Q_INVALIDO
        ADD     R3, R4, #0
        ADD     R4, R1, #0
        ADD     R1, R1, R1
        ADD     R1, R1, R1
        ADD     R1, R1, R1
        ADD     R4, R4, R4
        ADD     R1, R1, R4
        ADD     R1, R1, R3
        GETC
        OUT
        BR      LEER_Q_ENTERO

LEER_Q_FRACCION:
        GETC
        OUT
        LD      R5, ASCII_CERO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5
        BRn     LEER_Q_INVALIDO
        ADD     R5, R4, #-10
        BRzp    LEER_Q_INVALIDO
        LEA     R5, FRACCIONES_Q
        ADD     R5, R5, R4
        LDR     R3, R5, #0
        GETC
        OUT
        ADD     R4, R0, #-10
        BRz     LEER_Q_ESCALAR
        ADD     R4, R0, #-13
        BRz     LEER_Q_ESCALAR
        BR      LEER_Q_INVALIDO

LEER_Q_ESCALAR:
        AND     R4, R4, #0
        ADD     R4, R4, #8
LEER_Q_SHIFT:
        ADD     R1, R1, R1
        ADD     R4, R4, #-1
        BRp     LEER_Q_SHIFT
        ADD     R1, R1, R3
        ADD     R2, R2, #0
        BRz     LEER_Q_POSITIVO
        NOT     R1, R1
        ADD     R1, R1, #1
LEER_Q_POSITIVO:
        ADD     R0, R1, #0
        LD      R7, RETORNO_LEER
        RET

LEER_Q_INVALIDO:
        GETC
        ADD     R4, R0, #-10
        BRz     LEER_Q_MOSTRAR_ERROR
        ADD     R4, R0, #-13
        BRnp    LEER_Q_INVALIDO
LEER_Q_MOSTRAR_ERROR:
        LEA     R0, MENSAJE_ERROR
        PUTS
        BR      LEER_Q_REINICIAR

; -----------------------------------------------------------------
; MULTIPLICAR_Q8_8
; Multiplica dos valores Q8.8 como enteros escalados.
; Entrada: R0 y R2 en Q8.8.
; Salida: R1:R0 en Q16.16.
; -----------------------------------------------------------------
SIGNO:           .FILL #0
RETORNO_MULT:    .FILL #0

MULTIPLICAR_Q8_8:
        ST      R7, RETORNO_MULT
        AND     R6, R6, #0
        ADD     R3, R0, #0
        ADD     R5, R3, #0
        BRzp    MULT_A_POS
        NOT     R3, R3
        ADD     R3, R3, #1
        ADD     R6, R6, #1
MULT_A_POS:
        ADD     R5, R2, #0
        BRzp    MULT_B_POS
        NOT     R2, R2
        ADD     R2, R2, #1
        ADD     R6, R6, #0
        BRz     MULT_SOLO_B_NEG
        AND     R6, R6, #0
        BR      MULT_B_POS
MULT_SOLO_B_NEG:
        ADD     R6, R6, #1
MULT_B_POS:
        LEA     R7, SIGNO
        STR     R6, R7, #0
        AND     R0, R0, #0
        AND     R1, R1, #0
        AND     R4, R4, #0
        AND     R7, R7, #0
        ADD     R7, R7, #1
        AND     R5, R5, #0
        ADD     R5, R5, #15
        ADD     R5, R5, #1
MULT_BUCLE:
        AND     R6, R2, R7
        BRz     MULT_SHIFT
        ADD     R6, R0, #0
        ADD     R0, R0, R3
        ADD     R6, R6, #0
        BRn     MULT_ANT_NEG
        ADD     R3, R3, #0
        BRn     MULT_POS_NEG
        ADD     R0, R0, #0
        BRn     MULT_CARRY
        BR      MULT_SHIFT
MULT_POS_NEG:
        ADD     R0, R0, #0
        BRzp    MULT_CARRY
        BR      MULT_SHIFT
MULT_ANT_NEG:
        ADD     R3, R3, #0
        BRn     MULT_CARRY
        ADD     R0, R0, #0
        BRzp    MULT_CARRY
        BR      MULT_SHIFT
MULT_CARRY:
        ADD     R1, R1, #1
MULT_SHIFT:
        ADD     R6, R3, #0
        ADD     R3, R3, R3
        ADD     R4, R4, R4
        ADD     R6, R6, #0
        BRzp    MULT_NO_SHIFT_CARRY
        ADD     R4, R4, #1
MULT_NO_SHIFT_CARRY:
        ADD     R7, R7, R7
        ADD     R5, R5, #-1
        BRp     MULT_BUCLE
        LEA     R6, SIGNO
        LDR     R6, R6, #0
        ADD     R6, R6, #0
        BRz     MULT_FIN
        NOT     R0, R0
        NOT     R1, R1
        ADD     R0, R0, #1
        BRnp    MULT_FIN
        ADD     R1, R1, #1
MULT_FIN:
        LD      R7, RETORNO_MULT
        RET

DIGITOS_HEX:     .STRINGZ "0123456789ABCDEF"
RETORNO_HEX:     .FILL #0

IMPRIMIR_HEX:
        ST      R7, RETORNO_HEX
        ADD     R5, R0, #0
        AND     R1, R1, #0
        ADD     R1, R1, #4
HEX_DIGITO:
        AND     R2, R2, #0
        ADD     R3, R5, #0
        AND     R4, R4, #0
        ADD     R4, R4, #4
HEX_BIT:
        ADD     R2, R2, R2
        ADD     R3, R3, #0
        BRzp    HEX_CERO
        ADD     R2, R2, #1
HEX_CERO:
        ADD     R3, R3, R3
        ADD     R4, R4, #-1
        BRp     HEX_BIT
        AND     R4, R4, #0
        ADD     R4, R4, #4
HEX_SHIFT:
        ADD     R5, R5, R5
        ADD     R4, R4, #-1
        BRp     HEX_SHIFT
        LEA     R3, DIGITOS_HEX
        ADD     R3, R3, R2
        LDR     R0, R3, #0
        OUT
        ADD     R1, R1, #-1
        BRp     HEX_DIGITO
        LD      R7, RETORNO_HEX
        RET

.END
