#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# llama-check.sh — Verifica el stack de IA local (llama.cpp + OpenCode + systemd)
#
# Uso:
#   ./scripts/llama-check.sh           # inventario y coherencia (solo lectura)
#   ./scripts/llama-check.sh --bench   # además mide tok/s y tool-calling
#
# No cambia nada: no reinicia servicios ni edita configs. Si algo falla, imprime
# el comando exacto para arreglarlo.
#
# Cambiar de modelo: ./scripts/llama-model.sh <coder|4b|9b|list>
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/llama.sh
source "${SCRIPT_DIR}/lib/llama.sh"

MODELS_DIR="${HOME}/models"
LINK="${HOME}/.config/llama-current"
UNIT="llama-server"
OPENCODE_JSON="${HOME}/.config/opencode/opencode.json"

OK_=0
WARN_=0
ERR_=0
ok()    { echo -e "  \e[32m[OK]\e[0m $*";   OK_=$((OK_ + 1)); }
warn()  { echo -e "  \e[33m[WARN]\e[0m $*"; WARN_=$((WARN_ + 1)); }
err()   { echo -e "  \e[31m[ERR]\e[0m $*";  ERR_=$((ERR_ + 1)); }
info()  { echo -e "  \e[36m[..]\e[0m $*"; }
titulo() { echo; echo "── $* ──"; }

uso() {
  sed -n '3,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

BENCH=0
case "${1:-}" in
  --bench) BENCH=1 ;;
  -h|--help) uso; exit 0 ;;
  "") ;;
  *) echo "argumento desconocido: $1 (usá --bench o --help)" >&2; exit 2 ;;
esac

# ==============================================================================
# 1. Servicio
# ==============================================================================
titulo "Servicio"

estado=$(systemctl --user is-active "$UNIT" 2>/dev/null || true)
if [[ $estado == active ]]; then
  ok "systemd: $UNIT activo"
else
  err "systemd: $UNIT ${estado:-desconocido} → systemctl --user start $UNIT"
fi

habilitado=$(systemctl --user is-enabled "$UNIT" 2>/dev/null || true)
if [[ $habilitado == enabled ]]; then
  ok "arranca en el login (enabled)"
else
  warn "no arranca en el login (${habilitado:-?}) → systemctl --user enable $UNIT"
fi

# ==============================================================================
# 2. Endpoint
# ==============================================================================
titulo "Endpoint"

serve_sh=""
if [[ -L $LINK ]]; then
  serve_sh=$(readlink -f "$LINK")
  [[ -f $serve_sh ]] || serve_sh=""
fi

if [[ -z $serve_sh ]]; then
  warn "sin selector $LINK → el unit cae al 9B por defecto (creálo con llama-model.sh)"
  puerto=8082
else
  puerto=$(serve_var "$serve_sh" port || echo 8082)
  info "selector → ${serve_sh#"$HOME"/}"
fi
BASE="http://127.0.0.1:${puerto}"

if ss -ltn "sport = :$puerto" 2>/dev/null | grep -q LISTEN; then
  ok "puerto $puerto escuchando"
else
  err "nada escuchando en :$puerto → journalctl --user -u $UNIT -n 30 --no-pager"
fi

json=$(api_models "$BASE" || true)
alias_actual=$(printf '%s' "$json" | jq -r '.data[0].id // empty' 2>/dev/null || true)
ctx_actual=$(printf '%s' "$json" | jq -r '.data[0].meta.n_ctx // empty' 2>/dev/null || true)

if [[ -n $alias_actual ]]; then
  ok "sirviendo: $alias_actual (ctx $ctx_actual)"
elif ss -ltn "sport = :$puerto" 2>/dev/null | grep -q LISTEN; then
  warn "/v1/models no responde todavía: el modelo puede estar cargando (~80 s en frío)"
else
  err "/v1/models inaccesible"
fi

# ==============================================================================
# 3. Coherencia serve.sh ↔ server
# ==============================================================================
titulo "Coherencia serve.sh ↔ server"

if [[ -z $serve_sh ]]; then
  info "sin serve.sh que comparar (falta el selector)"
elif [[ -z $alias_actual ]]; then
  info "sin modelo servido que comparar"
else
  alias_esperado=$(serve_var "$serve_sh" alias || true)
  ctx_esperado=$(serve_var "$serve_sh" ctx_size || true)

  if [[ -n $alias_esperado && $alias_actual != "$alias_esperado" ]]; then
    err "el server sirve '$alias_actual' pero ${serve_sh#"$HOME"/} declara alias '$alias_esperado'"
  elif [[ -n $alias_esperado ]]; then
    ok "alias coincide ($alias_esperado)"
  else
    warn "no se pudo leer 'alias' de ${serve_sh#"$HOME"/}"
  fi

  if [[ -n $ctx_esperado && $ctx_actual != "$ctx_esperado" ]]; then
    err "ctx del server ($ctx_actual) != ctx_size de serve.sh ($ctx_esperado)"
  elif [[ -n $ctx_esperado ]]; then
    ok "ctx coincide ($ctx_actual)"
  else
    warn "no se pudo leer 'ctx_size' de ${serve_sh#"$HOME"/}"
  fi
fi

# ==============================================================================
# 4. Coherencia opencode.json
# ==============================================================================
titulo "Coherencia opencode.json"

if ! jq -e . "$OPENCODE_JSON" >/dev/null 2>&1; then
  err "JSON inválido en $OPENCODE_JSON (OpenCode descarta la config entera) → jq -e . $OPENCODE_JSON"
else
  ok "JSON válido"

  default=$(jq -r '.model // empty' "$OPENCODE_JSON")
  if [[ -n $alias_actual ]]; then
    if [[ $default == "llamacpp/$alias_actual" ]]; then
      ok "model default = $default"
    else
      warn "model default '$default' != 'llamacpp/$alias_actual' (el server sirve $alias_actual)"
    fi
  fi

  while IFS=$'\t' read -r id ctx; do
    [[ -n $id ]] || continue
    serve=$(serve_model_dir "$id" || true)
    if [[ -z $serve ]]; then
      warn "$id: declarado sin serve.sh en $MODELS_DIR"
      continue
    fi
    ctx_srv=$(serve_var "$serve" ctx_size || true)
    dir=$(basename "$(dirname "$serve")")
    if [[ -z $ctx ]]; then
      warn "$id: sin limit.context declarado (hereda n_ctx_train del modelo)"
    elif [[ -n $ctx_srv && $ctx != "$ctx_srv" ]]; then
      err "$id: limit.context $ctx != ctx_size $ctx_srv ($dir)"
    else
      ok "$id: ctx $ctx"
    fi
  done < <(jq -r '.providers.llamacpp.models // {} | to_entries[] | "\(.key)\t\(.value.limit.context // "")"' "$OPENCODE_JSON")
fi

# ==============================================================================
# 5. GPU
# ==============================================================================
titulo "GPU"

offload=$(journalctl --user -u "$UNIT" --no-pager -n 5000 2>/dev/null \
  | grep -oE 'offloaded [0-9]+/[0-9]+ layers' | tail -1 || true)
if [[ -n $offload ]]; then
  capas_gpu=${offload#offloaded }
  capas_gpu=${capas_gpu%%/*}
  capas_total=${offload##*/}
  capas_total=${capas_total%% *}
  if [[ $capas_gpu == "$capas_total" ]]; then
    ok "todas las capas en GPU ($offload)"
  else
    err "offload parcial ($offload): parte del modelo está en CPU"
  fi
else
  warn "el journal no reporta offload; confirmá con --bench (>=30 tok/s = GPU)"
fi

device=$(journalctl --user -u "$UNIT" --no-pager -n 5000 2>/dev/null \
  | grep -oE 'dispositivo: vulkan[0-9]+' | tail -1 || true)
if [[ -n $device ]]; then
  info "device pedido: ${device#dispositivo: } (vulkan0 = Arc B570)"
fi

# ==============================================================================
# 6. Extras
# ==============================================================================
titulo "Extras"

if command -v ollama >/dev/null 2>&1; then
  n_ollama=$(ollama list 2>/dev/null | tail -n +2 | grep -c . || true)
  if [[ ${n_ollama:-0} -eq 0 ]]; then
    warn "Ollama instalado en :11434 sin modelos (no compite por VRAM, pero no se usa)"
  else
    ok "Ollama con $n_ollama modelo(s)"
  fi
else
  ok "Ollama no instalado: stack solo llama.cpp"
fi

# ==============================================================================
# 7. Bench (opcional)
# ==============================================================================
if (( BENCH )); then
  titulo "Bench"

  if [[ -z $alias_actual ]]; then
    err "sin modelo servido; no se puede medir"
  else
    payload=$(jq -nc --arg m "$alias_actual" '{
      model: $m,
      messages: [{role: "user", content: "Explicá en una frase para qué sirve una GPU."}],
      max_tokens: 120,
      stream: false
    }')
    resp=$(curl -sS --max-time 300 "$BASE/v1/chat/completions" \
      -H 'Content-Type: application/json' -d "$payload" || true)
    tps=$(printf '%s' "$resp" | jq -r '.timings.predicted_per_second // 0' 2>/dev/null || echo 0)
    tps_int=$(printf '%.0f' "${tps:-0}")
    if (( tps_int >= 30 )); then
      ok "decode ${tps} tok/s"
    elif (( tps_int >= 15 )); then
      warn "decode ${tps} tok/s: lento, sospechar reparto parcial en CPU"
    else
      err "decode ${tps} tok/s: casi seguro en CPU (revisá --device vulkan0 y VRAM libre)"
    fi

    tpayload=$(jq -nc --arg m "$alias_actual" '{
      model: $m,
      messages: [{role: "user", content: "¿Qué hora es? Usá la herramienta."}],
      max_tokens: 200,
      stream: false,
      tools: [{
        type: "function",
        function: {
          name: "get_time",
          description: "Devuelve la hora actual",
          parameters: {type: "object", properties: {}}
        }
      }]
    }')
    tresp=$(curl -sS --max-time 300 "$BASE/v1/chat/completions" \
      -H 'Content-Type: application/json' -d "$tpayload" || true)
    calls=$(printf '%s' "$tresp" | jq -r '(.choices[0].message.tool_calls // []) | length' 2>/dev/null || echo 0)
    ptok=$(printf '%s' "$tresp" | jq -r '.usage.prompt_tokens // 0' 2>/dev/null || echo 0)

    if [[ ${calls:-0} -ge 1 && ${ptok:-0} -gt 100 ]]; then
      ok "tool-calling real (tool_calls=$calls, prompt_tokens=$ptok)"
    else
      err "tool-calling dudoso (tool_calls=${calls:-0}, prompt_tokens=${ptok:-0}; esperado >=1 y >100)"
    fi
  fi
fi

# ==============================================================================
# Resumen
# ==============================================================================
echo
echo "── Resumen ──"
echo "  OK: $OK_ | WARN: $WARN_ | ERR: $ERR_"
if (( ERR_ > 0 )); then
  echo "  → hay errores: revisá los [ERR] de arriba."
  exit 1
fi
echo "  → stack coherente."
