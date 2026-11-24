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
# Qué hace: repunta ~/.config/llama-current al serve.sh elegido, para el unit,
# espera a que el proceso muera y la VRAM se libere, descarga modelos de Ollama
# que ocupen la GPU, arranca el modelo pedido y verifica que el alias responda y
# que la VRAM residente del proceso sea real. Avisa si opencode.json declara otro
# contexto o si el default apunta a otro modelo.
#
# Variables:
#   FORCE=1            reinicia aunque el modelo pedido ya esté activo
#   TIMEOUT=300        segundos máximos de espera de /v1/models
#   STOP_OLLAMA=0      no descargar modelos de Ollama antes de arrancar
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/llama.sh
source "${SCRIPT_DIR}/lib/llama.sh"

MODELS_DIR="${HOME}/models"
LINK="${HOME}/.config/llama-current"
UNIT="llama-server"
OPENCODE_JSON="${HOME}/.config/opencode/opencode.json"
TIMEOUT="${TIMEOUT:-300}"
STOP_OLLAMA="${STOP_OLLAMA:-1}"
FORCE="${FORCE:-0}"

ok()   { echo -e "  \e[32m[OK]\e[0m $*"; }
warn() { echo -e "  \e[33m[WARN]\e[0m $*"; }
err()  { echo -e "  \e[31m[ERR]\e[0m $*" >&2; }
info() { echo -e "  \e[36m[..]\e[0m $*"; }

uso() {
  sed -n '4,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
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
    puerto=$(serve_var "$script" port || echo "8083")
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
puerto=$(serve_var "$target" port || echo 8083)
nombre=$(basename "$(dirname "$target")")
BASE="http://127.0.0.1:${puerto}"

echo "── Cambiando a $nombre ──"
ok "alias $alias_esperado | ctx $ctx_esperado | puerto $puerto"

# ¿Ya está cargado ese mismo modelo?
if [[ $FORCE != 1 ]] && systemctl --user is-active --quiet "$UNIT"; then
  cargado=$(api_models "$BASE" | jq -r '.data[0].id // empty' 2>/dev/null || true)
  if [[ -n $cargado && $cargado == "$alias_esperado" ]]; then
    ok "ya está activo ($alias_esperado); no reinicio (FORCE=1 para forzar)"
    exit 0
  fi
fi

# 1. Parar el backend y esperar a que el proceso muera.
pid_viejo=0
if systemctl --user is-active --quiet "$UNIT"; then
  pid_viejo=$(llama_unit_pid "$UNIT")
  info "parando $UNIT (pid ${pid_viejo:-?})"
  systemctl --user stop "$UNIT" || true
  if ! llama_wait_unit_stopped "$UNIT" 30; then
    warn "el proceso no terminó en 30 s; enviando SIGKILL al cgroup"
    systemctl --user kill -s SIGKILL "$UNIT" >/dev/null 2>&1 || true
    llama_wait_unit_stopped "$UNIT" 10 || true
  fi
  ok "proceso detenido"
else
  info "$UNIT no estaba activo"
fi

# 2. Terminar restos lanzados a mano que ocupen el puerto del modelo.
llama_kill_strays "$puerto" "$pid_viejo"
ok "sin restos escuchando en :$puerto"

# 3. Esperar a que la VRAM se libere de verdad.
info "esperando liberación de VRAM"
if ! restante=$(llama_wait_vram_released 262144 20); then
  err "la VRAM de procesos llama sigue ocupada: $((restante / 1024)) MiB"
  err "revisá otros procesos (otro llama.cpp, Ollama, un juego) y reintentá"
  exit 1
fi
if mem_arc=$(llama_arc_mem) && [[ -n $mem_arc ]]; then
  ok "VRAM liberada (Arc: $(echo "$mem_arc" | awk '{print $2}') MiB libres de $(echo "$mem_arc" | awk '{print $1}'))"
else
  ok "VRAM de procesos llama liberada (no pude leer el total de la Arc)"
fi

# 4. Liberar también los modelos de Ollama (comparten la misma GPU).
if [[ $STOP_OLLAMA == 1 ]]; then
  if command -v ollama >/dev/null 2>&1 && [[ -n $(ollama ps 2>/dev/null | awk 'NR > 1 && NF {print $1; exit}') ]]; then
    info "descargando modelos de Ollama para liberar VRAM"
    llama_stop_ollama_models
    ok "Ollama sin modelos cargados"
  fi
fi

# 5. Repuntar el selector y arrancar.
ln -sfn "$target" "$LINK"
ok "selector: $LINK → ${target#"$HOME"/}"

systemctl --user daemon-reload
if ! systemctl --user start "$UNIT"; then
  err "no se pudo arrancar $UNIT"
  systemctl --user status "$UNIT" --no-pager | tail -6 >&2 || true
  exit 1
fi

# 6. Esperar a que el endpoint sirva el alias pedido.
info "esperando /v1/models (hasta ${TIMEOUT}s; la carga en frío tarda ~80 s)"
inicio=$SECONDS
limite=$((SECONDS + TIMEOUT))
listo=0
while (( SECONDS < limite )); do
  json=$(api_models "$BASE" || true)
  actual=$(printf '%s' "$json" | jq -r '.data[0].id // empty' 2>/dev/null || true)
  if [[ $actual == "$alias_esperado" ]]; then
    listo=1
    break
  fi
  if ! systemctl --user is-active --quiet "$UNIT"; then
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

# 7. Confirmar que el modelo quedó en la GPU y no solo en RAM.
pid_nuevo=$(llama_unit_pid "$UNIT")
vram_kib=$(llama_pid_vram_kib "$pid_nuevo")
if (( vram_kib >= 1048576 )); then
  ok "GPU: $((vram_kib / 1024)) MiB residentes en la Arc (pid ${pid_nuevo:-?})"
elif (( vram_kib > 0 )); then
  warn "GPU: solo $((vram_kib / 1024)) MiB en VRAM; puede haber capas en CPU"
else
  warn "GPU: no pude leer VRAM residente del pid ${pid_nuevo:-?}; verificá con --bench"
fi

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
