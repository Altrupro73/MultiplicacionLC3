; Multiplicacion interactiva de enteros con signo para LC-3.
; Se introducen dos valores decimales por consola.
; El resultado de 32 bits se muestra como palabra alta y palabra baja.

.ORIG x3000

        BR      INICIO

MENSAJE_A:      .STRINGZ "\nIngrese el primer numero: "
MENSAJE_B:      .STRINGZ "\nIngrese el segundo numero: "
MENSAJE_ALTO:   .STRINGZ "\nResultado alto: x"
MENSAJE_BAJO:   .STRINGZ "\nResultado bajo: x"
MENSAJE_FIN:    .STRINGZ "\nFin del programa.\n"
MENSAJE_ERROR:  .STRINGZ "\nEntrada invalida. Intente de nuevo: "
DIGITOS_HEX:    .STRINGZ "0123456789ABCDEF"
ASCII_CERO:     .FILL x0030
ASCII_MENOS:    .FILL x002D
OPERANDO_A:     .FILL #0
RESULTADO_BAJO: .FILL #0
RESULTADO_ALTO: .FILL #0
SIGNO:          .FILL #0
RETORNO_LEER:   .FILL #0
RETORNO_MULT:   .FILL #0
RETORNO_HEX:    .FILL #0

INICIO:
        LEA     R0, MENSAJE_A
        PUTS
        JSR     LEER_NUMERO
        ST      R0, OPERANDO_A  ; guardar primer operando

        LEA     R0, MENSAJE_B
        PUTS
        JSR     LEER_NUMERO
        ADD     R2, R0, #0      ; segundo operando
        LD      R0, OPERANDO_A  ; primer operando para MULTIPLICAR
        JSR     MULTIPLICAR

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

        LEA     R0, MENSAJE_FIN
        PUTS
        HALT

; -----------------------------------------------------------------
; LEER_NUMERO
; Lee un entero decimal con signo hasta ENTER.
; Salida: R0 = valor de 16 bits en complemento a dos.
; -----------------------------------------------------------------
LEER_NUMERO:
        ST      R7, RETORNO_LEER

LEER_REINICIAR:
        AND     R1, R1, #0      ; acumulador
        AND     R2, R2, #0      ; signo: 0 positivo, 1 negativo
        GETC
        OUT
        LD      R5, ASCII_MENOS
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R3, R0, R5      ; comprobar '-'
        BRz     LEER_NEGATIVO
        BR      LEER_CARACTER

LEER_NEGATIVO:
        ADD     R2, R2, #1
        GETC
        OUT

LEER_CARACTER:
        ADD     R3, R0, #-10    ; LF
        BRz     LEER_TERMINAR
        ADD     R3, R0, #-13    ; CR
        BRz     LEER_TERMINAR

        LD      R5, ASCII_CERO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R3, R0, R5      ; caracter - '0'
        BRn     LEER_INVALIDO
        ADD     R3, R3, #-10
        BRzp    LEER_INVALIDO

        ADD     R3, R0, R5      ; digito numerico
        ADD     R4, R1, #0      ; guardar acumulador original
        ADD     R1, R1, R1      ; x2
        ADD     R1, R1, R1      ; x4
        ADD     R1, R1, R1      ; x8
        ADD     R4, R4, R4      ; x2
        ADD     R1, R1, R4      ; x10
        ADD     R1, R1, R3      ; sumar digito
        GETC
        OUT
        BR      LEER_CARACTER

LEER_TERMINAR:
        ADD     R2, R2, #0
        BRz     LEER_POSITIVO
        NOT     R1, R1
        ADD     R1, R1, #1

LEER_POSITIVO:
        ADD     R0, R1, #0
        LD      R7, RETORNO_LEER
        RET

LEER_INVALIDO:
        GETC
        ADD     R3, R0, #-10
        BRz     MOSTRAR_ERROR
        ADD     R3, R0, #-13
        BRnp    LEER_INVALIDO

MOSTRAR_ERROR:
        LEA     R0, MENSAJE_ERROR
        PUTS
        BR      LEER_REINICIAR

; -----------------------------------------------------------------
; MULTIPLICAR
; Entrada: R0 = multiplicando, R2 = multiplicador.
; Salida: R1:R0 = producto de 32 bits (alta:baja).
; -----------------------------------------------------------------
MULTIPLICAR:
        ST      R7, RETORNO_MULT
        AND     R6, R6, #0      ; signo: 0 positivo, 1 negativo

        ADD     R3, R0, #0      ; magnitud del multiplicando
        ADD     R5, R3, #0
        BRzp    MULT_A_POSITIVO
        NOT     R3, R3
        ADD     R3, R3, #1
        ADD     R6, R6, #1

MULT_A_POSITIVO:
        ADD     R5, R2, #0
        BRzp    MULT_B_POSITIVO
        NOT     R2, R2
        ADD     R2, R2, #1
        ADD     R6, R6, #0
        BRz     MULT_SOLO_B_NEGATIVO
        AND     R6, R6, #0
        BR      MULT_B_POSITIVO

MULT_SOLO_B_NEGATIVO:
        ADD     R6, R6, #1

MULT_B_POSITIVO:
        LEA     R7, SIGNO
        STR     R6, R7, #0
        AND     R0, R0, #0      ; palabra baja del resultado
        AND     R1, R1, #0      ; palabra alta del resultado
        AND     R4, R4, #0      ; palabra alta del multiplicando
        AND     R7, R7, #0
        ADD     R7, R7, #1      ; mascara
        AND     R5, R5, #0
        ADD     R5, R5, #15
        ADD     R5, R5, #1      ; 16 iteraciones

MULT_BUCLE:
        AND     R6, R2, R7
        BRz     MULT_DESPLAZAR
        ADD     R6, R0, #0      ; baja anterior
        ADD     R0, R0, R3

        ADD     R6, R6, #0
        BRn     MULT_BAJA_ANT_NEG
        ADD     R3, R3, #0
        BRn     MULT_BAJA_POS_SUM_NEG
        ADD     R0, R0, #0
        BRn     MULT_ACARREO
        BR      MULT_DESPLAZAR

MULT_BAJA_POS_SUM_NEG:
        ADD     R0, R0, #0
        BRzp    MULT_ACARREO
        BR      MULT_DESPLAZAR

MULT_BAJA_ANT_NEG:
        ADD     R3, R3, #0
        BRn     MULT_ACARREO
        ADD     R0, R0, #0
        BRzp    MULT_ACARREO
        BR      MULT_DESPLAZAR

MULT_ACARREO:
        ADD     R1, R1, #1

MULT_DESPLAZAR:
        ADD     R6, R3, #0      ; conservar bit alto de la baja
        ADD     R3, R3, R3
        ADD     R4, R4, R4
        ADD     R6, R6, #0
        BRzp    MULT_SIN_ACARREO
        ADD     R4, R4, #1

MULT_SIN_ACARREO:
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

; -----------------------------------------------------------------
; IMPRIMIR_HEX
; Entrada: R0 = palabra de 16 bits.
; Imprime cuatro digitos hexadecimales.
; -----------------------------------------------------------------
IMPRIMIR_HEX:
        ST      R7, RETORNO_HEX
        ADD     R5, R0, #0      ; conservar la palabra mientras se imprime
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
        BRzp    HEX_BIT_CERO
        ADD     R2, R2, #1
HEX_BIT_CERO:
        ADD     R3, R3, R3
        ADD     R4, R4, #-1
        BRp     HEX_BIT

        AND     R4, R4, #0
        ADD     R4, R4, #4
HEX_DESPLAZAR:
        ADD     R5, R5, R5
        ADD     R4, R4, #-1
        BRp     HEX_DESPLAZAR

        LEA     R3, DIGITOS_HEX
        ADD     R3, R3, R2
        LDR     R0, R3, #0
        OUT
        ADD     R1, R1, #-1
        BRp     HEX_DIGITO

        LD      R7, RETORNO_HEX
        RET

.END
