#!/bin/bash
set -euo pipefail

C=$(tput setaf 6 2>/dev/null || true)
B=$(tput bold 2>/dev/null || true)
R=$(tput sgr0 2>/dev/null || true)

ME=${0##*/}

usage() {
	cat <<EOF
Uso: $ME [nombre] [-cpp] [-t] [-clasico]
  nombre    nombre del proyecto (sin argumentos: menú interactivo)
  -cpp      estructura para C++ en vez de C
  -t        crea tests/ con un test de ejemplo
  -clasico  main de C++ con printf en vez de std::cout (solo con -cpp)
EOF
}

preguntar_nombre() {
	local resp default="${1:-demo}"
	printf '%s? %sNombre del proyecto (%s) %s› %s' "$C" "$R" "$default" "$C" "$R" >&2
	read -r resp
	[ -z "$resp" ] && resp="$default"
	echo "$resp"
}

seleccionar() {
	local titulo="$1" default="$2"
	shift 2
	local opciones=("$@") total=$# sel=0 i k
	for i in "${!opciones[@]}"; do
		[ "${opciones[$i]}" = "$default" ] && sel=$i
	done
	if [ ! -t 0 ]; then
		echo "${opciones[$sel]}"
		return
	fi
	while true; do
		printf "\r\x1b[K${C}? ${R}%s ${C}› ${R}/" "$titulo" >&2
		for i in "${!opciones[@]}"; do
			if [ "$i" -eq "$sel" ]; then
				printf " ${C}${B}%s${R}${R}" "${opciones[$i]}" >&2
			else
				printf " ${R}%s${R}" "${opciones[$i]}" >&2
			fi
		done
		printf '%s' "/${R}" >&2
		IFS= read -r -s -n1 k
		case "$k" in
			$'\x1b')
				IFS= read -r -s -n1 k
				IFS= read -r -s -n1 k
				case "$k" in
					D) sel=$(((sel + total - 1) % total)) ;;
					C) sel=$(((sel + 1) % total)) ;;
				esac
				;;
			$'\n' | '') break ;;
			[1-9])
				if [ "$k" -le "$total" ]; then
					sel=$((k - 1))
				fi
				;;
		esac
	done
	printf "\r\x1b[K" >&2
	echo "${opciones[$sel]}"
}

NOMBRE=""
MODULO="c"
CON_TESTS="no"
ESTILO="moderno"

while [ $# -gt 0 ]; do
	case "$1" in
		-cpp | --cpp) MODULO="cpp" ;;
		-t | --tests) CON_TESTS="si" ;;
		-clasico | --clasico) ESTILO="clasico" ;;
		-h | --help) usage; exit 0 ;;
		-*)
			echo "Opción desconocida: $1" >&2
			usage >&2
			exit 1
			;;
		*)
			[ -z "$NOMBRE" ] || { echo "Error: solo se admite un nombre de proyecto" >&2; exit 1; }
			NOMBRE="$1"
			;;
	esac
	shift
done

if [ -z "$NOMBRE" ]; then
	[ -t 0 ] || { usage >&2; exit 1; }
	NOMBRE=$(preguntar_nombre "demo")
	if [ "$MODULO" = "c" ]; then
		L=$(seleccionar "Lenguaje" "C" "C" "C++")
		[ "$L" = "C++" ] && MODULO="cpp"
	fi
	if [ "$MODULO" = "cpp" ] && [ "$ESTILO" = "moderno" ]; then
		S=$(seleccionar "Estilo del main" "std::cout" "std::cout" "printf")
		[ "$S" = "printf" ] && ESTILO="clasico"
	fi
	if [ "$CON_TESTS" = "no" ]; then
		T=$(seleccionar "Crear carpeta tests/?" "No" "No" "Sí")
		[ "$T" = "Sí" ] && CON_TESTS="si"
	fi
fi

# Nombre seguro para directorios, #include y Makefile
[[ "$NOMBRE" =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*$ ]] || {
	echo "Error: nombre inválido '$NOMBRE' (usa letras, números, '.', '_' o '-')" >&2
	exit 1
}

[ -e "$NOMBRE" ] && { echo "Error: '$NOMBRE' ya existe" >&2; exit 1; }

EXT="c"
EXT_H="h"
CC="gcc"
CFLAGS="-Wall -Wextra -g -Iinclude"
if [ "$MODULO" = "cpp" ]; then
	EXT="cpp"
	EXT_H="hpp"
	CC="g++"
	CFLAGS="-Wall -Wextra -g -std=c++17 -Iinclude"
fi

mkdir -p "$NOMBRE"/{src,include,build}
[ "$CON_TESTS" = "si" ] && mkdir -p "$NOMBRE/tests"

GUARD=$(printf '%s' "$NOMBRE" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9' '_')
case "$GUARD" in
	[0-9]*) GUARD="_$GUARD" ;;
esac

if [ "$MODULO" = "cpp" ] && [ "$ESTILO" = "moderno" ]; then
	cat > "$NOMBRE/src/main.$EXT" <<EOF
#include <iostream>

int main() {
	std::cout << "Hola desde $NOMBRE\n";
	return 0;
}
EOF
else
	cat > "$NOMBRE/src/main.$EXT" <<EOF
#include <stdio.h>

int main(void) {
	printf("Hola desde $NOMBRE\n");
	return 0;
}
EOF
fi

cat > "$NOMBRE/include/$NOMBRE.$EXT_H" <<EOF
#ifndef ${GUARD}_H
#define ${GUARD}_H

#endif
EOF

cat > "$NOMBRE/Makefile" <<'EOF'
CC = @CC@
CFLAGS = @CFLAGS@
BUILD = build
TARGET = $(BUILD)/@NOMBRE@
SRCS = $(wildcard src/*.@EXT@)
TEST = $(wildcard tests/test_*.@EXT@)

default: build

$(TARGET): $(SRCS)
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET)

build: $(TARGET)

run: build
	./$(TARGET)

test: $(TARGET) $(TEST)
	@test -n "$(TEST)" || { echo "No hay tests en tests/"; exit 1; }
	$(CC) $(CFLAGS) $(filter-out $(wildcard src/main.*),$(SRCS)) $(TEST) -o $(BUILD)/test
	./$(BUILD)/test

clean:
	rm -rf $(BUILD)

.PHONY: default build run test clean
EOF
sed -i "s|@CC@|$CC|; s|@CFLAGS@|$CFLAGS|; s|@NOMBRE@|$NOMBRE|; s|@EXT@|$EXT|" "$NOMBRE/Makefile"

if [ "$CON_TESTS" = "si" ]; then
	cat > "$NOMBRE/tests/test_$NOMBRE.$EXT" <<'EOF'
#include <assert.h>
#include <stdio.h>

int suma(int a, int b) {
	return a + b;
}

int main(void) {
	assert(suma(2, 3) == 5);
	assert(suma(-1, 1) == 0);
	printf("Todos los tests pasaron\n");
	return 0;
}
EOF
fi

{
	printf -- '-Iinclude\n'
	printf -- '-Wall\n'
	printf -- '-Wextra\n'
	if [ "$MODULO" = "cpp" ]; then
		printf -- '-std=c++17\n'
	fi
} > "$NOMBRE/compile_flags.txt"

cat > "$NOMBRE/.gitignore" <<'EOF'
build/
*.o
*.out
EOF

cat > "$NOMBRE/README.md" <<EOF
# $NOMBRE

## Compilar y correr

\`\`\`
make run       # compila y ejecuta
make clean     # borra build/
EOF
if [ "$CON_TESTS" = "si" ]; then
	cat >> "$NOMBRE/README.md" <<'EOF'
make test      # compila y ejecuta tests/test_*
EOF
fi
cat >> "$NOMBRE/README.md" <<'EOF'
```
EOF

echo "${C}Proyecto '$NOMBRE' ($MODULO) creado en ./$NOMBRE${R}"