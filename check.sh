#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# check.sh — Valida que todos los symlinks de stow estén correctos
# Uso: ./check.sh [--fix]
#   --fix: intenta reparar symlinks rotos automáticamente
# ==============================================================================

FIX_MODE=false
[[ "${1:-}" == "--fix" ]] && FIX_MODE=true

INFO="\e[34m[INFO]\e[0m"
OK="\e[32m[OK]\e[0m"
WARN="\e[33m[WARN]\e[0m"
ERR="\e[31m[ERR]\e[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STOW_DIR="$SCRIPT_DIR/stow"
CONFIG_DIR="$SCRIPT_DIR/config"

errors=0
warnings=0
fixed=0

green()  { echo -e "${OK} $*"; }
yellow() { echo -e "${WARN} $*"; }
red()    { echo -e "${ERR} $*"; ((errors++)) || true; }
warn()   { echo -e "${WARN} $*"; ((warnings++)) || true; }

# --- Symlinks esperados: stow_package → destino en $HOME ---
# Shell (archivos planos en $HOME)
declare -A SHELL_LINKS=(
  [".bashrc"]="$HOME/.bashrc"
  [".zshrc"]="$HOME/.zshrc"
  [".zsh_aliases"]="$HOME/.zsh_aliases"
  [".tmux.conf"]="$HOME/.tmux.conf"
  [".gitconfig"]="$HOME/.gitconfig"
  [".config/shell/path.sh"]="$HOME/.config/shell/path.sh"
)

# Nvim (directorio)
NVIM_LINK="$HOME/.config/nvim"
NVIM_STOW_TARGET="$STOW_DIR/nvim/.config/nvim"

# Terminales: stow_package → (directorio destino, archivos internos)
declare -A TERMINAL_KITTY=(
  ["dir"]="$HOME/.config/kitty"
  ["files"]=".config/kitty/kitty.conf .config/kitty/colors/kitty-colors.conf"
)
declare -A TERMINAL_ALACRITTY=(
  ["dir"]="$HOME/.config/alacritty"
  ["files"]=".config/alacritty/alacritty.toml .config/alacritty/colors/alacritty-colors.toml"
)
declare -A TERMINAL_GHOSTTY=(
  ["dir"]="$HOME/.config/ghostty"
  ["files"]=".config/ghostty/config .config/ghostty/colors/ghostty-colors"
)
declare -A TERMINAL_WEZTERM=(
  ["dir"]="$HOME/.config/wezterm"
  ["files"]=".config/wezterm/wezterm.lua"
)
declare -A TERMINAL_ROFI=(
  ["dir"]="$HOME/.config/rofi"
  ["files"]=".config/rofi/config.rasi"
)

# ==============================================================================
# Funciones de validación
# ==============================================================================

# Verifica que un symlink exista, apunte al target correcto y resuelva
check_symlink() {
  local expected_target="$1"  # ruta absoluta del destino esperado
  local label="$2"

  if [[ ! -L "$expected_target" ]]; then
    if [[ -d "$expected_target" ]]; then
      red "DIRECTORIO real donde debería haber symlink: $label"
      red "  → $expected_target es un directorio, no un symlink"
      if $FIX_MODE; then
        yellow "  Intentando backup + re-stow..."
        local backup="${expected_target}.bak.$(date +%s)"
        mv "$expected_target" "$backup"
        green "  Backup: $backup"
        ((fixed++)) || true
        return 1  # indica que se necesita re-stow
      fi
    elif [[ -f "$expected_target" ]]; then
      red "ARCHIVO real donde debería haber symlink: $label"
      red "  → $expected_target es un archivo regular"
      if $FIX_MODE; then
        local backup="${expected_target}.bak.$(date +%s)"
        mv "$expected_target" "$backup"
        green "  Backup: $backup"
        ((fixed++)) || true
        return 1
      fi
    else
      red "NO EXISTE: $label → $expected_target"
      if $FIX_MODE; then
        return 1  # indica que se necesita re-stow
      fi
    fi
    return 1
  fi

  # Es symlink, verificar que resuelva
  local resolved
  resolved="$(readlink -f "$expected_target" 2>/dev/null || true)"

  if [[ -z "$resolved" ]] || [[ ! -e "$resolved" ]]; then
    local current_target
    current_target="$(readlink "$expected_target")"
    red "SYMLINK ROTO: $label"
    red "  → apunta a: $current_target"
    red "  → no resuelve a ningún archivo válido"
    if $FIX_MODE; then
      rm -f "$expected_target"
      ((fixed++)) || true
      return 1
    fi
    return 1
  fi

  green "OK: $label → $(basename "$resolved")"
  return 0
}

# Valida symlink de directorio completo (ej. ~/.config/rofi → stow/rofi/.config/rofi)
check_dir_symlink() {
  local dir_link="$1" stow_dir="$2" files="$3" label="$4"

  if [[ ! -L "$dir_link" ]]; then
    red "DIRECTORIO real donde debería haber symlink: $label"
    red "  → $dir_link no es symlink"
    return 1
  fi

  local resolved
  resolved="$(readlink -f "$dir_link" 2>/dev/null || true)"
  if [[ "$resolved" != "$(readlink -f "$stow_dir")" ]]; then
    red "SYMLINK MAL APUNTADO: $label"
    red "  → $dir_link apunta a $resolved, se esperaba $stow_dir"
    return 1
  fi

  local all_ok=true
  for f in $files; do
    if [[ ! -e "$HOME/$f" ]]; then
      red "FALTA ARCHIVO vía symlink: $label → $f"
      all_ok=false
    fi
  done
  $all_ok && green "OK: $label → $(basename "$resolved")"
}

# Verifica symlinks internos de stow (dentro de stow/)
check_stow_internal_symlinks() {
  local pkg_dir="$1"
  local pkg_name
  pkg_name="$(basename "$pkg_dir")"

  while IFS= read -r -d '' link; do
    local dir target resolved
    dir="$(dirname "$link")"
    target="$(readlink "$link")"
    resolved="$(cd "$dir" && readlink -f "$target" 2>/dev/null || true)"

    if [[ -z "$resolved" ]] || [[ ! -e "$resolved" ]]; then
      red "STOW ROTO: $link → $target"
      return 1
    fi
  done < <(find "$pkg_dir" -type l -print0 2>/dev/null)

  return 0
}

# ==============================================================================
# Verificar stow instalado
# ==============================================================================
if ! command -v stow &>/dev/null; then
  red "GNU Stow no está instalado"
  exit 1
fi

# ==============================================================================
# Verificar symlinks internos de stow
# ==============================================================================
echo ""
echo "━━━ Symlinks internos de stow ━━━"
stow_ok=true
for pkg_dir in "$STOW_DIR"/*/; do
  [[ -d "$pkg_dir" ]] || continue
  pkg_name="$(basename "$pkg_dir")"

  if check_stow_internal_symlinks "$pkg_dir"; then
    green "stow/$pkg_name: ok"
  else
    red "stow/$pkg_name: symlinks internos rotos"
    stow_ok=false
  fi
done

# ==============================================================================
# Verificar symlinks en $HOME
# ==============================================================================
echo ""
echo "━━━ Symlinks en \$HOME ━━━"

# Shell
for stow_file in "${!SHELL_LINKS[@]}"; do
  dest="${SHELL_LINKS[$stow_file]}"
  label="shell/$stow_file → $dest"
  check_symlink "$dest" "$label" || true
done

# Nvim
check_symlink "$NVIM_LINK" "nvim → $NVIM_LINK" || true

# Terminales
for term_name in kitty alacritty ghostty wezterm rofi; do
  var_name="TERMINAL_${term_name^^}"
  eval 'dir="${'"$var_name"'[dir]}"'
  eval 'files="${'"$var_name"'[files]}"'

  if [[ -L "$dir" ]]; then
    check_dir_symlink "$dir" "$STOW_DIR/$term_name${dir#$HOME}" "$files" "$term_name" || true
    continue
  fi

  for f in $files; do
    src="$STOW_DIR/$term_name/$f"
    dest="$HOME/$f"
    label="$term_name → $dest"

    if [[ ! -e "$dest" ]] && [[ ! -L "$dest" ]]; then
      warn "No aplicado: $label"
    else
      check_symlink "$dest" "$label" || true
    fi
  done
done

# Opencode (archivos en ~/.config/opencode)
echo ""
echo "━━━ opencode ━━━"
for f in ".config/opencode/AGENTS.md" ".config/opencode/opencode.json" ".config/opencode/opencode.jsonc" ".config/opencode/package.json" ".config/opencode/package-lock.json" ".config/opencode/plugins/session-exporter.js"; do
  dest="$HOME/$f"
  label="opencode → $dest"
  if [[ ! -e "$dest" ]] && [[ ! -L "$dest" ]]; then
    warn "No aplicado: $label"
  else
    check_symlink "$dest" "$label" || true
  fi
done

# ==============================================================================
# Verificar que no haya archivos reales donde deberían ser symlinks
# ==============================================================================
echo ""
echo "━━━ Conflictos potenciales ━━━"

conflict_paths=(
  "$HOME/.config/kitty"
  "$HOME/.config/alacritty"
  "$HOME/.config/ghostty"
  "$HOME/.config/wezterm"
  "$HOME/.config/nvim"
  "$HOME/.config/rofi"
  "$HOME/.config/i3"
)

for p in "${conflict_paths[@]}"; do
  if [[ -d "$p" ]] && [[ ! -L "$p" ]]; then
    warn "Directorio real (no symlink): $p"
    if $FIX_MODE; then
      backup="${p}.bak.$(date +%s)"
      mv "$p" "$backup"
      green "  Backup → $backup"
      ((fixed++)) || true
    fi
  fi
done

# ==============================================================================
# Resumen
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $errors -eq 0 ]] && [[ $warnings -eq 0 ]]; then
  green "Todo OK ✓"
elif [[ $errors -eq 0 ]]; then
  yellow "$warnings advertencia(s), 0 errores"
else
  red "$errors error(es), $warnings advertencia(s)"
fi
if $FIX_MODE && [[ $fixed -gt 0 ]]; then
  yellow "$fixed item(es) reparados (backups creados)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit $errors
