; Multiplicacion interactiva LC-3 con formatos Q12.4, Q10.6 y Q8.8.
; Se acepta un numero entero o con hasta dos cifras decimales.
; El producto se guarda en dos palabras: R1:R0.

.ORIG x3000
        BR      INICIO

OPERANDO_A:      .FILL #0
RESULTADO_BAJO:  .FILL #0
RESULTADO_ALTO:  .FILL #0

INICIO:
        JSR     SELECCIONAR_FORMATO
        LEA     R0, MENSAJE_A
        PUTS
        JSR     LEER_NUMERO
        ST      R0, OPERANDO_A

        LEA     R0, MENSAJE_B
        PUTS
        JSR     LEER_NUMERO
        ADD     R2, R0, #0
        LD      R0, OPERANDO_A
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

        LEA     R0, MENSAJE_ESCALA
        PUTS
        HALT

MENSAJE_A:       .STRINGZ "Ingrese el primer valor: "
MENSAJE_B:       .STRINGZ "Ingrese el segundo valor: "
MENSAJE_ALTO:    .STRINGZ "Producto alto: x"
MENSAJE_BAJO:    .STRINGZ "\nProducto bajo: x"
MENSAJE_ESCALA:  .STRINGZ "\nEl producto esta almacenado en R1:R0.\n"

MENSAJE_MENU:    .STRINGZ "\nSeleccione formato Q:\n1. Q12.4\n2. Q10.6\n3. Q8.8\nOpcion: "
MENSAJE_Q12:     .STRINGZ "Formato seleccionado: Q12.4\n"
MENSAJE_Q10:     .STRINGZ "Formato seleccionado: Q10.6\n"
MENSAJE_Q8:      .STRINGZ "Formato seleccionado: Q8.8\n"
BITS_FRAC:       .FILL #0
RETORNO_SEL:     .FILL #0
ASCII_1:         .FILL x0031
ASCII_2:         .FILL x0032
ASCII_3:         .FILL x0033

SELECCIONAR_FORMATO:
        ST      R7, RETORNO_SEL
FORMATO_MENU:
        LEA     R0, MENSAJE_MENU
        PUTS
        GETC
        OUT
        LD      R1, ASCII_1
        NOT     R1, R1 
        ADD     R1, R1, #1
        ADD     R1, R0, R1
        BRz     FORMATO_Q12
        LD      R1, ASCII_2
        NOT     R1, R1
        ADD     R1, R1, #1
        ADD     R1, R0, R1
        BRz     FORMATO_Q10
        LD      R1, ASCII_3
        NOT     R1, R1
        ADD     R1, R1, #1
        ADD     R1, R0, R1
        BRz     FORMATO_Q8
        BR      FORMATO_MENU

FORMATO_Q12:
        LD      R1, CONSTANTE_4
        ST      R1, BITS_FRAC
        LEA     R0, MENSAJE_Q12
        PUTS
        BR      FORMATO_FIN

FORMATO_Q10:
        LD      R1, CONSTANTE_6
        ST      R1, BITS_FRAC
        LEA     R0, MENSAJE_Q10
        PUTS
        BR      FORMATO_FIN

FORMATO_Q8:
        LD      R1, CONSTANTE_8
        ST      R1, BITS_FRAC
        LEA     R0, MENSAJE_Q8
        PUTS

FORMATO_FIN:
        LD      R7, RETORNO_SEL
        RET

MENSAJE_ERROR:   .STRINGZ "\nEntrada invalida. Use hasta dos decimales.\n"
ASCII_CERO:      .FILL x0030
ASCII_MENOS:     .FILL x002D
ASCII_PUNTO:     .FILL x002E
CONSTANTE_4:     .FILL #4
CONSTANTE_6:     .FILL #6
CONSTANTE_8:     .FILL #8
NEGATIVO_100:    .FILL #-100
NEGATIVO_50:     .FILL #-50
RETORNO_LEER:    .FILL #0

; Lee un numero decimal con hasta dos cifras fraccionarias.
; La escala depende del formato seleccionado.
LEER_NUMERO:
        ST      R7, RETORNO_LEER
LEER_REINICIAR:
        AND     R1, R1, #0      ; parte entera
        AND     R2, R2, #0      ; signo
        AND     R3, R3, #0      ; fraccion escalada
        GETC
        OUT
        LD      R5, ASCII_MENOS
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5
        BRz     LEER_NEGATIVO
        BR      LEER_ENTERO

LEER_NEGATIVO:
        ADD     R2, R2, #1
        GETC
        OUT

LEER_ENTERO:
        ADD     R4, R0, #-10
        BRz     ESCALAR_NUMERO
        ADD     R4, R0, #-13
        BRz     ESCALAR_NUMERO
        LD      R5, ASCII_PUNTO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5
        BRz     LEER_FRACCION
        LD      R5, ASCII_CERO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5
        BRn     LEER_INVALIDO
        ADD     R5, R4, #-10
        BRzp    LEER_INVALIDO
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
        BR      LEER_ENTERO

LEER_FRACCION:
        ; Leer la primera cifra decimal
        GETC
        OUT

        ADD     R4, R0, #-10
        BRz     FRACCION_CERO
        ADD     R4, R0, #-13
        BRz     FRACCION_CERO

        LD      R5, ASCII_CERO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5

        BRn     LEER_INVALIDO
        ADD     R5, R4, #-10
        BRzp    LEER_INVALIDO

        ; Guardar primera cifra decimal
        ADD     R3, R4, #0

        ; Leer posible segunda cifra
        GETC
        OUT

        ADD     R4, R0, #-10
        BRz     UNA_CIFRA_DECIMAL
        ADD     R4, R0, #-13
        BRz     UNA_CIFRA_DECIMAL

        LD      R5, ASCII_CERO
        NOT     R5, R5
        ADD     R5, R5, #1
        ADD     R4, R0, R5

        BRn     LEER_INVALIDO
        ADD     R5, R4, #-10
        BRzp    LEER_INVALIDO

        ; Convertir primera cifra en decimas:
        ; primera_cifra * 10 + segunda_cifra
        ADD     R5, R3, R3
        ADD     R5, R5, R5
        ADD     R5, R5, R5
        ADD     R5, R5, R3
        ADD     R5, R5, R3
        ADD     R3, R5, R4

        ; Verificar fin de línea
        GETC
        OUT

        ADD     R4, R0, #-10
        BRz     ESCALAR_NUMERO
        ADD     R4, R0, #-13
        BRz     ESCALAR_NUMERO
        BR      LEER_INVALIDO

UNA_CIFRA_DECIMAL:
        ; Convertir, por ejemplo, .5 en 50 centésimas
        ADD     R5, R3, R3
        ADD     R5, R5, R5
        ADD     R5, R5, R5
        ADD     R5, R5, R3
        ADD     R5, R5, R3
        ADD     R3, R5, #0
        BR      ESCALAR_NUMERO

FRACCION_CERO:
        AND     R3, R3, #0
        BR      ESCALAR_NUMERO
ESCALAR_NUMERO:
        ; Convertir centesimas a fraccion binaria: redondeo(n * escala / 100).
        LD      R4, BITS_FRAC
FRACCION_ESCALAR_LOOP:
        ADD     R3, R3, R3
        ADD     R4, R4, #-1
        BRp     FRACCION_ESCALAR_LOOP
        LD      R5, NEGATIVO_100
        AND     R4, R4, #0
DIVIDIR_100:
        ADD     R0, R3, R5
        BRn     REDONDEAR_FRACCION
        ADD     R3, R3, R5
        ADD     R4, R4, #1
        BR      DIVIDIR_100

REDONDEAR_FRACCION:
        LD      R5, NEGATIVO_50
        ADD     R0, R3, R5
        BRn     FRACCION_LISTA
        ADD     R4, R4, #1
FRACCION_LISTA:
        ADD     R3, R4, #0
        LD      R4, BITS_FRAC
ESCALAR_LOOP:
        ADD     R1, R1, R1
        ADD     R4, R4, #-1
        BRp     ESCALAR_LOOP
        ADD     R1, R1, R3
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
        ADD     R4, R0, #-10
        BRz     MOSTRAR_ERROR
        ADD     R4, R0, #-13
        BRnp    LEER_INVALIDO
MOSTRAR_ERROR:
        LEA     R0, MENSAJE_ERROR
        PUTS
        BR      LEER_REINICIAR

; Multiplicacion de dos magnitudes de 16 bits.
; R0 y R2 son operandos escalados; R1:R0 es el producto.
SIGNO_MULT:      .FILL #0
RETORNO_MULT:    .FILL #0

MULTIPLICAR:
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
        ; R3 = magnitud del primer operando
        ; R2 = magnitud del segundo operando
        ; R6 = signo del resultado

        ; Guardar el signo antes de reutilizar R6
        LEA     R7, SIGNO_MULT
        STR     R6, R7, #0

        ; ---------------------------------------------------------
        ; Salida inmediata si alguno de los operandos es cero
        ; ---------------------------------------------------------
        ADD     R5, R3, #0
        BRz     MULT_RESULTADO_CERO

        ADD     R5, R2, #0
        BRz     MULT_RESULTADO_CERO

        ; ---------------------------------------------------------
        ; Elegir el operando de menor magnitud como multiplicador.
        ;
        ; R3 = multiplicando
        ; R2 = multiplicador
        ;
        ; Si R3 < R2, se intercambian.
        ; Así R2 siempre contiene la magnitud menor.
        ; ---------------------------------------------------------
        NOT     R5, R2
        ADD     R5, R5, #1
        ADD     R5, R3, R5    ,  ; R5 = R3 - R2
        BRn     MULT_INTERCAMBIAR

        BR      MULT_INICIALIZAR

MULT_INTERCAMBIAR:
        ADD     R5, R3, #0      ; temporal = R3
        ADD     R3, R2, #0      ; R3 = antiguo R2
        ADD     R2, R5, #0      ; R2 = antiguo R3

MULT_INICIALIZAR:
        AND     R0, R0, #0      ; palabra baja del resultado
        AND     R1, R1, #0      ; palabra alta del resultado
        AND     R4, R4, #0      ; palabra alta del multiplicando

        AND     R7, R7, #0
        ADD     R7, R7, #1      ; máscara = 1

        AND     R5, R5, #0
        ADD     R5, R5, #15
        ADD     R5, R5, #1      ; máximo 16 iteraciones

MULT_LOOP:
        AND     R6, R2, R7      ; comprobar bit actual del multiplicador
        BRz     MULT_SHIFT

        ADD     R6, R0, #0      ; guardar palabra baja anterior
        ADD     R0, R0, R3      ; sumar palabra baja

        ; Detectar acarreo de la suma de la palabra baja
        ADD     R6, R6, #0
        BRn     MULT_OLD_NEG

        ADD     R3, R3, #0
        BRn     MULT_POS_NEG

        ADD     R0, R0, #0
        BRn     MULT_CARRY
        BR      MULT_SHIFT

MULT_POS_NEG:
        ADD     R0, R0, #0
        BRzp    MULT_CARRY
        BR      MULT_SHIFT

MULT_OLD_NEG:
        ADD     R3, R3, #0
        BRn     MULT_CARRY

        ADD     R0, R0, #0
        BRzp    MULT_CARRY
        BR      MULT_SHIFT

MULT_CARRY:
        ADD     R1, R1, #1

MULT_SHIFT:
        ; Desplazar el multiplicando de 32 bits R4:R3
        ADD     R6, R3, #0      ; conservar bit 15 de R3
        ADD     R3, R3, R3      ; desplazar palabra baja
        ADD     R4, R4, R4      ; desplazar palabra alta

        ADD     R6, R6, #0
        BRzp    MULT_NO_CARRY
        ADD     R4, R4, #1      ; propagar acarreo

MULT_NO_CARRY:
        ADD     R7, R7, R7      ; desplazar máscara
        ADD     R5, R5, #-1
        BRp     MULT_LOOP

        BR      MULT_APLICAR_SIGNO

MULT_RESULTADO_CERO:
        AND     R0, R0, #0
        AND     R1, R1, #0
        BR      MULT_FIN

MULT_APLICAR_SIGNO:
        LEA     R6, SIGNO_MULT
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
        BRzp    HEX_ZERO
        ADD     R2, R2, #1
HEX_ZERO:
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
