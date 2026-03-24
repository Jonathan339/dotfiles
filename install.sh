#!/usr/bin/env bash
set -euo pipefail

# ===============================
#  Dotfiles Installer — Fijo menú
#  Fecha: 2025-08-11
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
CONFIG_MODE="${DOTFILES_CONFIG_MODE:-link}" # link (default) | copy

command -v sudo >/dev/null 2>&1 || die "Necesitás sudo instalado."
command -v curl >/dev/null 2>&1 || die "Necesitás curl (sudo apt install curl)."
command -v git >/dev/null 2>&1 || die "Necesitás git (sudo apt install git)."

# ---- Paquetes APT ----
declare -a APT_PACKAGES=(
  libstdc++6 curl wget vlc gnupg2 seahorse git python3-pip cargo libssl-dev
  openjdk-11-jre fzf tmux fonts-powerline kitty xclip zsh ca-certificates
)

package_is_installed() { dpkg -s "$1" &>/dev/null; }
snap_is_installed() { snap list "$1" &>/dev/null; }

install_packages() {
  log "Instalando paquetes necesarios..."
  sudo apt update
  local -a to_install=()
  local pkg
  for pkg in "${APT_PACKAGES[@]}"; do
    if ! package_is_installed "$pkg"; then
      to_install+=("$pkg")
    fi
  done

  if [[ "${#to_install[@]}" -eq 0 ]]; then
    ok "Todos los paquetes APT ya estaban instalados."
    return
  fi

  sudo apt install -y "${to_install[@]}" || die "Fallo instalando paquetes APT."
  ok "Paquetes instalados: ${to_install[*]}"
}

install_package_if_not_installed() {
  local pkg="$1"
  if package_is_installed "$pkg"; then
    ok "$pkg ya está instalado. Saltando..."
  else
    log "$pkg no está instalado. Instalando..."
    sudo apt-get install -y "$pkg" || die "Fallo instalando $pkg."
  fi
}

# ---- Helpers paths ----
check_file_exists() {
  local full_path="$REPO_ROOT/$1"
  log "Verificando archivo: $full_path"
  [[ -f "$full_path" ]] && {
    ok "$1 encontrado"
    return 0
  } || {
    warn "$1 no encontrado"
    return 1
  }
}

check_directory_exists() {
  local full_path="$REPO_ROOT/$1"
  log "Verificando directorio: $full_path"
  [[ -d "$full_path" ]] && {
    ok "$1 encontrado"
    return 0
  } || {
    warn "$1 no encontrado"
    return 1
  }
}

# ---- Enlace/Copia de config ----
link_config_files() {
  log "Creando enlaces simbólicos desde 'config'..."
  local success="true"

  if check_file_exists "config/.zshrc"; then ln -snf "$REPO_ROOT/config/.zshrc" "$HOME/.zshrc" && ok ".zshrc enlazado" || success="false"; fi
  if check_file_exists "config/.zsh_aliases"; then ln -snf "$REPO_ROOT/config/.zsh_aliases" "$HOME/.zsh_aliases" && ok ".zsh_aliases enlazado" || success="false"; fi
  if check_file_exists "config/.bashrc"; then ln -snf "$REPO_ROOT/config/.bashrc" "$HOME/.bashrc" && ok ".bashrc enlazado" || success="false"; fi
  if check_directory_exists "config/nvim"; then
    mkdir -p "$HOME/.config"
    ln -snf "$REPO_ROOT/config/nvim" "$HOME/.config/nvim" && ok "nvim enlazado" || success="false"
  fi
  if check_file_exists "config/kitty.conf"; then
    mkdir -p "$HOME/.config/kitty"
    ln -snf "$REPO_ROOT/config/kitty.conf" "$HOME/.config/kitty/kitty.conf" && ok "kitty.conf enlazado" || success="false"
  fi
  if check_file_exists "config/wezterm.lua"; then
    mkdir -p "$HOME/.config/wezterm"
    ln -snf "$REPO_ROOT/config/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" && ok "wezterm.lua enlazado" || success="false"
  fi

  [[ "$success" = true ]] && ok "Enlaces simbólicos creados" || die "Error creando enlaces simbólicos."
}

copy_config_files() {
  log "Copiando archivos de configuración desde 'config'..."
  local success="true"

  if check_file_exists "config/.zshrc"; then cp -f "$REPO_ROOT/config/.zshrc" "$HOME/" && ok ".zshrc copiado" || success="false"; fi
  if check_file_exists "config/.zsh_aliases"; then cp -f "$REPO_ROOT/config/.zsh_aliases" "$HOME/" && ok ".zsh_aliases copiado" || success="false"; fi
  if check_file_exists "config/.bashrc"; then cp -f "$REPO_ROOT/config/.bashrc" "$HOME/" && ok ".bashrc copiado" || success="false"; fi
  if check_directory_exists "config/nvim"; then
    mkdir -p "$HOME/.config"
    cp -rf "$REPO_ROOT/config/nvim" "$HOME/.config/" && ok "nvim copiado" || success="false"
  fi
  if check_file_exists "config/kitty.conf"; then
    mkdir -p "$HOME/.config/kitty"
    cp -f "$REPO_ROOT/config/kitty.conf" "$HOME/.config/kitty/" && ok "kitty.conf copiado" || success="false"
  fi
  if check_file_exists "config/wezterm.lua"; then
    mkdir -p "$HOME/.config/wezterm"
    cp -f "$REPO_ROOT/config/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" && ok "wezterm.lua copiado" || success="false"
  fi

  [[ "$success" = true ]] && ok "Archivos de configuración copiados" || die "Error copiando configuraciones."
}

apply_config_files() {
  case "$CONFIG_MODE" in
    link)
      log "Modo configuración: enlaces simbólicos (default)."
      link_config_files
      ;;
    copy)
      log "Modo configuración: copia de archivos."
      copy_config_files
      ;;
    *)
      die "DOTFILES_CONFIG_MODE inválido: '$CONFIG_MODE'. Usá 'link' o 'copy'."
      ;;
  esac
}

# ---- Oh My Zsh ----
install_oh_my_zsh() {
  log "Instalando Oh My Zsh..."
  [[ -d "$HOME/.oh-my-zsh" ]] && {
    warn "Existe ~/.oh-my-zsh, se reemplaza"
    rm -rf "$HOME/.oh-my-zsh"
  }
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || die "Fallo instalando Oh My Zsh."
  ok "Oh My Zsh instalado."
}

# ---- Kitty themes ----
install_kitty_themes() {
  log "Instalando kitty-themes..."
  mkdir -p "$HOME/.config/kitty"
  [[ -d "$HOME/.config/kitty/kitty-themes" ]] && {
    warn "Existe kitty-themes, se reemplaza"
    rm -rf "$HOME/.config/kitty/kitty-themes"
  }
  git clone --depth=1 https://github.com/dexpota/kitty-themes.git "$HOME/.config/kitty/kitty-themes" || die "Fallo instalando kitty-themes."
  ok "kitty-themes instalado."
}

# ---- Nerd Fonts ----
install_nerd_fonts() {
  log "Instalando nerd-fonts (DroidSansMono Nerd Font)..."
  local font_path="$HOME/.local/share/fonts/DroidSansMNerdFont-Regular.otf"
  if [[ -f "$font_path" ]]; then
    ok "DroidSansMono Nerd Font ya está instalada. Saltando..."
    return
  fi
  mkdir -p "$HOME/.local/share/fonts"
  pushd "$HOME/.local/share/fonts" >/dev/null
  curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf || die "Fallo descargando la fuente."
  popd >/dev/null
  ok "Nerd Font instalada (si querés: fc-cache -fv)."
}

# ---- Snap helpers/apps ----
ensure_snapd() {
  if ! command -v snap >/dev/null 2>&1; then
    log "Instalando snapd..."
    sudo apt update && sudo apt install -y snapd || die "Fallo instalando snapd."
    ok "snapd instalado."
  fi
}

install_android_studio() {
  ensure_snapd
  if snap_is_installed android-studio; then
    ok "Android Studio ya está instalado. Saltando..."
    return
  fi
  log "Instalando Android Studio (snap)..."
  sudo snap install android-studio --classic || die "Fallo instalando Android Studio."
  ok "Android Studio instalado."
}
install_spotify() {
  ensure_snapd
  if snap_is_installed spotify; then
    ok "Spotify ya está instalado. Saltando..."
    return
  fi
  log "Instalando Spotify (snap)..."
  sudo snap install spotify || die "Fallo instalando Spotify."
  ok "Spotify instalado."
}
install_vscode() {
  ensure_snapd
  if snap_is_installed code; then
    ok "VS Code ya está instalado. Saltando..."
    return
  fi
  log "Instalando VS Code (snap)..."
  sudo snap install code --classic || die "Fallo instalando VS Code."
  ok "VS Code instalado."
}
install_nvim() {
  ensure_snapd
  if snap_is_installed nvim; then
    ok "Neovim (snap) ya está instalado. Saltando..."
    return
  fi
  log "Instalando Neovim (snap beta)..."
  sudo snap install nvim --beta --classic || die "Fallo instalando Neovim."
  ok "Neovim instalado."
}

# ---- Yarn (keyring) ----
install_yarn() {
  if command -v yarn >/dev/null 2>&1; then
    ok "Yarn ya está instalado. Saltando..."
    return
  fi
  log "Instalando Yarn (repo con keyring)..."
  sudo mkdir -p /usr/share/keyrings
  curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarn-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null
  sudo apt update
  sudo apt install -y yarn || die "Fallo instalando Yarn."
  ok "Yarn instalado."
}

# ---- Bun ----
install_bun() {
  if command -v bun >/dev/null 2>&1; then
    ok "Bun ya está instalado. Saltando..."
    return
  fi
  log "Instalando Bun..."
  curl -fsSL https://bun.sh/install | bash || die "Fallo instalando Bun."
  ok "Bun instalado."
}

# ---- Node.js (FNM recomendado) ----
install_fnm() {
  if command -v fnm >/dev/null 2>&1; then
    ok "FNM ya está instalado. Saltando..."
    return
  fi
  log "Instalando FNM (Node manager)..."
  curl -fsSL https://fnm.vercel.app/install | bash || die "Fallo instalando FNM."
  # corregido comillas
  grep -q 'fnm env' "$HOME/.zshrc" 2>/dev/null || echo 'eval "$(fnm env --use-on-cd)"' >>"$HOME/.zshrc"
  ok "FNM instalado. Abrí una nueva terminal para tener fnm en PATH."
}

install_nodejs_with_fnm() {
  export FNM_DIR="$HOME/.local/share/fnm"
  export PATH="$HOME/.fnm:$FNM_DIR:$PATH"
  if command -v fnm >/dev/null 2>&1; then
    log "Instalando Node.js LTS con FNM..."
    fnm install --lts && fnm default lts-latest
    ok "Node.js LTS instalado con FNM."
  else
    warn "FNM no está disponible en esta shell. Abrí una nueva terminal (o source ~/.zshrc) y corré de nuevo esta opción."
  fi
}

install_nodejs() {
  install_fnm
  install_nodejs_with_fnm
}

# ---- Lazygit ----
install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    ok "lazygit ya está instalado. Saltando..."
    return
  fi
  log "Instalando lazygit..."
  ARCH="x86_64"
  [[ "$(uname -m)" == "aarch64" ]] && ARCH="arm64"
  LAZYGIT_VERSION="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po '"tag_name": "v\K[^"]*' || true)"
  [[ -z "$LAZYGIT_VERSION" ]] && die "No pude obtener la versión de lazygit."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  pushd "$tmp_dir" >/dev/null
  curl -fsSLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${ARCH}.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  popd >/dev/null
  rm -rf "$tmp_dir"
  ok "lazygit instalado."
}

# ---- Limpieza ----
clean() {
  log "Limpieza..."
  sudo apt autoremove -y
  sudo apt full-upgrade -y
  ok "Limpieza completa."
}

# ---- Instalación completa ----
install_all() {
  install_packages
  install_oh_my_zsh
  apply_config_files
  install_bun
  install_android_studio
  install_spotify
  install_vscode
  install_nvim
  install_nerd_fonts
  install_yarn
  install_kitty_themes
  install_nodejs
  install_lazygit
  clean
  ok "Todo listo. Abrí una nueva terminal para aplicar cambios de PATH."
}

# ---- CLI rápida opcional ----
if [[ "${1:-}" == "--all" ]]; then
  if [[ "${2:-}" == "--copy" ]]; then
    CONFIG_MODE="copy"
  else
    CONFIG_MODE="link"
  fi
  install_all
  exit 0
fi

# ---- Menú (coincide por número con $REPLY) ----
PS3="Elegí una opción: "
select opcion in \
  "Instalar todo" \
  "Instalar paquetes" \
  "Enlazar archivos de configuración" \
  "Copiar archivos de configuración" \
  "Instalar Bun" \
  "Instalar Oh My Zsh" \
  "Instalar kitty-themes" \
  "Instalar Android Studio" \
  "Instalar Spotify" \
  "Instalar Visual Studio Code" \
  "Instalar nvim" \
  "Instalar Node.js" \
  "Instalar Yarn" \
  "Instalar lazygit" \
  "Limpiar" \
  "Salir"; do
  case "$REPLY" in
    1) install_all ;;
    2) install_packages ;;
    3) link_config_files ;;
    4) copy_config_files ;;
    5) install_bun ;;
    6) install_oh_my_zsh ;;
    7) install_kitty_themes ;;
    8) install_android_studio ;;
    9) install_spotify ;;
    10) install_vscode ;;
    11) install_nvim ;;
    12) install_nodejs ;;
    13) install_yarn ;;
    14) install_lazygit ;;
    15) clean ;;
    16) exit 0 ;;
    *) echo "Opción inválida." ;;
  esac
done
