/* Multiplicacion interactiva con formatos Q12.4, Q10.6 y Q8.8. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct formato_q {
	const char *nombre;
	unsigned bits_fraccion;
};

static const struct formato_q formatos[] = {
	{"Q12.4", 4u},
	{"Q10.6", 6u},
	{"Q8.8", 8u}
};

static int leer_linea(char *linea, size_t capacidad)
{
	if (fgets(linea, capacidad, stdin) == NULL) {
		return 0;
	}

	linea[strcspn(linea, "\n")] = '\0';
	return 1;
}

static int leer_formato(void)
{
	char linea[32];
	char *fin;
	unsigned opcion;

	for (;;) {
		printf("Seleccione formato Q:\n");
		printf("1. Q12.4\n2. Q10.6\n3. Q8.8\nOpcion: ");
		if (!leer_linea(linea, sizeof linea)) {
			return -1;
		}

		opcion = (unsigned)strtoul(linea, &fin, 10);
		while (*fin == ' ' || *fin == '\t') {
			++fin;
		}
		if (fin != linea && *fin == '\0' && opcion >= 1u && opcion <= 3u) {
			return (int)opcion - 1;
		}

		fprintf(stderr, "Opcion invalida.\n");
	}
}

static int convertir_q(const char *texto, unsigned bits_fraccion, int16_t *salida)
{
	const char *cursor = texto;
	uint32_t parte_entera = 0;
	uint32_t parte_fraccion = 0;
	unsigned digitos_fraccion = 0;
	unsigned escala = 1u << bits_fraccion;
	int negativo = 0;
	int64_t valor_escalado;
	char *fin;

	if (*cursor == '-' || *cursor == '+') {
		negativo = *cursor == '-';
		++cursor;
	}
	if (*cursor < '0' || *cursor > '9') {
		return 0;
	}

	while (*cursor >= '0' && *cursor <= '9') {
		if (parte_entera > UINT32_MAX / 10u) {
			return 0;
		}
		parte_entera = parte_entera * 10u + (unsigned)(*cursor - '0');
		++cursor;
	}

	if (*cursor == '.') {
		++cursor;
		while (*cursor >= '0' && *cursor <= '9' && digitos_fraccion < 2u) {
			parte_fraccion = parte_fraccion * 10u + (unsigned)(*cursor - '0');
			++digitos_fraccion;
			++cursor;
		}
		if (digitos_fraccion == 0u || (*cursor >= '0' && *cursor <= '9')) {
			return 0;
		}
	}

	fin = (char *)cursor;
	while (*fin == ' ' || *fin == '\t') {
		++fin;
	}
	if (*fin != '\0') {
		return 0;
	}

	if (digitos_fraccion == 0u) {
		parte_fraccion = 0u;
	} else if (digitos_fraccion == 1u) {
		parte_fraccion *= 10u;
	}

	valor_escalado = (int64_t)parte_entera * escala;
	valor_escalado += ((int64_t)parte_fraccion * escala + 50) / 100;
	if (negativo) {
		valor_escalado = -valor_escalado;
	}
	if (valor_escalado < INT16_MIN || valor_escalado > INT16_MAX) {
		return 0;
	}

	*salida = (int16_t)valor_escalado;
	return 1;
}

static int leer_operando(const char *mensaje, unsigned bits_fraccion, int16_t *salida)
{
	char linea[128];

	for (;;) {
		printf("%s", mensaje);
		if (!leer_linea(linea, sizeof linea)) {
			return 0;
		}
		if (convertir_q(linea, bits_fraccion, salida)) {
			return 1;
		}
		fprintf(stderr, "Entrada invalida. Use hasta dos decimales y respete el rango del formato.\n");
	}
}

static int32_t multiplicar_q(int16_t multiplicando, int16_t multiplicador)
{
	uint32_t multiplicando_abs;
	uint32_t multiplicador_abs;
	uint32_t resultado = 0u;
	int negativo;

	negativo = (multiplicando < 0) != (multiplicador < 0);

	/*
	 * Se usa unsigned para obtener correctamente la magnitud de INT16_MIN.
	 * Su valor absoluto no puede representarse como int16_t.
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

static void imprimir_bits(uint16_t palabra)
{
	int bit;

	for (bit = 15; bit >= 0; --bit) {
		putchar((palabra & (UINT16_C(1) << bit)) != 0u ? '1' : '0');
		if (bit == 8) {
			putchar(' ');
		}
	}
	putchar('\n');
}

int main(void)
{
	int formato;
	int16_t operando_a;
	int16_t operando_b;
	int32_t producto;
	uint32_t producto_bits;
	uint32_t escala_producto;
	uint16_t palabra_alta;
	uint16_t palabra_baja;
	double producto_decimal;

	formato = leer_formato();
	if (formato < 0) {
		return 1;
	}
	printf("Formato seleccionado: %s\n", formatos[formato].nombre);

	if (!leer_operando("Ingrese el primer valor: ", formatos[formato].bits_fraccion, &operando_a) ||
		!leer_operando("Ingrese el segundo valor: ", formatos[formato].bits_fraccion, &operando_b)) {
		return 1;
	}

	producto = multiplicar_q(operando_a, operando_b);
	producto_bits = (uint32_t)producto;
	palabra_alta = (uint16_t)(producto_bits >> 16);
	palabra_baja = (uint16_t)producto_bits;
	escala_producto = UINT32_C(1) << (2u * formatos[formato].bits_fraccion);
	producto_decimal = (double)producto / (double)escala_producto;

	printf("Producto alto: x%04" PRIX16 "\n", palabra_alta);
	printf("Producto bajo: x%04" PRIX16 "\n", palabra_baja);
	printf("Bits palabra alta: ");
	imprimir_bits(palabra_alta);
	printf("Bits palabra baja: ");
	imprimir_bits(palabra_baja);
	printf("Producto decimal aproximado: %.10f\n", producto_decimal);
	printf("Escala del producto: 2^%u = %u (Q%u.%u)\n",
	       2u * formatos[formato].bits_fraccion,
	       escala_producto,
	       32u - 2u * formatos[formato].bits_fraccion,
	       2u * formatos[formato].bits_fraccion);

	return 0;
}
