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

APT_PACKAGES=(
  libstdc++6 curl wget vlc gnupg2 seahorse git python3-pip cargo
  libssl-dev openjdk-21-jre fzf tmux fonts-powerline kitty
  xclip zsh ca-certificates ripgrep
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
    "$HOME/.config/rofi"
    "$HOME/.config/i3"
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

  for pkg in shell nvim kitty alacritty ghostty wezterm rofi i3; do
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
  mkdir -p "$HOME/.config/rofi/themes"
  mkdir -p "$HOME/.config/i3"

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
  cp -rf "$config_dir/rofi/." "$HOME/.config/rofi/"
  cp -f "$config_dir/i3/config" "$HOME/.config/i3/config"

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

install_neovim() {
  install_snap_app nvim --beta --classic
  stow_single_pkg nvim
  ok "Neovim instalado + config aplicada."
}

install_opencode() {
  command -v opencode >/dev/null && return

  log "Instalando OpenCode..."
  curl -fsSL https://opencode.ai/install | bash
  ok "OpenCode instalado."
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
  stow_single_pkg ghostty
  ok "Config de Ghostty aplicada (instalalo manualmente)."
}

install_wezterm() {
  stow_single_pkg wezterm
  ok "Config de WezTerm aplicada (instalalo manualmente)."
}

install_rofi() {
  install_package_if_missing rofi
  stow_single_pkg rofi
  ok "Rofi instalado + config aplicada."
}

install_i3() {
  stow_single_pkg i3
  ok "Config de i3 aplicada."
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
  sudo apt clean
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
  install_neovim
  install_opencode
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
  "Instalar aplicaciones Snap (android-studio, spotify, vscode)" \
  "Limpiar sistema" \
  "" \
  "━━━ HERRAMIENTAS ━━━" \
  "Instalar Neovim (snap) + config" \
  "Instalar OpenCode" \
  "Instalar Kitty + config" \
  "Instalar Alacritty + config" \
  "Aplicar config de Ghostty (instalar manual)" \
  "Aplicar config de WezTerm (instalar manual)" \
  "Instalar Rofi + config" \
  "Aplicar config de i3" \
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
  "Aplicar solo config de rofi" \
  "Aplicar solo config de i3" \
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

    "Instalar Neovim (snap) + config") install_neovim ;;
    "Instalar OpenCode") install_opencode ;;
    "Instalar Kitty + config") install_kitty ;;
    "Instalar Alacritty + config") install_alacritty ;;
    "Aplicar config de Ghostty (instalar manual)") install_ghostty ;;
    "Aplicar config de WezTerm (instalar manual)") install_wezterm ;;
    "Instalar Rofi + config") install_rofi ;;
    "Aplicar config de i3") install_i3 ;;
    "Instalar Zsh + config") install_zsh ;;
    "Instalar Tmux + config") install_tmux ;;

    "Aplicar TODOS los dotfiles (stow)") apply_config_files ;;
    "Aplicar solo config de shell") stow_single_pkg shell ;;
    "Aplicar solo config de nvim") stow_single_pkg nvim ;;
    "Aplicar solo config de kitty") stow_single_pkg kitty ;;
    "Aplicar solo config de alacritty") stow_single_pkg alacritty ;;
    "Aplicar solo config de ghostty") stow_single_pkg ghostty ;;
    "Aplicar solo config de wezterm") stow_single_pkg wezterm ;;
    "Aplicar solo config de rofi") stow_single_pkg rofi ;;
    "Aplicar solo config de i3") stow_single_pkg i3 ;;

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
