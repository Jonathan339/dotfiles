#!/usr/bin/env bash
set -euo pipefail

# ===============================
# Dotfiles Installer Optimizado
# Fecha: 2026-04-12
# ===============================

INFO="\e[34m[INFO]\e[0m"
OK="\e[32m[OK]\e[0m"
WARN="\e[33m[WARN]\e[0m"
ERR="\e[31m[ERROR]\e[0m"

log() { echo -e "$INFO $*"; }
ok() { echo -e "$OK  $*"; }
warn() { echo -e "$WARN $*"; }
die() {
  echo -e "$ERR $*" >&2
  exit 1
}

trap 'echo -e "\n'"$ERR"' Ocurrió un error. Revisá el mensaje anterior."' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
CONFIG_MODE="${DOTFILES_CONFIG_MODE:-stow}"

command -v sudo >/dev/null || die "Necesitás sudo."
command -v curl >/dev/null || die "Necesitás curl."
command -v git >/dev/null || die "Necesitás git."

# ===============================
# PAQUETES
# ===============================

declare -a APT_PACKAGES=(
  libstdc++6 curl wget vlc gnupg2 seahorse git python3-pip cargo
  libssl-dev openjdk-11-jre fzf tmux fonts-powerline kitty
  xclip zsh ca-certificates
)

package_is_installed() {
  dpkg -s "$1" &>/dev/null
}

snap_is_installed() {
  snap list "$1" &>/dev/null
}

install_packages() {
  log "Instalando paquetes necesarios..."
  sudo apt update

  local -a missing=()

  for pkg in "${APT_PACKAGES[@]}"; do
    package_is_installed "$pkg" || missing+=("$pkg")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    ok "Todos los paquetes ya estaban instalados."
    return
  fi

  sudo apt install -y "${missing[@]}"
  ok "Paquetes instalados."
}

install_package_if_missing() {
  local pkg="$1"

  if package_is_installed "$pkg"; then
    ok "$pkg ya instalado."
    return
  fi

  sudo apt install -y "$pkg"
}

# ===============================
# LIMPIEZA SYMLINKS
# ===============================

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
      warn "Eliminando symlink: $file"
      rm "$file"
    fi
  done
}

# ===============================
# GNU STOW
# ===============================

stow_config_files() {
  log "Aplicando dotfiles con GNU Stow..."

  install_package_if_missing stow
  cleanup_conflicting_symlinks

  local stow_dir="$REPO_ROOT/stow"
  local -a packages=(shell nvim kitty alacritty wezterm)

  [[ -d "$stow_dir" ]] || die "No existe: $stow_dir"

  for pkg in "${packages[@]}"; do
    [[ -d "$stow_dir/$pkg" ]] || continue

    log "Aplicando paquete: $pkg"

    stow \
      --adopt \
      --restow \
      --dir "$stow_dir" \
      --target "$HOME" \
      "$pkg"

    ok "Paquete aplicado: $pkg"
  done

  ok "Dotfiles aplicados correctamente."
}

apply_config_files() {
  case "$CONFIG_MODE" in
    stow) stow_config_files ;;
    *) die "Modo inválido." ;;
  esac
}

# ===============================
# OH MY ZSH
# ===============================

install_oh_my_zsh() {
  log "Instalando Oh My Zsh..."

  rm -rf "$HOME/.oh-my-zsh"

  git clone --depth=1 \
    https://github.com/ohmyzsh/ohmyzsh.git \
    "$HOME/.oh-my-zsh"

  ok "Oh My Zsh instalado."
}

# ===============================
# KITTY THEMES
# ===============================

install_kitty_themes() {
  mkdir -p "$HOME/.config/kitty"

  rm -rf "$HOME/.config/kitty/kitty-themes"

  git clone --depth=1 \
    https://github.com/dexpota/kitty-themes.git \
    "$HOME/.config/kitty/kitty-themes"

  ok "kitty-themes instalado."
}

# ===============================
# NERD FONT
# ===============================

install_nerd_fonts() {
  local font="$HOME/.local/share/fonts/DroidSansMNerdFont-Regular.otf"

  [[ -f "$font" ]] && return

  mkdir -p "$HOME/.local/share/fonts"

  curl -fLo "$font" \
    https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf

  ok "Nerd Font instalada."
}

# ===============================
# SNAP
# ===============================

ensure_snapd() {
  command -v snap >/dev/null || sudo apt install -y snapd
}

install_snap_app() {
  local name="$1"
  local flag="${2:-}"

  ensure_snapd

  if snap_is_installed "$name"; then
    ok "$name ya instalado."
    return
  fi

  sudo snap install "$name" $flag
}

# ===============================
# YARN
# ===============================

install_yarn() {
  command -v yarn >/dev/null && return

  curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg |
    sudo gpg --dearmor -o /usr/share/keyrings/yarn.gpg

  echo \
    "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian stable main" |
    sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null

  sudo apt update
  sudo apt install -y yarn
}

# ===============================
# BUN
# ===============================

install_bun() {
  command -v bun >/dev/null && return

  curl -fsSL https://bun.sh/install | bash
}

# ===============================
# FNM / NODE
# ===============================

install_fnm() {
  if command -v fnm >/dev/null; then
    ok "FNM ya instalado."
    return
  fi

  log "Instalando FNM..."

  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell

  touch "$HOME/.zshrc"

  grep -q 'fnm env' "$HOME/.zshrc" || cat <<EOF >> "$HOME/.zshrc"

export FNM_PATH="\$HOME/.local/share/fnm"
if [ -d "\$FNM_PATH" ]; then
  export PATH="\$FNM_PATH:\$PATH"
  eval "\$(fnm env --use-on-cd)"
fi
EOF

  ok "FNM instalado."
}

install_nodejs() {
  install_fnm

  export PATH="$HOME/.local/share/fnm:$PATH"

  source "$HOME/.zshrc" || true

  fnm install --lts
  fnm default lts-latest

  ok "Node.js instalado."
}

# ===============================
# LAZYGIT
# ===============================

install_lazygit() {
  command -v lazygit >/dev/null && return

  local version
  version=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest |
    grep -Po '"tag_name": "v\K[^"]*')

  curl -Lo lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"

  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin

  rm -f lazygit lazygit.tar.gz
}

# ===============================
# LIMPIEZA
# ===============================

clean() {
  sudo apt autoremove -y
  sudo apt full-upgrade -y
}

# ===============================
# INSTALL ALL
# ===============================

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

# ===============================
# MENU
# ===============================

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
