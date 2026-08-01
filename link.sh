#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# link.sh — Aplica dotfiles con GNU Stow + valida con check.sh
# Uso:
#   ./link.sh              # Aplica todos los paquetes stow
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
      echo "  Sin args:      aplica todos los paquetes stow"
      echo "  paquete...:    aplica solo los paquetes indicados"
      echo "  --check:       solo valida symlinks, no aplica"
      echo "  --fix:         aplica + repara directorios conflictivos"
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
# Paquetes disponibles
# ==============================================================================
ALL_PACKAGES=(
  shell
  nvim
  kitty
  alacritty
  ghostty
  wezterm
  rofi
  hypr
  waybar
  dunst
)

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

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
  PACKAGES=("${ALL_PACKAGES[@]}")
fi

# Validar que todos los paquetes existan
for pkg in "${PACKAGES[@]}"; do
  [[ -d "$STOW_DIR/$pkg" ]] || die "Paquete no encontrado: stow/$pkg"
done

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
  local pkg="$1"
  local stow_pkg="$STOW_DIR/$pkg"

  log "Verificando conflictos para: $pkg"

  # Nunca tocar directorios críticos del sistema
  local protected_dirs=("$HOME/.config" "$HOME/.local" "$HOME/.cache")

  # Encontrar solo archivos que stow crearía como symlinks
  while IFS= read -r -d '' entry; do
    local relative="${entry#"$stow_pkg/"}"
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
  done < <(find "$stow_pkg" -type f -print0 2>/dev/null)
}

# ==============================================================================
# Aplicar stow
# ==============================================================================
apply_stow() {
  local pkg="$1"
  local stow_pkg="$STOW_DIR/$pkg"

  log "Aplicando: stow $pkg"

  # Asegurar que los directorios padre existan
  mkdir -p "$HOME/.config" 2>/dev/null || true

  # Aplicar stow con --restow (elimina y recrea symlinks)
  stow --restow \
    --dir "$STOW_DIR" \
    --target "$HOME" \
    "$pkg" 2>/dev/null

  ok "stow/$pkg → $HOME"
}

# ==============================================================================
# Flujo principal
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Dotfiles Linker (GNU Stow)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

applied=0
skipped=0

for pkg in "${PACKAGES[@]}"; do
  check_requirements "$pkg" || { ((skipped++)) || true; continue; }

  if $FIX_MODE; then
    resolve_conflicts "$pkg"
  fi

  if apply_stow "$pkg"; then
    ((applied++)) || true
  else
    ((skipped++)) || true
  fi
done

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
