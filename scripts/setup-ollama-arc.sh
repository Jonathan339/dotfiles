#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# setup-ollama-arc.sh
# Ajusta el servicio de Ollama para la Intel Arc B570 (backend Vulkan):
#   - flash attention activada (más rápido y menos memoria en el Arc)
#   - KV cache cuantizada q8_0 (entra más contexto en los 10 GB de VRAM)
#   - límites acordes a una GPU de 10 GB (1 modelo cargado, keep-alive 30m)
# Escribe un drop-in de systemd y reinicia el servicio. Requiere root:
#   sudo ~/.dotfiles/scripts/setup-ollama-arc.sh
# ==============================================================================

DROPIN_DIR=/etc/systemd/system/ollama.service.d
DROPIN="$DROPIN_DIR/override.conf"

if [[ $EUID -ne 0 ]]; then
  echo "Este script necesita root: sudo $0" >&2
  exit 1
fi

if ! pacman -Q ollama &>/dev/null; then
  echo "Ollama no está instalado (falta el paquete ollama). Nada que configurar." >&2
  exit 1
fi

if ! pacman -Q ollama-vulkan &>/dev/null; then
  echo "AVISO: falta ollama-vulkan; Ollama no usará el Arc. Instalalo con:" >&2
  echo "  sudo pacman -S ollama-vulkan" >&2
fi

mkdir -p "$DROPIN_DIR"

cat > "$DROPIN" <<'EOF'
# Generado por ~/.dotfiles/scripts/setup-ollama-arc.sh — Intel Arc B570 (Vulkan)
[Service]
# Flash attention: menos VRAM y más velocidad en el Arc
Environment="OLLAMA_FLASH_ATTENTION=1"
# KV cache cuantizada: permite más contexto dentro de los 10 GB de VRAM
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
# Contexto por defecto (bajalo si un modelo grande no entra entero en VRAM).
# 32k: el prompt base de OpenCode ronda los 8-9k tokens, así que 8192 no alcanza
# ni para el system prompt. Con KV q8_0 un 4B Q8 de ~5 GB sigue entrando en la Arc.
Environment="OLLAMA_CONTEXT_LENGTH=32768"
# Sin VRAM para dos modelos: uno a la vez
Environment="OLLAMA_MAX_LOADED_MODELS=1"
# Mantener el modelo cargado entre consultas
Environment="OLLAMA_KEEP_ALIVE=30m"
EOF

systemctl daemon-reload
systemctl restart ollama

estado="$(systemctl is-active ollama)"
echo "OK: $DROPIN escrito y servicio reiniciado (estado: $estado)."
echo "Comprobá que el Arc aparezca como GPU:"
echo "  ollama ps"
