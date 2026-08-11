#!/usr/bin/env bash
set -euo pipefail

# ===============================
# Dotfiles Installer Optimizado
# Fecha: 2026-04-12
# ===============================

INFO="\e[34m[INFO]\e[0m"
OK="\e[32m[OK]\e[0m"
WARN="\e[33m[WARN]\e[0m"
ERR="\e[31m[ERR]\e[0m"

log() { echo -e "$INFO $*"; }
ok() { echo -e "$OK $*"; }
warn() { echo -e "$WARN $*"; }
die() { echo -e "$ERR $*"; exit 1; }

trap 'echo -e "\n${ERR} Ocurrió un error. Revisá el mensaje anterior."' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
CONFIG_MODE="${DOTFILES_CONFIG_MODE:-stow}"
STOW_ADOPT="${DOTFILES_STOW_ADOPT:-false}"

command -v sudo >/dev/null || die "Necesitás sudo."
command -v curl >/dev/null || die "Necesitás curl."
command -v git >/dev/null || die "Necesitás git."

APT_PACKAGES=(
  libstdc++6 curl wget vlc gnupg2 seahorse git python3-pip cargo
  libssl-dev openjdk-11-jre fzf tmux fonts-powerline kitty
  xclip zsh ca-certificates ripgrep
)

package_is_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

snap_is_installed() { snap list "$1" &>/dev/null; }

install_packages() {
  log "Instalando paquetes necesarios..."
  sudo apt update

  sudo apt install -y "${APT_PACKAGES[@]}"

  ok "Paquetes instalados."
}

install_package_if_missing() {
  package_is_installed "$1" && return
  sudo apt install -y "$1"
}

cleanup_conflicting_symlinks() {
  log "Limpiando symlinks conflictivos..."

  local files=(
    "$HOME/.bashrc"
    "$HOME/.zshrc"
    "$HOME/.config/nvim"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/alacritty/alacritty.toml"
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

stow_config_files() {
  log "Aplicando dotfiles con GNU Stow..."

  install_package_if_missing stow
  cleanup_conflicting_symlinks

  local stow_dir="$REPO_ROOT/stow"
  local packages=(shell nvim kitty alacritty wezterm)

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

apply_config_files() {
  case "$CONFIG_MODE" in
    stow) stow_config_files ;;
    *) die "Modo inválido." ;;
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
  mkdir -p "$HOME/.config/kitty"
  rm -rf "$HOME/.config/kitty/kitty-themes"

  git clone --depth=1 \
    https://github.com/dexpota/kitty-themes.git \
    "$HOME/.config/kitty/kitty-themes"

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

ensure_snapd() {
  command -v snap >/dev/null || sudo apt install -y snapd
}

install_snap_app() {
  local name="$1"
  local flag="${2:-}"

  ensure_snapd

  snap_is_installed "$name" && return

  sudo snap install "$name" $flag || warn "Falló snap: $name"
}

install_yarn() {
  command -v yarn >/dev/null && return

  curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg |
    sudo gpg --dearmor -o /usr/share/keyrings/yarn.gpg

  echo \
    "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main" |
    sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null

  sudo apt update
  sudo apt install -y yarn

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
  command -v lazygit >/dev/null && return

  local arch
  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) die "Arquitectura no soportada: $(uname -m)" ;;
  esac

  local version
  version=$(
    curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest |
      grep -Po '"tag_name": "v\K[^"]*'
  )

  [[ -n "$version" ]] || die "No se pudo obtener versión de Lazygit"

  curl -Lo lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_${arch}.tar.gz"

  tar xf lazygit.tar.gz lazygit

  sudo install -m 755 lazygit /usr/local/bin/lazygit

  rm -f lazygit lazygit.tar.gz

  ok "Lazygit instalado."
}

clean() {
  sudo apt autoremove -y
  sudo apt upgrade -y
  ok "Sistema limpiado."
}

install_all() {
  install_packages
  install_oh_my_zsh
  apply_config_files
  install_bun
  install_snap_app android-studio --classic
  install_snap_app spotify
  install_snap_app code --classic
  install_snap_app nvim --beta --classic
  install_nerd_fonts
  install_yarn
  install_kitty_themes
  install_nodejs
  install_lazygit
  clean

  ok "Instalación completa finalizada."
}

PS3="Elegí una opción: "

select option in \
  "Instalar todo" \
  "Instalar paquetes" \
  "Aplicar dotfiles" \
  "Instalar Bun" \
  "Instalar Oh My Zsh" \
  "Instalar kitty-themes" \
  "Instalar Android Studio" \
  "Instalar Spotify" \
  "Instalar VSCode" \
  "Instalar Nvim" \
  "Instalar Node.js" \
  "Instalar Yarn" \
  "Instalar Lazygit" \
  "Limpiar" \
  "Salir"
do
  case $REPLY in
    1) install_all ;;
    2) install_packages ;;
    3) apply_config_files ;;
    4) install_bun ;;
    5) install_oh_my_zsh ;;
    6) install_kitty_themes ;;
    7) install_snap_app android-studio --classic ;;
    8) install_snap_app spotify ;;
    9) install_snap_app code --classic ;;
    10) install_snap_app nvim --beta --classic ;;
    11) install_nodejs ;;
    12) install_yarn ;;
    13) install_lazygit ;;
    14) clean ;;
    15) exit 0 ;;
    *) warn "Opción inválida." ;;
  esac
done
