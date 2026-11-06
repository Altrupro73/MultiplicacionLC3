; Multiplicacion con signo mediante desplazamientos y sumas para LC-3.
; El resultado queda en dos palabras: R1:R0 (alta:baja).

.ORIG x3000

        AND     R0, R0, #0      ; R0 = 0
        ADD     R0, R0, #13     ; R0 = 13
        AND     R2, R2, #0      ; R2 = 0
        ADD     R2, R2, #11     ; R2 = 11
        JSR     MULTIPLICAR
        LEA     R6, RESULTADO_BAJO
        STR     R0, R6, #0
        LEA     R6, RESULTADO_ALTO
        STR     R1, R6, #0
FIN:
        BR      FIN             ; detener sin modificar R0

; -----------------------------------------------------------------
; MULTIPLICAR
; Entrada:
;   R0 = multiplicando
;   R2 = multiplicador
; Salida:
;   R1:R0 = producto de 32 bits (R1 = palabra alta, R0 = baja)
;
; Se trabaja con magnitudes positivas y se aplica el signo al final.
; -----------------------------------------------------------------
MULTIPLICAR:
        ST      R7, RETORNO     ; preservar la direccion de retorno de JSR
        AND     R6, R6, #0      ; R6 = 0: resultado positivo

        ADD     R3, R0, #0      ; R3 = magnitud del multiplicando (baja)
        ADD     R5, R3, #0
        BRzp    R1_POSITIVO
        NOT     R3, R3          ; valor absoluto de R3
        ADD     R3, R3, #1
        ADD     R6, R6, #1      ; cambiar el signo

R1_POSITIVO:
        ADD     R5, R2, #0
        BRzp    R2_POSITIVO
        NOT     R2, R2          ; valor absoluto de R2
        ADD     R2, R2, #1
        ADD     R6, R6, #0
        BRz     SOLO_R2_NEGATIVO
        AND     R6, R6, #0      ; negativo por ambos: resultado positivo
        BR      R2_POSITIVO

SOLO_R2_NEGATIVO:
        ADD     R6, R6, #1      ; negativo por R2 solamente

R2_POSITIVO:
        LEA     R7, SIGNO
        STR     R6, R7, #0      ; guardar signo antes de usar R6 como temporal
        AND     R0, R0, #0      ; R0 = palabra baja del resultado
        AND     R1, R1, #0      ; R1 = palabra alta del resultado
        AND     R4, R4, #0      ; R4 = palabra alta del multiplicando
        AND     R7, R7, #0
        ADD     R7, R7, #1      ; R7 = mascara del bit actual
        AND     R5, R5, #0
        ADD     R5, R5, #15
        ADD     R5, R5, #1      ; R5 = 16 iteraciones

BUCLE:
        AND     R6, R2, R7      ; comprobar el bit actual del multiplicador
        BRz     SIGUIENTE_BIT
        ADD     R6, R0, #0      ; guardar palabra baja anterior
        ADD     R0, R0, R3      ; sumar palabra baja

        ; Detectar acarreo unsigned de la palabra baja.
        ADD     R6, R6, #0
        BRn     BAJA_ANTERIOR_NEGATIVA
        ADD     R3, R3, #0
        BRn     BAJA_POSITIVA_SUMANDO_NEGATIVO
        ADD     R0, R0, #0
        BRn     ACARREO
        BR      SIGUIENTE_BIT

BAJA_POSITIVA_SUMANDO_NEGATIVO:
        ADD     R0, R0, #0
        BRzp    ACARREO
        BR      SIGUIENTE_BIT

BAJA_ANTERIOR_NEGATIVA:
        ADD     R3, R3, #0
        BRn     ACARREO
        ADD     R0, R0, #0
        BRzp    ACARREO
        BR      SIGUIENTE_BIT

ACARREO:
        ADD     R1, R1, #1      ; incrementar palabra alta

SIGUIENTE_BIT:
        ADD     R6, R3, #0      ; conservar bit alto antes del desplazamiento
        ADD     R3, R3, R3      ; desplazar palabra baja
        ADD     R4, R4, R4      ; desplazar palabra alta
        ADD     R6, R6, #0
        BRzp     SIN_ACARREO_DESPLAZAMIENTO
        ADD     R4, R4, #1      ; propagar bit 15 de la palabra baja

SIN_ACARREO_DESPLAZAMIENTO:
        ADD     R7, R7, R7      ; desplazar mascara
        ADD     R5, R5, #-1
        BRp     BUCLE

APLICAR_SIGNO:
        LEA     R6, SIGNO
        LDR     R6, R6, #0
        ADD     R6, R6, #0
        BRz     FIN_MULTIPLICAR
        NOT     R0, R0          ; negar palabra baja
        NOT     R1, R1          ; negar palabra alta
        ADD     R0, R0, #1
        BRnp    FIN_MULTIPLICAR
        ADD     R1, R1, #1      ; propagar acarreo de la palabra baja

FIN_MULTIPLICAR:
        LD      R7, RETORNO     ; restaurar la direccion de retorno
        RET

RESULTADO_BAJO: .FILL #0
RESULTADO_ALTO: .FILL #0
SIGNO:          .FILL #0
RETORNO:        .FILL #0

.END