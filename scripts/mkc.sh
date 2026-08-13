#!/bin/bash
set -e

C=$(tput setaf 6 2>/dev/null)
B=$(tput bold 2>/dev/null)
R=$(tput sgr0 2>/dev/null)

usage() {
	echo "Uso: $0 [nombre] [-cpp] [-t] [-clasico]"
	echo "  nombre    nombre del proyecto (sin argumentos: menú interactivo)"
	echo "  -cpp      estructura para C++ en vez de C"
	echo "  -t        crea tests/ con un test de ejemplo"
	echo "  -clasico  main de C++ con printf en vez de std::cout (solo con -cpp)"
	exit 1
}

preguntar_nombre() {
	local resp default="${1:-demo}"
	printf "${C}? ${R}Nombre del proyecto (${default}) ${C}› ${R}" >&2
	read -r resp
	[ -z "$resp" ] && resp="$default"
	echo "$resp"
}

seleccionar() {
	local titulo="$1" default="$2"
	shift 2
	local opciones=("$@") total=$# sel=0 i k n
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
		printf "/${R}" >&2
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
		-cpp) MODULO="cpp" ;;
		-t) CON_TESTS="si" ;;
		-clasico) ESTILO="clasico" ;;
		-h | --help) usage ;;
		*) NOMBRE="$1" ;;
	esac
	shift
done

if [ -z "$NOMBRE" ]; then
	[ -t 0 ] || usage
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

[ -e "$NOMBRE" ] && { echo "Error: '$NOMBRE' ya existe" >&2; exit 1; }

EXT="c"
EXT_H="h"
CC="gcc"
FLAGS="-Wall -Wextra -Iinclude"
if [ "$MODULO" = "cpp" ]; then
	EXT="cpp"
	EXT_H="hpp"
	CC="g++"
	FLAGS="-Wall -Wextra -Iinclude -std=c++17"
fi

mkdir -p "$NOMBRE"/{src,include,build}
[ "$CON_TESTS" = "si" ] && mkdir -p "$NOMBRE/tests"

GUARD=$(echo "$NOMBRE" | tr '[:lower:]' '[:upper:]' | tr '-' '_')

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
CFLAGS = @FLAGS@
BUILD = build
TARGET = $(BUILD)/@NOMBRE@
SRCS = $(wildcard src/*.@EXT@)
TEST = $(wildcard tests/test_*.@EXT@)

default: run

$(TARGET): $(SRCS)
	mkdir -p $(BUILD)
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET)

run: $(TARGET)
	./$(TARGET)

test: $(TARGET) $(TEST)
	@test -n "$(TEST)" || { echo "No hay tests en tests/"; exit 1; }
	$(CC) $(CFLAGS) $(filter-out $(wildcard src/main.*),$(SRCS)) $(TEST) -o $(BUILD)/test
	./$(BUILD)/test

clean:
	rm -rf $(BUILD)

.PHONY: default run test clean
EOF
sed -i "s/@CC@/$CC/; s|@FLAGS@|$FLAGS|; s/@NOMBRE@/$NOMBRE/; s/@EXT@/$EXT/" "$NOMBRE/Makefile"

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

printf -- "-Iinclude\n" > "$NOMBRE/compile_flags.txt"

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