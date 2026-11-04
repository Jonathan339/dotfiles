#!/usr/bin/env bash
# lib/llama.sh — helpers compartidos por scripts/llama-*.sh
#
# No se ejecuta solo: se sourcea. Los serve.sh de ~/models declaran sus flags
# como `var="${var:-default}"`; acá se leen esos defaults para no duplicar
# alias, puerto y contexto en la config de OpenCode ni en el journal.

# serve_var <serve.sh> <var> → imprime el default de `var="${var:-...}"`.
# Devuelve 1 si el script no declara la variable con ese patrón.
serve_var() {
  local file=$1 name=$2 line re
  line=$(grep -m1 -E "^${name}=\"\\\$\\{${name}:-" "$file" 2>/dev/null) || return 1
  re="^${name}=\"\\\$\\{${name}:-([^}]*)\\}\""
  [[ $line =~ $re ]] || return 1
  printf '%s\n' "${BASH_REMATCH[1]}"
}

# serve_model_dir <alias> → ruta del serve.sh cuyo alias coincide.
# Devuelve 1 si ningún modelo de ~/models usa ese alias.
serve_model_dir() {
  local alias=$1 dir candidato
  for dir in "${MODELS_DIR:?MODELS_DIR no definido}"/*/; do
    [[ -f "${dir}serve.sh" ]] || continue
    candidato=$(serve_var "${dir}serve.sh" alias) || continue
    if [[ $candidato == "$alias" ]]; then
      printf '%s\n' "${dir}serve.sh"
      return 0
    fi
  done
  return 1
}

# api_models <base-url> → JSON de /v1/models. Falla si el server no responde
# (503 mientras carga el modelo, conexión rechazada, etc.).
api_models() {
  curl -fsS --max-time 5 "${1}/models" 2>/dev/null
}
