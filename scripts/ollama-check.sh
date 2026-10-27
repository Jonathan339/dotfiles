#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ollama-check.sh — Verifica la IA local (Ollama sobre Intel Arc B570 / Vulkan)
#
# Uso:
#   ./scripts/ollama-check.sh                 # inventario, config y GPU
#   ./scripts/ollama-check.sh --bench         # además mide tok/s (modelo cargado)
#   ./scripts/ollama-check.sh --bench MODELO  # mide tok/s de MODELO
#
# Solo lee: no toca configuración ni descarga nada.
# Para re-aplicar el drop-in del servicio: sudo scripts/setup-ollama-arc.sh
# ==============================================================================

OLLAMA_URL="http://127.0.0.1:11434"

OK_=0
WARN_=0
ERR_=0
ok()   { echo -e "  \e[32m[OK]\e[0m $*";   OK_=$((OK_ + 1)); }
warn() { echo -e "  \e[33m[WARN]\e[0m $*"; WARN_=$((WARN_ + 1)); }
err()  { echo -e "  \e[31m[ERR]\e[0m $*";  ERR_=$((ERR_ + 1)); }
titulo() { echo; echo "── $* ──"; }

# ==============================================================================
# Bench: tok/s de un modelo (vía API local, sin ruido de spinner)
# ==============================================================================
bench() {
  local modelo="$1"
  MODELO="$modelo" python3 - <<'PY'
import json, os, time, urllib.request

modelo = os.environ["MODELO"]
req = urllib.request.Request(
    "http://127.0.0.1:11434/api/generate",
    data=json.dumps({
        "model": modelo,
        "prompt": "Explicá en dos frases para qué sirve una GPU.",
        "stream": False,
        "think": False,
        "options": {"num_predict": 150},
    }).encode(),
    headers={"Content-Type": "application/json"},
)

t0 = time.time()
with urllib.request.urlopen(req, timeout=900) as r:
    d = json.load(r)

print(f"  {modelo}: {d['eval_count'] / d['eval_duration'] * 1e9:.1f} tok/s | "
      f"prefill {d['prompt_eval_count'] / d['prompt_eval_duration'] * 1e9:.1f} tok/s | "
      f"carga {d['load_duration'] / 1e9:.1f}s | total {time.time() - t0:.1f}s")
PY
  echo "  (reparto actual:)"
  ollama ps | tail -n +2 | sed 's/^/    /'
}

# ==============================================================================
# Argumentos
# ==============================================================================
BENCH=false
MODELO_BENCH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bench) BENCH=true; shift ;;
    --help|-h) sed -n '4,12p' "$0"; exit 0 ;;
    *) MODELO_BENCH="$1"; shift ;;
  esac
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  IA local — Ollama + Intel Arc B570"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ==============================================================================
titulo "Paquetes"
# ==============================================================================
for pkg in ollama ollama-vulkan; do
  if pacman -Q "$pkg" &>/dev/null; then
    ok "$pkg $(pacman -Q "$pkg" | awk '{print $2}')"
  else
    err "$pkg NO instalado (sudo pacman -S $pkg)"
  fi
done

# ==============================================================================
titulo "Servicio"
# ==============================================================================
if systemctl is-active ollama &>/dev/null; then
  ok "ollama.service activo"
else
  err "ollama.service NO está activo (sudo systemctl start ollama)"
fi

if systemctl is-enabled ollama &>/dev/null; then
  ok "habilitado al arrancar"
else
  warn "no está habilitado al arrancar (sudo systemctl enable ollama)"
fi

if curl -sf --max-time 5 "$OLLAMA_URL/api/version" >/dev/null 2>&1; then
  ok "responde en $OLLAMA_URL ($(curl -s --max-time 5 "$OLLAMA_URL/api/version" | python3 -c 'import json,sys; print("v" + json.load(sys.stdin)["version"])'))"
else
  err "no responde en $OLLAMA_URL"
fi

# El instalador oficial deja su propio unit en /etc/systemd/system (sin OLLAMA_MODELS)
EXEC_SVC="$(systemctl show ollama.service -p ExecStart --value 2>/dev/null | grep -o '/[^ ;]*' | head -1 || true)"
if [[ -n "$EXEC_SVC" && "$EXEC_SVC" != "/usr/bin/ollama" ]]; then
  warn "el servicio corre $EXEC_SVC, no el binario del paquete (/usr/bin/ollama)"
fi

# ==============================================================================
titulo "Configuración del servicio (drop-in)"
# ==============================================================================
DROPIN=/etc/systemd/system/ollama.service.d/override.conf
if [[ -r "$DROPIN" ]]; then
  ok "drop-in presente: $DROPIN"
else
  warn "sin drop-in (¿corriste sudo scripts/setup-ollama-arc.sh?)"
fi

CONFIG_LINE="$(journalctl -u ollama -b --no-pager 2>/dev/null | grep "server config" | tail -1 || true)"
if [[ -z "$CONFIG_LINE" ]]; then
  warn "no se pudo leer el journal del servicio (variables sin verificar)"
else
  declare -A ESPERADO=(
    [OLLAMA_VULKAN]="true"
    [OLLAMA_FLASH_ATTENTION]="true"
    [OLLAMA_KV_CACHE_TYPE]="q8_0"
    [OLLAMA_CONTEXT_LENGTH]="32768"
    [OLLAMA_MAX_LOADED_MODELS]="1"
    [OLLAMA_KEEP_ALIVE]="30m0s"
    # Sin esto el daemon busca los modelos en $HOME/.ollama/models y ve el store vacío
    [OLLAMA_MODELS]="/var/lib/ollama"
  )
  for var in "${!ESPERADO[@]}"; do
    valor="${ESPERADO[$var]}"
    if grep -q "$var:$valor" <<<"$CONFIG_LINE"; then
      ok "$var=$valor"
    else
      actual="$(grep -o "$var:[^ ]*" <<<"$CONFIG_LINE" | head -1 || true)"
      warn "$var esperaba '$valor' y el servicio tiene '${actual#*:}'"
    fi
  done
fi

# ==============================================================================
titulo "GPU (Vulkan)"
# ==============================================================================
COMPUTE_LINE="$(journalctl -u ollama -b --no-pager 2>/dev/null | grep "inference compute" | tail -1 || true)"
if [[ -z "$COMPUTE_LINE" ]]; then
  warn "el journal no muestra GPU detectada (¿servicio reiniciado?)"
elif grep -q "Arc" <<<"$COMPUTE_LINE"; then
  ok "detectada: $(grep -o 'description="[^"]*"' <<<"$COMPUTE_LINE" | cut -d'"' -f2)"
  ok "VRAM: $(grep -o 'total="[^"]*"' <<<"$COMPUTE_LINE" | cut -d'"' -f2) (disponible $(grep -o 'available="[^"]*"' <<<"$COMPUTE_LINE" | cut -d'"' -f2))"
  if grep -q "library=Vulkan" <<<"$COMPUTE_LINE"; then
    ok "backend Vulkan"
  else
    err "backend distinto de Vulkan"
  fi
else
  err "no se detecta la Arc: $(grep -o 'description="[^"]*"' <<<"$COMPUTE_LINE" | cut -d'"' -f2)"
fi

if JOURNAL_IGPU="$(journalctl -u ollama -b --no-pager 2>/dev/null | grep 'dropping integrated GPU' | tail -1)" && [[ -n "$JOURNAL_IGPU" ]]; then
  ok "iGPU AMD descartada (esperado; ver OLLAMA_IGPU_ENABLE si algún día se quiere)"
fi

# ==============================================================================
titulo "Modelos instalados"
# ==============================================================================
if ollama list 2>/dev/null | tail -n +2 | grep -q .; then
  ollama list | sed 's/^/  /'
else
  err "ollama no ve ningún modelo (revisá OLLAMA_MODELS: systemctl cat ollama)"
fi

# ==============================================================================
titulo "Modelos cargados y reparto de VRAM"
# ==============================================================================
if ollama ps 2>/dev/null | tail -n +2 | grep -q .; then
  ollama ps | sed 's/^/  /'
  if ollama ps | tail -n +2 | grep -q "CPU/GPU"; then
    warn "alguno está parcial en CPU: normal en 12B+ con 10 GB (baja la calidad solo si el % de CPU sube mucho)"
  else
    ok "todo en GPU"
  fi
else
  warn "ningún modelo cargado (se carga al usar; keep-alive 30m)"
fi

# ==============================================================================
titulo "Integración con OpenCode"
# ==============================================================================
CONFIG_OPENCODE="$HOME/.config/opencode/opencode.json"
if [[ -r "$CONFIG_OPENCODE" ]]; then
  SALIDA_OPENCODE="$(CONFIG_OPENCODE="$CONFIG_OPENCODE" python3 - <<'PY'
import json, os, urllib.request

try:
    with open(os.environ["CONFIG_OPENCODE"]) as f:
        cfg = json.load(f)
except json.JSONDecodeError as e:
    print(f"  [ERR] opencode.json no es JSON válido: {e}")
    raise SystemExit(0)

prov = (cfg.get("providers") or cfg.get("provider") or {}).get("ollama")
if not prov:
    print("  [WARN] no hay provider 'ollama' declarado")
    raise SystemExit(0)

forma = "V2" if "providers" in cfg else "V1"
declarados = list((prov.get("models") or {}).keys())
print(f"  [OK] provider ollama en formato {forma}: {', '.join(declarados) or '(sin modelos declarados)'}")

try:
    with urllib.request.urlopen("http://127.0.0.1:11434/api/tags", timeout=5) as r:
        instalados = {m["name"] for m in json.load(r).get("models", [])}
except Exception:
    print("  [WARN] no se pudo consultar /api/tags para comparar")
    raise SystemExit(0)

for modelo in declarados:
    if modelo in instalados:
        print(f"  [OK] {modelo} declarado en opencode y presente en ollama")
    else:
        print(f"  [ERR] {modelo} declarado en opencode pero NO está instalado")
PY
)"
  printf '%s\n' "$SALIDA_OPENCODE"
  # El bloque de Python imprime [OK]/[WARN]/[ERR]: contarlos acá o el resumen miente
  OK_=$((OK_ + $(grep -c '\[OK\]' <<<"$SALIDA_OPENCODE" || true)))
  WARN_=$((WARN_ + $(grep -c '\[WARN\]' <<<"$SALIDA_OPENCODE" || true)))
  ERR_=$((ERR_ + $(grep -c '\[ERR\]' <<<"$SALIDA_OPENCODE" || true)))
else
  warn "no se encontró $CONFIG_OPENCODE"
fi

# ==============================================================================
titulo "Bench"
# ==============================================================================
if $BENCH; then
  if [[ -z "$MODELO_BENCH" ]]; then
    MODELO_BENCH="$(ollama ps 2>/dev/null | tail -n +2 | awk 'NR==1 {print $1}')"
    [[ -z "$MODELO_BENCH" ]] && MODELO_BENCH="$(ollama list 2>/dev/null | tail -n +2 | awk 'NR==1 {print $1}')"
  fi
  echo "  midiendo $MODELO_BENCH (referencias medidas: ver skill ia-local)"
  bench "$MODELO_BENCH"
else
  echo "  (usá --bench [modelo] para medir tok/s)"
fi

# ==============================================================================
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  $OK_ OK · $WARN_ advertencia(s) · $ERR_ error(es)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ $ERR_ -eq 0 ]]
