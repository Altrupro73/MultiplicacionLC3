/*
 * Logica de multiplicacion para los formatos Q usados por
 * Multiplicacion_3_Formatos.asm.
 *
 * El operando Q se almacena en 16 bits con signo:
 *
 *     almacenado = valor_real * 2^bits_fraccion
 *
 * Formato      Escala       Resolucion
 * Q12.4        16            0.0625
 * Q10.6        64            0.015625
 * Q8.8         256           0.00390625
 *
 * La multiplicacion de dos operandos Q genera un producto de 32 bits.
 * Si el formato de entrada usa F bits fraccionarios, el producto usa
 * 2F bits fraccionarios y se almacena como palabra_alta:palabra_baja.
 */

#include <stdbool.h>
#include <stdint.h>

enum formato_q {
	FORMATO_Q12_4,
	FORMATO_Q10_6,
	FORMATO_Q8_8
};

struct q_configuracion {
	unsigned bits_fraccion;
};

static const struct q_configuracion CONFIGURACIONES_Q[] = {
	[FORMATO_Q12_4] = {4u},
	[FORMATO_Q10_6] = {6u},
	[FORMATO_Q8_8] = {8u}
};

static bool formato_valido(enum formato_q formato)
{
	return formato >= FORMATO_Q12_4 && formato <= FORMATO_Q8_8;
}

/* Devuelve la cantidad de bits fraccionarios del formato seleccionado. */
unsigned q_bits_fraccion(enum formato_q formato)
{
	if (!formato_valido(formato)) {
		return 0u;
	}

	return CONFIGURACIONES_Q[formato].bits_fraccion;
}

/*
 * Convierte un numero decimal a su representacion Q.
 *
 * parte_entera y centesimas representan, por ejemplo, 12.34 como:
 *
 *     parte_entera = 12
 *     centesimas   = 34
 *
 * La fraccion se redondea al paso representable por el formato. No se
 * usan valores float, por lo que la conversion es determinista.
 */
bool q_codificar_decimal(enum formato_q formato,
                         bool negativo,
                         uint32_t parte_entera,
                         uint32_t centesimas,
                         int16_t *salida)
{
	uint32_t escala;
	int64_t valor;

	if (!formato_valido(formato) || salida == 0 || centesimas > 99u) {
		return false;
	}

	escala = UINT32_C(1) << CONFIGURACIONES_Q[formato].bits_fraccion;
	valor = (int64_t)parte_entera * escala;
	valor += ((int64_t)centesimas * escala + 50) / 100;
	if (negativo) {
		valor = -valor;
	}

	if (valor < INT16_MIN || valor > INT16_MAX) {
		return false;
	}

	*salida = (int16_t)valor;
	return true;
}

/*
 * Multiplica dos operandos Q almacenados como enteros de 16 bits.
 * La conversion a int32_t evita perder bits durante la operacion.
 */
int32_t q_multiplicar(int16_t multiplicando, int16_t multiplicador)
{
    uint32_t multiplicando_abs;
    uint32_t multiplicador_abs;
    uint32_t resultado = 0u;
    bool negativo;

    negativo = (multiplicando < 0) != (multiplicador < 0);

    /*
     * La conversión a uint32_t antes de negar evita problemas con
     * INT16_MIN, cuyo valor absoluto no cabe en int16_t.
     */
    multiplicando_abs = (uint32_t)(int32_t)multiplicando;
    if (multiplicando < 0) {
        multiplicando_abs = 0u - multiplicando_abs;
    }

    multiplicador_abs = (uint32_t)(int32_t)multiplicador;
    if (multiplicador < 0) {
        multiplicador_abs = 0u - multiplicador_abs;
    }

    while (multiplicador_abs != 0u) {
        if ((multiplicador_abs & 1u) != 0u) {
            resultado += multiplicando_abs;
        }

        multiplicando_abs <<= 1;
        multiplicador_abs >>= 1;
    }

    if (negativo) {
        return -(int32_t)resultado;
    }

    return (int32_t)resultado;
}

/*
 * Separa el producto signed de 32 bits en dos palabras de 16 bits.
 * La conversion a uint32_t conserva la representacion en complemento a dos,
 * por lo que tambien funciona para productos negativos.
 *
 * El llamador puede imprimir las palabras con:
 *     printf("x%04X", palabra_alta);
 *     printf("x%04X", palabra_baja);
 */
void q_separar_palabras(int32_t producto,
                        uint16_t *palabra_alta,
                        uint16_t *palabra_baja)
{
	uint32_t bits;

	if (palabra_alta == 0 || palabra_baja == 0) {
		return;
	}

	bits = (uint32_t)producto;
	*palabra_alta = (uint16_t)(bits >> 16);
	*palabra_baja = (uint16_t)bits;
}
