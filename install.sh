#!/usr/bin/env bash
set -euo pipefail

# ===============================
# Dotfiles Installer
# ===============================

INFO="\e[34m[INFO]\e[0m"
OK="\e[32m[OK]\e[0m"
WARN="\e[33m[WARN]\e[0m"
ERR="\e[31m[ERR]\e[0m"

log() { echo -e "$INFO $*"; }
ok() { echo -e "$OK $*"; }
warn() { echo -e "$WARN $*"; }
die() { echo -e "$ERR $*"; exit 1; }

trap 'echo -e "\n${ERR} Ocurrió un error."' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
CONFIG_MODE="${DOTFILES_CONFIG_MODE:-stow}"
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

APT_PACKAGES=(
  libstdc++6 curl wget vlc gnupg2 seahorse git python3-pip cargo
  libssl-dev openjdk-21-jre fzf tmux fonts-powerline kitty
  xclip zsh ca-certificates ripgrep loupe rofi
)

package_is_installed() {
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "^$1 .* install ok installed"
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

# --- Config via stow ---

apply_stow() {
  log "Aplicando dotfiles con GNU Stow..."
  "$REPO_ROOT/link.sh" --fix
}

# --- Config via copy ---

apply_copy() {
  log "Copiando dotfiles a $HOME..."

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

apply_config_files() {
  case "$CONFIG_MODE" in
    stow) apply_stow ;;
    copy) apply_copy ;;
    *) die "Modo inválido. Usá 'stow' o 'copy'." ;;
  esac
}

# --- Herramientas ---

install_oh_my_zsh() {
  [[ -d "$HOME/.oh-my-zsh" ]] && { warn "Oh My Zsh ya existe."; return; }
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  ok "Oh My Zsh instalado."
}

install_kitty_themes() {
  local themes_dir="$HOME/.config/kitty/kitty-themes"

  [[ -d "$themes_dir" ]] && { warn "kitty-themes ya existe."; return; }

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

ensure_snapd() {
  command -v snap >/dev/null || sudo apt install -y snapd
}

install_snap_app() {
  local name="$1"
  shift
  local flags=("$@")

  ensure_snapd
  snap_is_installed "$name" && return

  sudo snap install "$name" "${flags[@]}" || warn "Falló snap: $name"
}

install_neovim() {
  install_snap_app nvim --beta --classic
  ok "Neovim instalado."
}

install_opencode() {
  command -v opencode >/dev/null && return
  log "Instalando OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  ok "OpenCode instalado."
}

install_kitty() {
  install_package_if_missing kitty
  ok "Kitty instalado."
}

install_alacritty() {
  install_package_if_missing alacritty
  ok "Alacritty instalado."
}

install_ghostty() {
  ok "Config de Ghostty aplicada (instalalo manualmente)."
}

install_wezterm() {
  ok "Config de WezTerm aplicada (instalalo manualmente)."
}

install_zsh() {
  install_package_if_missing zsh
  install_oh_my_zsh
  ok "Zsh instalado."
}

install_tmux() {
  install_package_if_missing tmux
  ok "Tmux instalado."
}

install_rofi() {
  install_package_if_missing rofi
  ok "Rofi instalado."
}

install_spotify_snap() {
  install_snap_app spotify
  ok "Spotify instalado."
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

  local arch
  case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) die "Arquitectura no soportada: $(uname -m)" ;;
  esac

  local bun_dir="$HOME/.bun"
  local bin_dir="$bun_dir/bin"

  mkdir -p "$bin_dir"

  curl -fsLo /tmp/bun.zip \
    "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${arch}.zip"

  unzip -oq /tmp/bun.zip -d /tmp/bun-extract
  mv /tmp/bun-extract/bun-linux-${arch}/bun "$bin_dir/bun"
  chmod +x "$bin_dir/bun"

  rm -rf /tmp/bun.zip /tmp/bun-extract

  ok "Bun instalado en $bin_dir/bun"
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
  sudo apt clean
  ok "Sistema limpiado."
}

# --- Instalación completa ---

install_all() {
  install_packages
  install_oh_my_zsh
  apply_config_files
  install_bun
  install_snap_app android-studio --classic
  install_snap_app spotify
  install_snap_app code --classic
  install_neovim
  install_opencode
  install_nerd_fonts
  install_yarn
  install_kitty_themes
  install_rofi
  install_nodejs
  install_lazygit
  clean

  log "Re-aplicando stow con todos los programas instalados..."
  "$REPO_ROOT/link.sh" --fix

  log "Validando symlinks finales..."
  "$REPO_ROOT/check.sh" || true

  ok "Instalación completa finalizada."
}

if [[ "$ALL_MODE" == "true" ]]; then
  install_all
  exit 0
fi

# --- Menú interactivo ---

PS3="Elegí una opción: "

echo "━━━━━━━━━━━━━━━━━━━━━━━"
echo "  SISTEMA"
echo "━━━━━━━━━━━━━━━━━━━━━━━"

select option in \
  "Instalar TODO completo" \
  "Instalar paquetes base" \
  "Instalar aplicaciones Snap (android-studio, spotify, vscode)" \
  "Limpiar sistema" \
  "Aplicar/validar symlinks" \
  "" \
  "━━━ HERRAMIENTAS ━━━" \
  "Instalar Neovim (snap)" \
  "Instalar OpenCode" \
  "Instalar Kitty" \
  "Instalar Alacritty" \
  "Instalar Zsh + Oh My Zsh" \
  "Instalar Tmux" \
  "Instalar Rofi" \
  "" \
  "━━━ DOTFILES ━━━" \
  "Aplicar TODOS los dotfiles" \
  "Aplicar solo config de shell" \
  "Aplicar solo config de nvim" \
  "Aplicar solo config de kitty" \
  "Aplicar solo config de alacritty" \
  "Aplicar solo config de ghostty" \
  "Aplicar solo config de wezterm" \
  "Aplicar solo config de rofi" \
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
  "━━━ SNAP ━━━" \
  "Instalar Spotify (snap)" \
  "" \
  "━━━ SALIR ━━━" \
  "Salir"
do
  [[ -z "$REPLY" || "$REPLY" == "0" ]] && continue

  case $option in
    "Instalar TODO completo") install_all ;;
    "Instalar paquetes base") install_packages ;;
    "Instalar aplicaciones Snap (android-studio, spotify, vscode)")
      install_snap_app android-studio --classic
      install_snap_app spotify
      install_snap_app code --classic
      ok "Apps Snap instaladas."
      ;;
    "Limpiar sistema") clean ;;
    "Aplicar/validar symlinks") "$REPO_ROOT/link.sh" --fix ;;

    "Instalar Neovim (snap)") install_neovim ;;
    "Instalar OpenCode") install_opencode ;;
    "Instalar Kitty") install_kitty ;;
    "Instalar Alacritty") install_alacritty ;;
    "Instalar Zsh + Oh My Zsh") install_zsh ;;
    "Instalar Tmux") install_tmux ;;
    "Instalar Rofi") install_rofi ;;

    "Aplicar TODOS los dotfiles") apply_config_files ;;
    "Aplicar solo config de shell") "$REPO_ROOT/link.sh" shell ;;
    "Aplicar solo config de nvim") "$REPO_ROOT/link.sh" nvim ;;
    "Aplicar solo config de kitty") "$REPO_ROOT/link.sh" kitty ;;
    "Aplicar solo config de alacritty") "$REPO_ROOT/link.sh" alacritty ;;
    "Aplicar solo config de ghostty") "$REPO_ROOT/link.sh" ghostty ;;
    "Aplicar solo config de wezterm") "$REPO_ROOT/link.sh" wezterm ;;
    "Aplicar solo config de rofi") "$REPO_ROOT/link.sh" rofi ;;

    "Instalar Bun") install_bun ;;
    "Instalar Oh My Zsh") install_oh_my_zsh ;;
    "Instalar kitty-themes") install_kitty_themes ;;
    "Instalar Node.js (via FNM)") install_nodejs ;;
    "Instalar Yarn") install_yarn ;;
    "Instalar Lazygit") install_lazygit ;;
    "Instalar Nerd Fonts") install_nerd_fonts ;;

    "Instalar Spotify (snap)") install_spotify_snap ;;

    "Salir") exit 0 ;;
    *) warn "Opción inválida." ;;
  esac
done
