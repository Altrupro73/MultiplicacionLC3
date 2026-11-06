/* Multiplicacion shift + sumas con formatos Q12.4, Q10.6 y Q8.8.
* Muestra formato, rangos de entrada/salida, precision e iteraciones. */
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <io.h>
#include <windows.h>
#else
#include <unistd.h>
#endif

/* Colores ANSI: quedan vacios si la salida no es una consola. */
static const char *c_rst = "", *c_tit = "", *c_ok = "", *c_dim = "";
static const char *c_lab = "", *c_hex = "", *c_err = "", *c_pro = "";

static void iniciar_color(void)
{
#ifndef FORZAR_COLOR
#ifdef _WIN32
	HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE);
	DWORD modo = 0;
	
	if (h == INVALID_HANDLE_VALUE || !GetConsoleMode(h, &modo) ||
		!SetConsoleMode(h, modo | 0x0004u)) {
		return;
	}
#else
		if (!isatty(STDOUT_FILENO)) {
			return;
		}
#endif
#endif
		c_rst = "\033[0m";
		c_tit = "\033[1;36m";
		c_ok  = "\033[1;32m";
		c_dim = "\033[2m";
		c_lab = "\033[33m";
		c_hex = "\033[35m";
		c_err = "\033[31m";
		c_pro = "\033[1;33m";
}

struct formato_q {
	const char *nombre;
	unsigned bits_entera;   /* incluye el bit de signo */
	unsigned bits_fraccion;
};

static const struct formato_q formatos[] = {
	{"Q12.4", 12u, 4u},
{"Q10.6", 10u, 6u},
	{"Q8.8", 8u, 8u}
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
		printf("  %sOpcion:%s ", c_pro, c_rst);
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
		
		fprintf(stderr, "  %sOpcion invalida.%s\n", c_err, c_rst);
	}
}

/* Convierte texto decimal a Q. Ademas devuelve el valor decimal ingresado
* (antes de cuantizar) para poder calcular el error de cuantizacion. */
static int convertir_q(const char *texto, unsigned bits_fraccion,
					   int16_t *salida, double *valor_ingresado)
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
	*valor_ingresado = (double)parte_entera + (double)parte_fraccion / 100.0;
	if (negativo) {
		*valor_ingresado = -*valor_ingresado;
	}
	return 1;
}

static int leer_operando(const char *mensaje, unsigned bits_fraccion,
						 int16_t *salida, double *valor_ingresado)
{
	char linea[128];
	
	for (;;) {
		printf("%s%s%s", c_pro, mensaje, c_rst);
		if (!leer_linea(linea, sizeof linea)) {
			return 0;
		}
		if (convertir_q(linea, bits_fraccion, salida, valor_ingresado)) {
			return 1;
		}
		fprintf(stderr, "  %sEntrada invalida: hasta 2 decimales y dentro del rango del formato.%s\n", c_err, c_rst);
	}
}

/* Multiplicacion por desplazamiento y suma. Cuenta iteraciones y sumas. */
static int32_t multiplicar_q(int16_t multiplicando, int16_t multiplicador,
							 unsigned *iteraciones, unsigned *sumas)
{
	uint32_t multiplicando_abs;
	uint32_t multiplicador_abs;
	uint32_t resultado = 0u;
	int negativo;
	
	*iteraciones = 0u;
	*sumas = 0u;
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
			++*sumas;
		}
		multiplicando_abs <<= 1;
		multiplicador_abs >>= 1;
		++*iteraciones;
	}
	
	if (negativo) {
		return -(int32_t)resultado;
	}
	
	return (int32_t)resultado;
}

#define ANCHO 70

/* Imprime un double con hasta max_dec decimales, sin ceros sobrantes. */
static void dec(char *buf, size_t n, double v, int max_dec)
{
	size_t len;
	
	snprintf(buf, n, "%.*f", max_dec, v);
	if (strchr(buf, '.') != NULL) {
		len = strlen(buf);
		while (len > 0 && buf[len - 1] == '0') {
			buf[--len] = '\0';
		}
		if (len > 0 && buf[len - 1] == '.') {
			buf[--len] = '\0';
		}
	}
	if (strcmp(buf, "-0") == 0) {
		strcpy(buf, "0");
	}
}

static void barra(char c)
{
	int i;
	
	printf("  %s", c_dim);
	for (i = 0; i < ANCHO; ++i) {
		putchar(c);
	}
	printf("%s\n", c_rst);
}

static void seccion(const char *titulo)
{
	printf("\n  %s%s%s\n", c_tit, titulo, c_rst);
	barra('-');
}

/* Fila de tabla: el relleno va dentro del color para no desalinear. */
static void fila(const char *etiqueta, const char *a, const char *b, const char *color)
{
	printf("  %s%-12s%s %s%-26s %-26s%s\n", c_lab, etiqueta, c_rst, color, a, b, c_rst);
}

/* Bits agrupados de a 4: 1111 1111 1111 1000 */
static void imprimir_bits(uint16_t palabra)
{
	int bit;
	
	printf("%s", c_dim);
	for (bit = 15; bit >= 0; --bit) {
		putchar((palabra & (UINT16_C(1) << bit)) != 0u ? '1' : '0');
		if (bit % 4 == 0 && bit != 0) {
			putchar(' ');
		}
	}
	printf("%s", c_rst);
}

int main(void)
{
	int formato;
	int16_t operando_a;
	int16_t operando_b;
	double ingresado_a;
	double ingresado_b;
	int32_t producto;
	uint32_t producto_bits;
	uint32_t escala_producto;
	uint16_t palabra_alta;
	uint16_t palabra_baja;
	double producto_decimal;
	unsigned iteraciones;
	unsigned sumas;
	
	const struct formato_q *f;
	int fr;
	int fp;
	double escala_op;
	double escala_prod;
	double producto_ideal;
	char c1[160];
	char c2[160];
	char c3[64];
	char c4[64];
	
	iniciar_color();
	
	printf("\n");
	barra('=');
	printf("  %sMULTIPLICACION EN PUNTO FIJO%s  (shift + sumas)\n", c_tit, c_rst);
	barra('=');
	printf("\n  %s1)%s Q12.4    %s2)%s Q10.6    %s3)%s Q8.8\n\n",
		   c_lab, c_rst, c_lab, c_rst, c_lab, c_rst);
	
	formato = leer_formato();
	if (formato < 0) {
		return 1;
	}
	f = &formatos[formato];
	fr = (int)f->bits_fraccion;
	fp = 2 * fr;
	printf("\n");
	
	if (!leer_operando("  Primer valor : ", f->bits_fraccion, &operando_a, &ingresado_a) ||
		!leer_operando("  Segundo valor: ", f->bits_fraccion, &operando_b, &ingresado_b)) {
		return 1;
	}
		
		producto = multiplicar_q(operando_a, operando_b, &iteraciones, &sumas);
		producto_bits = (uint32_t)producto;
		palabra_alta = (uint16_t)(producto_bits >> 16);
		palabra_baja = (uint16_t)producto_bits;
		escala_producto = UINT32_C(1) << (2u * f->bits_fraccion);
		producto_decimal = (double)producto / (double)escala_producto;
		
		escala_op = (double)(1u << fr);
		escala_prod = (double)escala_producto;
		producto_ideal = ingresado_a * ingresado_b;
		
		/* ---------------- RESULTADO ---------------- */
		printf("\n");
		barra('=');
		dec(c1, sizeof c1, producto_decimal, fp);
		printf("  %sRESULTADO%s   A x B = %s%s%s\n", c_tit, c_rst, c_ok, c1, c_rst);
		barra('=');
		
		seccion("OPERANDOS");
		printf("  %s%-12s %-14s %-16s %s%s\n", c_dim, "", "Ingresado", "Valor en Q", "Hex", c_rst);
		dec(c1, sizeof c1, ingresado_a, 2);
		dec(c2, sizeof c2, (double)operando_a / escala_op, fr);
		printf("  %s%-12s%s %-14s %-16s %sx%04" PRIX16 "%s\n",
			   c_lab, "A", c_rst, c1, c2, c_hex, (uint16_t)operando_a, c_rst);
		dec(c1, sizeof c1, ingresado_b, 2);
		dec(c2, sizeof c2, (double)operando_b / escala_op, fr);
		printf("  %s%-12s%s %-14s %-16s %sx%04" PRIX16 "%s\n",
			   c_lab, "B", c_rst, c1, c2, c_hex, (uint16_t)operando_b, c_rst);
		
		seccion("PRODUCTO (32 bits)");
		printf("  %s%-12s%s %sx%04" PRIX16 "%s   ", c_lab, "Alta", c_rst, c_hex, palabra_alta, c_rst);
		imprimir_bits(palabra_alta);
		printf("\n");
		printf("  %s%-12s%s %sx%04" PRIX16 "%s   ", c_lab, "Baja", c_rst, c_hex, palabra_baja, c_rst);
		imprimir_bits(palabra_baja);
		printf("\n");
		
		seccion("FORMATO Y PRECISION");
		fila("", "ENTRADA", "SALIDA", c_dim);
		snprintf(c1, sizeof c1, "%s  (%u+%u bits)", f->nombre, f->bits_entera, f->bits_fraccion);
		snprintf(c2, sizeof c2, "Q%u.%u  (%u+%d bits)", 32u - 2u * f->bits_fraccion,
				 2u * f->bits_fraccion, 32u - 2u * f->bits_fraccion, fp);
		fila("Formato", c1, c2, "");
		dec(c3, sizeof c3, -32768.0 / escala_op, fr);
		dec(c4, sizeof c4, 32767.0 / escala_op, fr);
		snprintf(c1, sizeof c1, "[%s, %s]", c3, c4);
		dec(c3, sizeof c3, -(1073741824.0 - 32768.0) / escala_prod, fp);
		dec(c4, sizeof c4, 1073741824.0 / escala_prod, fp);
		snprintf(c2, sizeof c2, "[%s, %s]", c3, c4);
		fila("Rango", c1, c2, "");
		dec(c1, sizeof c1, 1.0 / escala_op, fr);
		dec(c2, sizeof c2, 1.0 / escala_prod, fp);
		fila("Resolucion", c1, c2, "");
		dec(c3, sizeof c3, 0.5 / escala_op, fr + 1);
		snprintf(c1, sizeof c1, "+/- %.40s", c3);
		fila("Error max.", c1, "0 (exacto)", "");
		
		seccion("ALGORITMO Y ERROR");
		dec(c1, sizeof c1, producto_ideal, 4);
		dec(c2, sizeof c2, producto_decimal - producto_ideal, 12);
		printf("  %s%-12s%s %u de 16  (%u sumas)\n", c_lab, "Iteraciones", c_rst, iteraciones, sumas);
		printf("  %s%-12s%s %s%s%s  (exacto: %s)\n", c_lab, "Error", c_rst, c_err, c2, c_rst, c1);
		
		printf("\n");
		return 0;
}
