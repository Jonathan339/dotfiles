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
  xclip zsh ca-certificates ripgrep stow
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

install_package_if_missing() {
  package_is_installed "$1" && return
  sudo pacman -S --noconfirm "$1"
}

cleanup_conflicting_symlinks() {
  log "Limpiando symlinks conflictivos..."

  local files=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.gitconfig"
    "$HOME/.tmux.conf"
    "$HOME/.config/nvim"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/kitty/colors/kitty-colors.conf"
    "$HOME/.config/alacritty/alacritty.toml"
    "$HOME/.config/alacritty/colors/alacritty-colors.toml"
    "$HOME/.config/ghostty/config"
    "$HOME/.config/ghostty/colors/ghostty-colors"
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

stow_config_files() {
  log "Aplicando dotfiles con GNU Stow..."

  install_package_if_missing stow
  cleanup_conflicting_symlinks

  local stow_dir="$REPO_ROOT/stow"
  local packages=(shell nvim terminal)

  [[ -d "$stow_dir" ]] || die "No existe: $stow_dir"

  for pkg in "${packages[@]}"; do
    [[ -d "$stow_dir/$pkg" ]] || continue

    if [[ "$STOW_ADOPT" == "true" ]]; then
      stow --adopt --restow --dir "$stow_dir" --target "$HOME" "$pkg"
    else
      stow --restow --dir "$stow_dir" --target "$HOME" "$pkg"
    fi

    ok "Paquete aplicado: $pkg"
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

  for f in .zshrc .zsh_aliases .bashrc .tmux.conf .gitconfig; do
    [[ -f "$config_dir/$f" ]] && cp -f "$config_dir/$f" "$HOME/$f"
  done

  cp -rf "$config_dir/nvim/." "$HOME/.config/nvim/"
  cp -f "$config_dir/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  cp -f "$config_dir/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  cp -f "$config_dir/colors/kitty-colors.conf" "$HOME/.config/kitty/colors/kitty-colors.conf"
  cp -f "$config_dir/colors/alacritty-colors.toml" "$HOME/.config/alacritty/colors/alacritty-colors.toml"
  cp -f "$REPO_ROOT/stow/terminal/.config/ghostty/config" "$HOME/.config/ghostty/config"
  cp -f "$REPO_ROOT/stow/terminal/.config/ghostty/colors/ghostty-colors" "$HOME/.config/ghostty/colors/ghostty-colors"

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

select option in \
  "Instalar todo" \
  "Instalar paquetes base" \
  "Instalar paquetes AUR (android-studio, spotify, vscode)" \
  "Aplicar dotfiles" \
  "Inicializar pacman + AUR helper" \
  "Instalar Bun" \
  "Instalar Oh My Zsh" \
  "Instalar kitty-themes" \
  "Instalar Node.js (via FNM)" \
  "Instalar Yarn" \
  "Instalar Lazygit" \
  "Instalar Nerd Fonts" \
  "Limpiar" \
  "Salir"
do
  case $REPLY in
    1) install_all ;;
    2) install_packages ;;
    3) install_aur_packages ;;
    4) apply_config_files ;;
    5) init_pacman ;;
    6) install_bun ;;
    7) install_oh_my_zsh ;;
    8) install_kitty_themes ;;
    9) install_nodejs ;;
    10) install_yarn ;;
    11) install_lazygit ;;
    12) install_nerd_fonts ;;
    13) clean ;;
    14) exit 0 ;;
    *) warn "Opción inválida." ;;
  esac
done
