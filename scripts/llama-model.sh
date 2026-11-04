#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# llama-model.sh — Elige qué modelo levanta llama-server.service
#
# Uso:
#   ./scripts/llama-model.sh list         # modelos disponibles y cuál está activo
#   ./scripts/llama-model.sh coder        # qwen2.5-coder-7b
#   ./scripts/llama-model.sh 4b           # Qwen3.5-4B
#   ./scripts/llama-model.sh 9b           # qwen3.5-9b-uncensored
#   ./scripts/llama-model.sh <alias|dir>  # cualquier modelo de ~/models
#
# Qué hace: repunta ~/.config/llama-current al serve.sh elegido, reinicia el
# unit y espera a que /v1/models responda con el alias esperado. Avisa si
# opencode.json declara otro contexto o si el default apunta a otro modelo.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/llama.sh
source "${SCRIPT_DIR}/lib/llama.sh"

MODELS_DIR="${HOME}/models"
LINK="${HOME}/.config/llama-current"
UNIT="llama-server"
OPENCODE_JSON="${HOME}/.config/opencode/opencode.json"
TIMEOUT="${TIMEOUT:-300}"

ok()   { echo -e "  \e[32m[OK]\e[0m $*"; }
warn() { echo -e "  \e[33m[WARN]\e[0m $*"; }
err()  { echo -e "  \e[31m[ERR]\e[0m $*" >&2; }
info() { echo -e "  \e[36m[..]\e[0m $*"; }

uso() {
  sed -n '4,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

listar() {
  local actual="" dir script alias ctx puerto marca
  [[ -L $LINK ]] && actual=$(readlink -f "$LINK")
  printf '\n  %-24s %-16s %-7s %-7s %s\n' MODELO ALIAS CTX PUERTO ""
  for dir in "$MODELS_DIR"/*/; do
    [[ -f "${dir}serve.sh" ]] || continue
    script="${dir}serve.sh"
    alias=$(serve_var "$script" alias || echo "?")
    ctx=$(serve_var "$script" ctx_size || echo "?")
    puerto=$(serve_var "$script" port || echo "8082")
    marca=""
    [[ -n $actual && $actual == "$(readlink -f "$script")" ]] && marca="← activo"
    printf '  %-24s %-16s %-7s %-7s %s\n' "$(basename "$dir")" "$alias" "$ctx" "$puerto" "$marca"
  done
  echo
}

case "${1:-}" in
  ""|-h|--help|help) uso; exit 0 ;;
  list|--list) listar; exit 0 ;;
esac

pedido=$1
case "$pedido" in
  coder) pedido=qwen2.5-coder-7b ;;
  4b)    pedido=qwen3.5-4b ;;
  9b)    pedido=qwen3.5-9b ;;
esac

target=""
for dir in "$MODELS_DIR"/*/; do
  [[ -f "${dir}serve.sh" ]] || continue
  alias=$(serve_var "${dir}serve.sh" alias || true)
  if [[ $pedido == "$(basename "$dir")" || $pedido == "$alias" ]]; then
    target="${dir}serve.sh"
    break
  fi
done

if [[ -z $target ]]; then
  err "no hay modelo '$pedido' en $MODELS_DIR"
  listar
  exit 1
fi

alias_esperado=$(serve_var "$target" alias || true)
ctx_esperado=$(serve_var "$target" ctx_size || true)
puerto=$(serve_var "$target" port || echo 8082)
nombre=$(basename "$(dirname "$target")")

echo "── Cambiando a $nombre ──"
ok "alias $alias_esperado | ctx $ctx_esperado | puerto $puerto"

ln -sfn "$target" "$LINK"
ok "selector: $LINK → ${target#"$HOME"/}"

systemctl --user daemon-reload
if ! systemctl --user restart "$UNIT"; then
  err "no se pudo reiniciar $UNIT"
  systemctl --user status "$UNIT" --no-pager | tail -6 >&2 || true
  exit 1
fi

info "esperando /v1/models (hasta ${TIMEOUT}s; la carga en frío tarda ~80 s)"
inicio=$SECONDS
limite=$((SECONDS + TIMEOUT))
listo=0
while (( SECONDS < limite )); do
  json=$(api_models "http://127.0.0.1:${puerto}" || true)
  actual=$(printf '%s' "$json" | jq -r '.data[0].id // empty' 2>/dev/null || true)
  if [[ $actual == "$alias_esperado" ]]; then
    listo=1
    break
  fi
  sleep 2
done

if (( ! listo )); then
  err "timeout: el server no expuso '$alias_esperado' en ${TIMEOUT}s"
  journalctl --user -u "$UNIT" -n 15 --no-pager >&2 || true
  exit 1
fi

ok "listo en $((SECONDS - inicio))s: $alias_esperado en :$puerto"

# Avisos de coherencia con OpenCode (no se corrige solo: es config versionada).
if jq -e . "$OPENCODE_JSON" >/dev/null 2>&1; then
  ctx_cfg=$(jq -r --arg id "$alias_esperado" '.providers.llamacpp.models[$id].limit.context // empty' "$OPENCODE_JSON")
  if [[ -n $ctx_cfg && $ctx_cfg != "$ctx_esperado" ]]; then
    warn "opencode.json declara limit.context $ctx_cfg para $alias_esperado; el server usa $ctx_esperado"
  fi
  default=$(jq -r '.model // empty' "$OPENCODE_JSON")
  if [[ $default != "llamacpp/$alias_esperado" ]]; then
    warn "el default de OpenCode es '$default'; el server sirve '$alias_esperado'"
    info "para dejarlo como default: editá ~/.config/opencode/opencode.json y reiniciá el servicio"
  fi
else
  warn "opencode.json inválido o ausente; no se pudo verificar la coherencia"
fi
