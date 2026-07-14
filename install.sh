#!/usr/bin/env bash
set -euo pipefail

# ===============================
# Dotfiles Installer — Arch/Manjaro
# ===============================

INFO="\e[34m[INFO]\e[0m"
OK="\e[32m[OK]\e[0m"
WARN="\e[33m[WARN]\e[0m"
ERR="\e[31m[ERR]\e[0m"

log() { echo -e "$INFO $*"; }
ok() { echo -e "$OK $*"; }
warn() { echo -e "$WARN $*"; }

failed() {
  echo -e "$ERR Fallo. Revisa el siguiente mensaje:"
  return 1
}

die() {
  echo -e "$ERR $*"
  exit 1
}

trap 'echo -e "\n${ERR} Ocurrió un error. Revisá el siguiente mensaje."' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
CONFIG_MODE="${DOTFILES_CONFIG_MODE:-stow}"
STOW_ADOPT="${DOTFILES_STOW_ADOPT:-false}"
ALL_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL_MODE=true; shift ;;
    --copy) CONFIG_MODE="copy"; shift ;;
    *) shift ;;
  esac
done

command -v sudo >/dev/null || die "Necesitás sudo."
command -v curl >/dev/null || die "Necesitás curl."
command -v git >/dev/null || die "Necesitás git."

PACMAN_PACKAGES=(
  curl wget vlc gnupg seahorse git python-pip rust
  openssl jdk21-openjdk fzf tmux kitty neovim
  xclip wl-clipboard zsh ca-certificates ripgrep stow
  yarn python-virtualenvwrapper lazygit
)

AUR_PACKAGES=(
  android-studio
  spotify
  visual-studio-code-bin
)

AUR_HELPER=""

detect_aur_helper() {
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
  fi
  [[ -n "$AUR_HELPER" ]]
}

package_is_installed() {
  pacman -Q "$1" &>/dev/null
}

init_pacman() {
  if [[ ! -f /etc/pacman.d/mirrorlist ]]; then
    die "No se detectó pacman. ¿Esto es Arch/Manjaro?"
  fi

  if ! command -v paru &>/dev/null && ! command -v yay &>/dev/null; then
    log "Instalando paru (AUR helper)..."
    sudo pacman -S --noconfirm --needed base-devel git
    local tmpdir; tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    (cd "$tmpdir/paru" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
    AUR_HELPER="paru"
    ok "paru instalado."
  else
    detect_aur_helper
  fi
}

install_packages() {
  log "Instalando paquetes del sistema..."
  sudo pacman -Syu --noconfirm "${PACMAN_PACKAGES[@]}"
  ok "Paquetes base instalados."
}

install_aur_packages() {
  detect_aur_helper || init_pacman

  log "Instalando paquetes desde AUR..."
  $AUR_HELPER -S --noconfirm "${AUR_PACKAGES[@]}" || warn "Algunos paquetes AUR fallaron"
  ok "Paquetes AUR instalados."
}

install_aur_pkg() {
  local pkg="$1"
  detect_aur_helper || init_pacman
  $AUR_HELPER -S --noconfirm "$pkg" || warn "Falló la instalación de $pkg"
  ok "$pkg instalado."
}

install_package_if_missing() {
  package_is_installed "$1" && return
  sudo pacman -S --noconfirm "$1"
}

cleanup_conflicting_symlinks() {
  log "Limpiando symlinks conflictivos..."

  local files=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.zsh_aliases"
    "$HOME/.gitconfig"
    "$HOME/.tmux.conf"
    "$HOME/.config/nvim"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/kitty/colors/kitty-colors.conf"
    "$HOME/.config/alacritty/alacritty.toml"
    "$HOME/.config/alacritty/colors/alacritty-colors.toml"
    "$HOME/.config/ghostty/config"
    "$HOME/.config/ghostty/colors/ghostty-colors"
    "$HOME/.config/wezterm/wezterm.lua"
  )

  for file in "${files[@]}"; do
    if [[ -L "$file" ]]; then
      local target
      target="$(readlink "$file")"

      if [[ "$target" == *"$REPO_ROOT"* ]]; then
        rm "$file"
        warn "Symlink eliminado: $file"
      else
        warn "Symlink externo preservado: $file"
      fi
    fi
  done
}

stow_single_pkg() {
  local pkg="$1"
  local stow_dir="$REPO_ROOT/stow"

  install_package_if_missing stow

  [[ -d "$stow_dir/$pkg" ]] || { warn "Paquete stow no encontrado: $pkg"; return 1; }

  if [[ "$STOW_ADOPT" == "true" ]]; then
    stow --adopt --restow --dir "$stow_dir" --target "$HOME" "$pkg"
  else
    stow --restow --dir "$stow_dir" --target "$HOME" "$pkg"
  fi

  ok "Config aplicada: $pkg"
}

stow_config_files() {
  log "Aplicando todos los dotfiles con GNU Stow..."

  cleanup_conflicting_symlinks

  for pkg in shell nvim kitty alacritty ghostty wezterm; do
    stow_single_pkg "$pkg" || true
  done
}

copy_config_files() {
  log "Copiando dotfiles a $HOME..."

  cleanup_conflicting_symlinks

  local config_dir="$REPO_ROOT/config"

  mkdir -p "$HOME/.config/nvim"
  mkdir -p "$HOME/.config/kitty/colors"
  mkdir -p "$HOME/.config/alacritty/colors"
  mkdir -p "$HOME/.config/ghostty/colors"
  mkdir -p "$HOME/.config/wezterm"

  for f in .zshrc .zsh_aliases .bashrc .tmux.conf .gitconfig; do
    [[ -f "$config_dir/$f" ]] && cp -f "$config_dir/$f" "$HOME/$f"
  done

  cp -rf "$config_dir/nvim/." "$HOME/.config/nvim/"
  cp -f "$config_dir/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  cp -f "$config_dir/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  cp -f "$config_dir/colors/kitty-colors.conf" "$HOME/.config/kitty/colors/kitty-colors.conf"
  cp -f "$config_dir/colors/alacritty-colors.toml" "$HOME/.config/alacritty/colors/alacritty-colors.toml"
  cp -f "$config_dir/ghostty/config" "$HOME/.config/ghostty/config"
  cp -f "$config_dir/colors/ghostty-colors" "$HOME/.config/ghostty/colors/ghostty-colors"
  cp -f "$config_dir/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

  ok "Dotfiles copiados a $HOME."
}

backup_dotfiles() {
  local backup_dir="/tmp/dotfiles-backup-$(date +%s)"
  log "Respaldando config actual en $backup_dir ..."
  mkdir -p "$backup_dir"
  for f in .zshrc .zsh_aliases .bashrc .tmux.conf .gitconfig; do
    [[ -f "$HOME/$f" ]] && cp -L "$HOME/$f" "$backup_dir/"
  done
  [[ -d "$HOME/.config/nvim" ]] && cp -rL "$HOME/.config/nvim" "$backup_dir/nvim" 2>/dev/null || true
  ok "Backup guardado en $backup_dir"
}

apply_config_files() {
  backup_dotfiles
  case "$CONFIG_MODE" in
    stow) stow_config_files ;;
    copy) copy_config_files ;;
    *) die "Modo inválido. Usá 'stow' o 'copy'." ;;
  esac
}

install_oh_my_zsh() {
  [[ -d "$HOME/.oh-my-zsh" ]] && {
    warn "Oh My Zsh ya existe."
    return
  }

  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  ok "Oh My Zsh instalado."
}

install_kitty_themes() {
  local themes_dir="$HOME/.config/kitty/kitty-themes"

  [[ -d "$themes_dir" ]] && {
    warn "kitty-themes ya existe."
    return
  }

  mkdir -p "$HOME/.config/kitty"

  git clone --depth=1 \
    https://github.com/dexpota/kitty-themes.git \
    "$themes_dir"

  ok "kitty-themes instalado."
}

install_nerd_fonts() {
  local font="$HOME/.local/share/fonts/DroidSansMNerdFont-Regular.otf"

  [[ -f "$font" ]] && return

  mkdir -p "$HOME/.local/share/fonts"

  curl -fLo "$font" \
    https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf

  ok "Nerd Font instalada."
}

install_neovim() {
  install_package_if_missing neovim
  stow_single_pkg nvim
  ok "Neovim instalado + config aplicada."
}

install_kitty() {
  install_package_if_missing kitty
  stow_single_pkg kitty
  ok "Kitty instalado + config aplicada."
}

install_alacritty() {
  install_package_if_missing alacritty
  stow_single_pkg alacritty
  ok "Alacritty instalado + config aplicada."
}

install_ghostty() {
  install_package_if_missing ghostty
  stow_single_pkg ghostty
  ok "Ghostty instalado + config aplicada."
}

install_wezterm() {
  install_package_if_missing wezterm
  stow_single_pkg wezterm
  ok "WezTerm instalado + config aplicada."
}

install_zsh() {
  install_package_if_missing zsh
  stow_single_pkg shell
  install_oh_my_zsh
  ok "Zsh instalado + config aplicada."
}

install_tmux() {
  install_package_if_missing tmux
  stow_single_pkg shell
  ok "Tmux instalado + config aplicada."
}

install_yarn() {
  install_package_if_missing yarn
  ok "Yarn instalado."
}

install_bun() {
  if command -v bun >/dev/null; then
    ok "Bun ya instalado."
    return
  fi

  log "Instalando Bun..."
  curl -fsSL https://bun.sh/install | bash -s -- --no-modify-path
  ok "Bun instalado."
}

install_fnm() {
  if command -v fnm >/dev/null; then
    ok "FNM ya instalado."
    return
  fi

  log "Instalando FNM..."
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
  ok "FNM instalado."
}

install_nodejs() {
  install_fnm

  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env)"

  fnm install --lts
  fnm default lts-latest

  ok "Node.js instalado."
}

install_lazygit() {
  install_package_if_missing lazygit
  ok "Lazygit instalado."
}

clean() {
  log "Limpiando caché de paquetes..."
  sudo pacman -Sc --noconfirm 2>/dev/null || true

  local orphans; orphans=$(pacman -Qdtq 2>/dev/null) || true
  if [[ -n "$orphans" ]]; then
    echo "$orphans" | sudo pacman -Rns --noconfirm - 2>/dev/null || true
  fi

  ok "Sistema limpiado."
}

install_all() {
  init_pacman
  install_packages
  install_aur_packages
  install_oh_my_zsh
  apply_config_files
  install_bun
  install_nerd_fonts
  install_yarn
  install_kitty_themes
  install_nodejs
  install_lazygit
  clean

  ok "Instalación completa finalizada."
}

if [[ "$ALL_MODE" == "true" ]]; then
  install_all
  exit 0
fi

PS3="Elegí una opción: "

echo "━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SISTEMA"
echo "━━━━━━━━━━━━━━━━━━━━━━━"

select option in \
  "Instalar TODO completo" \
  "Instalar paquetes base" \
  "Instalar paquetes AUR (android-studio, spotify, vscode)" \
  "Inicializar pacman + AUR helper" \
  "Limpiar sistema" \
  "" \
  "━━━ HERRAMIENTAS ━━━" \
  "Instalar Neovim + config" \
  "Instalar Kitty + config" \
  "Instalar Alacritty + config" \
  "Instalar Ghostty + config" \
  "Instalar WezTerm + config" \
  "Instalar Zsh + config" \
  "Instalar Tmux + config" \
  "" \
  "━━━ DOTFILES ━━━" \
  "Aplicar TODOS los dotfiles (stow)" \
  "Aplicar solo config de shell" \
  "Aplicar solo config de nvim" \
  "Aplicar solo config de kitty" \
  "Aplicar solo config de alacritty" \
  "Aplicar solo config de ghostty" \
  "Aplicar solo config de wezterm" \
  "" \
  "━━━ EXTRAS ━━━" \
  "Instalar Bun" \
  "Instalar Oh My Zsh" \
  "Instalar kitty-themes" \
  "Instalar Node.js (via FNM)" \
  "Instalar Yarn" \
  "Instalar Lazygit" \
  "Instalar Nerd Fonts" \
  "" \
  "━━━ AUR ━━━" \
  "Instalar Spotify" \
  "" \
  "━━━ SALIR ━━━" \
  "Salir"
do
  [[ -z "$REPLY" || "$REPLY" == "0" ]] && continue

  case $option in
    "Instalar TODO completo") install_all ;;
    "Instalar paquetes base") install_packages ;;
    "Instalar paquetes AUR (android-studio, spotify, vscode)") install_aur_packages ;;
    "Inicializar pacman + AUR helper") init_pacman ;;
    "Limpiar sistema") clean ;;

    "Instalar Neovim + config") install_neovim ;;
    "Instalar Kitty + config") install_kitty ;;
    "Instalar Alacritty + config") install_alacritty ;;
    "Instalar Ghostty + config") install_ghostty ;;
    "Instalar WezTerm + config") install_wezterm ;;
    "Instalar Zsh + config") install_zsh ;;
    "Instalar Tmux + config") install_tmux ;;

    "Aplicar TODOS los dotfiles (stow)") apply_config_files ;;
    "Aplicar solo config de shell") stow_single_pkg shell ;;
    "Aplicar solo config de nvim") stow_single_pkg nvim ;;
    "Aplicar solo config de kitty") stow_single_pkg kitty ;;
    "Aplicar solo config de alacritty") stow_single_pkg alacritty ;;
    "Aplicar solo config de ghostty") stow_single_pkg ghostty ;;
    "Aplicar solo config de wezterm") stow_single_pkg wezterm ;;

    "Instalar Bun") install_bun ;;
    "Instalar Oh My Zsh") install_oh_my_zsh ;;
    "Instalar kitty-themes") install_kitty_themes ;;
    "Instalar Node.js (via FNM)") install_nodejs ;;
    "Instalar Yarn") install_yarn ;;
    "Instalar Lazygit") install_lazygit ;;
    "Instalar Nerd Fonts") install_nerd_fonts ;;

    "Instalar Spotify") install_aur_pkg spotify ;;

    "Salir") exit 0 ;;
    *) warn "Opción inválida." ;;
  esac
done
