#!/usr/bin/env bash
set -euo pipefail

# llama-serve.sh — entrada de llama-server.service.
#
# Resuelve el modelo activo (symlink ~/.config/llama-current, que maneja
# llama-model.sh) y ejecuta su serve.sh. Si todavía no hay selector, cae al 9B
# para que el arranque automático nunca quede sin server.

LINK="${HOME}/.config/llama-current"
FALLBACK="${HOME}/models/qwen3.5-9b-uncensored/serve.sh"

if [[ -L $LINK ]]; then
  destino=$(readlink -f "$LINK")
  if [[ -x $destino ]]; then
    exec "$destino" "$@"
  fi
  echo "llama-serve: $LINK apunta a un destino inválido: ${destino:-?}" >&2
  exit 1
fi

if [[ -x $FALLBACK ]]; then
  echo "llama-serve: sin selector ($LINK); usando el 9B por defecto." >&2
  exec "$FALLBACK" "$@"
fi

echo "llama-serve: no hay modelo seleccionado ni fallback en $FALLBACK" >&2
exit 1
