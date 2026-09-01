#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# link.sh — Aplica dotfiles con GNU Stow + valida con check.sh
#
# Modelo de capas (ordre de precedencia, la última gana):
#   stow/shared           → común a cualquier equipo
#   stow/os/<so>          → específico del sistema operativo (detección automática)
#   stow/wm/<wm>          → específico del escritorio (detección automática)
#   stow/host/<hostname>  → específico del equipo (detección automática)
#
# Uso:
#   ./link.sh              # Aplica todos los paquetes de todas las capas
#   ./link.sh shell nvim   # Aplica solo paquetes específicos
#   ./link.sh --check      # Solo valida, no aplica
#   ./link.sh --fix        # Aplica + repara problemas conocidos
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
STOW_DIR="$REPO_ROOT/stow"

INFO="\e[34m[INFO]\e[0m"
OK="\e[32m[OK]\e[0m"
WARN="\e[33m[WARN]\e[0m"
ERR="\e[31m[ERR]\e[0m"

log()   { echo -e "$INFO $*"; }
ok()    { echo -e "$OK $*"; }
warn()  { echo -e "$WARN $*"; }
die()   { echo -e "$ERR $*"; exit 1; }

CHECK_ONLY=false
FIX_MODE=false
PACKAGES=()

# ==============================================================================
# Parse args
# ==============================================================================
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=true; shift ;;
    --fix)   FIX_MODE=true; shift ;;
    --help|-h)
      echo "Uso: ./link.sh [--check] [--fix] [paquete...]"
      echo ""
      echo "  Sin args:      aplica todos los paquetes stow de todas las capas"
      echo "  paquete...:    aplica solo los paquetes indicados (busca en todas las capas)"
      echo "  --check:       solo valida symlinks, no aplica"
      echo "  --fix:         aplica + repara directorios conflictivos"
      echo ""
      echo "Capas detectadas automáticamente:"
      echo "  stow/shared           (común)"
      echo "  stow/os/<so>          (según /etc/os-release)"
      echo "  stow/wm/<wm>          (según XDG_CURRENT_DESKTOP / pgrep)"
      echo "  stow/host/<hostname>  (según hostname)"
      exit 0
      ;;
    *)      PACKAGES+=("$1"); shift ;;
  esac
done

# ==============================================================================
# Verificar dependencias
# ==============================================================================
command -v stow &>/dev/null || die "GNU Stow no está instalado. Instalalo: sudo apt install stow"

# ==============================================================================
# Detección automática de capas
# ==============================================================================

# Fing SD del sistema operativo: debian, arch, fedora, ... (bajo /etc/os-release)
detect_os() {
  local id id_like candidate
  id=""; id_like=""
  [[ -r /etc/os-release ]] && . /etc/os-release 2>/dev/null || return 1

  for candidate in "$id" $id_like; do
    [[ -z "$candidate" ]] && continue
    candidate="${candidate,,}"
    if [[ -d "$STOW_DIR/os/$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

# Fing WM/DE activo, en minúsculas y normalizado (hyprland, xfce, gnome, ...)
detect_wm() {
  local wm candidate

  wm="${XDG_CURRENT_DESKTOP:-}"
  wm="${wm%%:*}"        # ej. "ubuntu:GNOME" → "ubuntu"
  [[ -n "$wm" ]] && wm="${wm,,}"

  # Fallbacks por proceso cuando no hay XDG_CURRENT_DESKTOP
  if [[ -z "$wm" ]] && pgrep -x Hyprland &>/dev/null; then
    wm="hyprland"
  fi
  if [[ $wm != hyprland ]] && pgrep -x xfce4-session &>/dev/null; then
    wm="xfce"
  fi

  if [[ -n "$wm" ]] && [[ -d "$STOW_DIR/wm/$wm" ]]; then
    echo "$wm"
    return 0
  fi
  return 1
}

# Fing strings del equipo (solo si hay capa definida)
detect_host() {
  local h
  h="$(hostname 2>/dev/null || true)"
  [[ -z "$h" ]] && return 1
  [[ -d "$STOW_DIR/host/$h" ]] || return 1
  echo "$h"
  return 0
}

# ==============================================================================
# Paquetes disponibles por capa
# ==============================================================================
LAYERS=()
layer_names="shared"
[[ -d "$STOW_DIR/shared" ]] && LAYERS+=("stow/shared")

if so="$(detect_os)"; then
  LAYERS+=("stow/os/$so")
  layer_names="$layer_names, os/$so"
fi
if wm="$(detect_wm)"; then
  LAYERS+=("stow/wm/$wm")
  layer_names="$layer_names, wm/$wm"
fi
if host="$(detect_host)"; then
  LAYERS+=("stow/host/$host")
  layer_names="$layer_names, host/$host"
fi

# Programas requeridos por cada paquete (comando a verificar antes de stow)
declare -A REQUIREMENTS
REQUIREMENTS[kitty]="kitty"
REQUIREMENTS[alacritty]="alacritty"
REQUIREMENTS[ghostty]="ghostty"
REQUIREMENTS[wezterm]="wezterm"
REQUIREMENTS[nvim]="nvim"
REQUIREMENTS[rofi]="rofi"
REQUIREMENTS[hypr]="Hyprland"
REQUIREMENTS[waybar]="waybar"
REQUIREMENTS[dunst]="dunst"
REQUIREMENTS[opencode]="opencode"

# Resuelve un paquete a su capa. Devuelve la ruta del paquete en la última capa
# donde exista (precedencia: shared < os < wm < host).
resolve_pkg_dir() {
  local pkg="$1" layer dir last=""
  for layer in "${LAYERS[@]}"; do
    dir="$STOW_DIR/$layer/$pkg"
    if [[ -d "$dir" ]]; then
      last="$dir"
    fi
  done
  [[ -n "$last" ]] && echo "$last" && return 0
  return 1
}

# ==============================================================================
# Solo check
# ==============================================================================
if $CHECK_ONLY; then
  log "Validando symlinks..."
  exec "$REPO_ROOT/check.sh"
fi

# ==============================================================================
# Validar requisitos antes de stow
# ==============================================================================
check_requirements() {
  local pkg="$1"
  local cmd="${REQUIREMENTS[$pkg]:-}"

  [[ -z "$cmd" ]] && return 0

  if ! command -v "$cmd" &>/dev/null; then
    warn "'$cmd' no está instalado. Saltando stow/$pkg."
    return 1
  fi
}

# ==============================================================================
# Resolver conflictos antes de stow
# ==============================================================================
resolve_conflicts() {
  local pkg_dir="$1"
  local layer_pkg_dir
  layer_pkg_dir="$STOW_DIR/$pkg_dir"

  log "Verificando conflictos para: $1"

  # Nunca tocar directorios críticos del sistema
  local protected_dirs=("$HOME/.config" "$HOME/.local" "$HOME/.cache")

  # Encontrar solo archivos que stow crearía como symlinks
  while IFS= read -r -d '' entry; do
    local relative="${entry#"$layer_pkg_dir/"}"
    local target="$HOME/$relative"

    # Proteger directorios padre nunca moverlos
    local skip=false
    for protected in "${protected_dirs[@]}"; do
      if [[ "$target" == "$protected" ]] || [[ "$target" == "$protected/"* ]]; then
        # Solo actuar si el target es el archivo exacto, no un directorio padre
        if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
          skip=true
          break
        fi
      fi
    done
    $skip && continue

    # Si el target es un directorio real donde stow espera un symlink
    if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
      # Solo mover si es un directorio vacío o de stow
      if [[ -z "$(ls -A "$target" 2>/dev/null)" ]]; then
        warn "Directorio vacío (no symlink): $target"
        rmdir "$target" 2>/dev/null || true
      else
        warn "Directorio con contenido: $target (skip, resolvé manualmente)"
        continue
      fi
    fi

    # Si el target es un archivo regular donde stow espera un symlink
    if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
      local backup="${target}.bak.$(date +%s)"
      warn "Conflicto: $target (no es symlink)"
      mv "$target" "$backup"
      ok "Backup → $backup"
    fi

    # Si es un symlink roto, eliminarlo
    if [[ -L "$target" ]]; then
      local resolved
      resolved="$(readlink -f "$target" 2>/dev/null || true)"
      if [[ -z "$resolved" ]] || [[ ! -e "$resolved" ]]; then
        warn "Symlink roto: $target → $(readlink "$target")"
        rm -f "$target"
        ok "Eliminado symlink roto"
      fi
    fi
  done < <(find "$layer_pkg_dir" -type f -print0 2>/dev/null)
}

# ==============================================================================
# Aplicar stow
# ==============================================================================
apply_stow() {
  local pkg_dir="$1" pkg_layer
  pkg_layer="$(dirname "$pkg_dir")"

  log "Aplicando: stow -d $pkg_layer -t \$HOME ${pkg_layer##*/}/$(basename "$pkg_dir")"

  # Asegurar que los directorios padre existan
  mkdir -p "$HOME/.config" 2>/dev/null || true

  # Aplicar stow con --restow (elimina y recrea symlinks)
  stow --restow \
    --dir "$pkg_layer" \
    --target "$HOME" \
    "$(basename "$pkg_dir")" 2>/dev/null

  ok "$(basename "$pkg_dir") → $HOME"
}

# ==============================================================================
# Flujo principal
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Dotfiles Linker (GNU Stow)"
echo "  Capas: $layer_names"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

applied=0
skipped=0

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  # Aplicar todos los paquetes de cada capa, en orden de precedencia
  for layer in "${LAYERS[@]}"; do
    for pkg_dir in "$layer"/*/; do
      [[ -d "$pkg_dir" ]] || continue
      pkg="$(basename "$pkg_dir")"
      check_requirements "$pkg" || { ((skipped++)) || true; continue; }

      if $FIX_MODE; then
        resolve_conflicts "$pkg_dir"
      fi

      if apply_stow "$pkg_dir"; then
        ((applied++)) || true
      else
        ((skipped++)) || true
      fi
    done
  done
else
  # Aplicar solo paquetes indicados (resueltos en la última capa donde existan)
  for pkg in "${PACKAGES[@]}"; do
    pkg_dir="$(resolve_pkg_dir "$pkg")" || { warn "Paquete no encontrado en ninguna capa: $pkg"; ((skipped++)) || true; continue; }

    check_requirements "$pkg" || { ((skipped++)) || true; continue; }

    if $FIX_MODE; then
      resolve_conflicts "$pkg_dir"
    fi

    if apply_stow "$pkg_dir"; then
      ((applied++)) || true
    else
      ((skipped++)) || true
    fi
  done
fi

# ==============================================================================
# Validación
# ==============================================================================
echo ""
log "Validando symlinks..."
echo ""

if "$REPO_ROOT/check.sh"; then
  echo ""
  ok "Linker completado: $applied paquete(s) aplicado(s)"
else
  echo ""
  warn "Algunos symlinks tienen problemas. Revisá la salida arriba."
  if ! $FIX_MODE; then
    warn "Tip: ejecutá './link.sh --fix' para intentar reparar automáticamente."
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"