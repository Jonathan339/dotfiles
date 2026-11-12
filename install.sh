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
CONFIG_ONLY=false
DRY_RUN=false
ONLY_TAGS=""
LIST_MODE=false
UI_MODE="${DOTFILES_UI:-auto}"

# Colores de la paleta compartida (fallback si el archivo no existe)
PALETTE_FILE="$REPO_ROOT/config/colors/palette.sh"
MENU_ACCENT="#8f45e3"
MENU_BG="#252525"
MENU_FG="#ffffff"
MENU_PINK="#f485ed"
MENU_COLOR3="#c47be8"
MENU_COLOR7="#fab1ed"
if [[ -f "$PALETTE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$PALETTE_FILE"
  MENU_ACCENT="${PALETTE_ACCENT:-$MENU_ACCENT}"
  MENU_BG="${PALETTE_BG:-$MENU_BG}"
  MENU_FG="${PALETTE_FG:-$MENU_FG}"
  MENU_PINK="${PALETTE_COLOR5:-$MENU_PINK}"
  MENU_COLOR3="${PALETTE_COLOR3:-$MENU_COLOR3}"
  MENU_COLOR7="${PALETTE_COLOR7:-$MENU_COLOR7}"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL_MODE=true; shift ;;
    --copy) CONFIG_MODE="copy"; shift ;;
    --config-only) CONFIG_ONLY=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --only) ONLY_TAGS="${2:-}"; shift 2 ;;
    --only=*) ONLY_TAGS="${1#*=}"; shift ;;
    --ui) UI_MODE="${2:-auto}"; shift 2 ;;
    --ui=*) UI_MODE="${1#*=}"; shift ;;
    --list) LIST_MODE=true; shift ;;
    *) shift ;;
  esac
done

command -v sudo >/dev/null || die "Necesitás sudo."
command -v curl >/dev/null || die "Necesitás curl."
command -v git >/dev/null || die "Necesitás git."

# ==============================================================================
# Detección del gestor de paquetes (apt en Debian/Ubuntu, pacman en Arch)
# ==============================================================================
detect_pm() {
  if command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "unknown"
  fi
}
PM="$(detect_pm)"
OS_ID=""
[[ -r /etc/os-release ]] && . /etc/os-release
OS_ID="${ID:-unknown}"

warn_pm() { warn "Función pensada para apt; no soportada con $PM en $OS_ID. Saltando."; }

APT_PACKAGES=(
  libstdc++6 curl wget vlc gnupg2 seahorse git python3-pip cargo
  libssl-dev openjdk-21-jre fzf tmux fonts-powerline kitty
  xclip zsh ca-certificates ripgrep loupe rofi
  hyprland waybar dunst swaybg hypridle grim slurp wl-clipboard
  cliphist brightnessctl stow shellcheck
)

PACMAN_PACKAGES=(
  curl wget vlc gnupg seahorse git python-pip rust
  openssl jre-openjdk fzf tmux powerline-fonts kitty
  xclip zsh ca-certificates ripgrep loupe rofi
  hyprland waybar dunst swaybg hypridle grim slurp wl-clipboard
  cliphist brightnessctl stow
  neovim ttf-hack-nerd tree-sitter-cli shellcheck
  keyd
)

package_is_installed() {
  case "$PM" in
    apt)
      dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "^$1 .* install ok installed"
      ;;
    pacman)
      pacman -Q "$1" &>/dev/null
      ;;
    *) return 1 ;;
  esac
}

snap_is_installed() { snap list "$1" &>/dev/null; }

# Instala desde AUR usando paru/yay si están disponibles. Devuelve 1 si no hay helper.
install_aur_app() {
  local helper=""
  command -v paru &>/dev/null && helper="paru"
  [[ -z "$helper" ]] && command -v yay &>/dev/null && helper="yay"
  [[ -z "$helper" ]] && return 1

  log "Instalando $1 desde AUR con $helper..."
  "$helper" -S --needed --noconfirm "$1"
}

install_packages() {
  log "Instalando paquetes necesarios..."
  case "$PM" in
    apt)
      sudo apt update
      sudo apt install -y "${APT_PACKAGES[@]}"
      ;;
    pacman)
      # -Syu para evitar partial upgrades (regla de oro de Arch)
      sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES[@]}"
      ;;
    *) die "Gestor de paquetes no soportado: $PM" ;;
  esac
  ok "Paquetes instalados."
}

install_package_if_missing() {
  package_is_installed "$1" && return
  case "$PM" in
    apt) sudo apt install -y "$1" ;;
    pacman) sudo pacman -S --noconfirm --needed "$1" ;;
  esac
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
  [[ "$PM" == "apt" ]] || { warn_pm; return 1; }
  command -v snap >/dev/null || sudo apt install -y snapd
}

install_snap_app() {
  local name="$1"
  shift
  local flags=("$@")

  # En Arch: VS Code está en repos oficiales; el resto solo por AUR con helper
  if [[ "$PM" == "pacman" ]]; then
    if [[ "$name" == "code" ]]; then
      install_package_if_missing code
    elif install_aur_app "$name"; then
      ok "$name instalado desde AUR."
    else
      warn "'$name': no instalado (sin helper AUR o falló). En Arch: paru/yay -S $name"
    fi
    return
  fi

  [[ "$PM" == "apt" ]] || { warn_pm; return; }

  ensure_snapd
  snap_is_installed "$name" && return

  sudo snap install "$name" "${flags[@]}" || warn "Falló snap: $name"
}

install_neovim() {
  case "$PM" in
    apt)
      install_snap_app nvim --beta --classic
      ;;
    pacman)
      install_package_if_missing neovim
      ;;
    *)
      warn "Neovim: instalalo manualmente."
      return
      ;;
  esac
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
  if install_package_if_missing ghostty 2>/dev/null; then
    ok "Ghostty instalado."
  else
    warn "Ghostty no está en repos de esta distro; instalalo manualmente y luego aplicá la config."
  fi
}

install_wezterm() {
  if install_package_if_missing wezterm 2>/dev/null; then
    ok "WezTerm instalado."
  else
    warn "WezTerm no está en repos de esta distro; instalalo manualmente y luego aplicá la config."
  fi
}

install_zsh() {
  install_package_if_missing zsh
  install_oh_my_zsh
  if [[ "$SHELL" != *zsh ]]; then
    warn "Shell actual: $SHELL. Para usar zsh por defecto: chsh -s \"$(command -v zsh)\""
  fi
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

install_hyprland() {
  install_package_if_missing hyprland
  install_package_if_missing waybar
  install_package_if_missing dunst
  install_package_if_missing swaybg
  install_package_if_missing hypridle
  install_package_if_missing grim
  install_package_if_missing slurp
  install_package_if_missing wl-clipboard
  install_package_if_missing cliphist
  install_package_if_missing brightnessctl
  ok "Hyprland y complementos instalados."
}

install_spotify_snap() {
  install_snap_app spotify
  ok "Spotify instalado."
}

install_vscode() {
  install_snap_app code --classic
}

install_android_studio() {
  install_snap_app android-studio --classic
}

install_yarn() {
  if [[ "$PM" == "pacman" ]]; then
    install_package_if_missing yarn
    ok "Yarn instalado."
    return
  fi

  [[ "$PM" == "apt" ]] || { warn_pm; return; }
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

  if [[ "$PM" == "pacman" ]]; then
    install_package_if_missing lazygit
    ok "Lazygit instalado."
    return
  fi

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

install_keyd() {
  if [[ "$PM" != "pacman" ]]; then
    warn "keyd solo está empaquetado en Arch/CachyOS en este repo; saltando."
    return 1
  fi

  install_package_if_missing keyd || { warn "No se pudo instalar keyd."; return 1; }

  local src="$REPO_ROOT/system/etc/keyd/default.conf"
  [[ -f "$src" ]] || die "Falta el archivo de sistema: $src"

  # Cada paso se verifica: install_keyd se llama dentro de "|| warn",
  # así que errexit no aplica y un sudo cancelado no debe pasar por bueno.
  sudo install -Dm644 "$src" /etc/keyd/default.conf ||
    { warn "No se pudo copiar $src a /etc/keyd (¿sudo cancelado?)."; return 1; }

  if systemctl is-active --quiet keyd; then
    sudo keyd reload || { warn "No se pudo recargar keyd."; return 1; }
  else
    sudo keyd check || { warn "keyd check falló: revisá $src"; return 1; }
    sudo systemctl enable --now keyd || { warn "No se pudo activar keyd."; return 1; }
  fi

  ok "keyd aplicado: AltGr+, → < y AltGr+. → >."
}

clean() {
  case "$PM" in
    apt)
      sudo apt autoremove -y
      sudo apt clean
      ;;
    pacman)
      sudo pacman -Sc --noconfirm
      ;;
  esac
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
  install_hyprland
  install_nodejs
  install_lazygit
  install_keyd
  clean

  log "Re-aplicando stow con todos los programas instalados..."
  "$REPO_ROOT/link.sh" --fix

  log "Validando symlinks finales..."
  "$REPO_ROOT/check.sh" || true

  ok "Instalación completa finalizada."
}

# ==============================================================================
# Catálogo: herramienta → instalación + configs
# Formato: tag|etiqueta|comando requerido|función|paquetes stow
# ==============================================================================
TOOL_CATALOG=(
  "__installed|Sincronizar configs de lo instalado||__installed|"
  "__base|Paquetes base del sistema||install_packages|"
  "nvim|Neovim|nvim|install_neovim|nvim"
  "opencode|OpenCode|opencode|install_opencode|opencode"
  "kitty|Kitty|kitty|install_kitty|kitty"
  "alacritty|Alacritty|alacritty|install_alacritty|alacritty"
  "ghostty|Ghostty|ghostty|install_ghostty|ghostty"
  "wezterm|WezTerm|wezterm|install_wezterm|wezterm"
  "zsh|Zsh + Oh My Zsh|zsh|install_zsh|shell"
  "tmux|Tmux|tmux|install_tmux|shell"
  "rofi|Rofi|rofi|install_rofi|rofi"
  "hyprland|Hyprland + complementos|Hyprland|install_hyprland|hypr waybar dunst"
  "vscode|VS Code|code|install_vscode|"
  "spotify|Spotify|spotify|install_spotify_snap|"
  "android-studio|Android Studio|android-studio|install_android_studio|"
  "bun|Bun|bun|install_bun|"
  "nodejs|Node.js (via FNM)|fnm|install_nodejs|"
  "yarn|Yarn|yarn|install_yarn|"
  "lazygit|Lazygit|lazygit|install_lazygit|"
  "keyd|keyd (tecla < > con AltGr)|keyd|install_keyd|"
  "nerd-fonts|Nerd Fonts||install_nerd_fonts|"
  "kitty-themes|kitty-themes||install_kitty_themes|"
  "__all|Aplicar TODOS los dotfiles||__apply_all|"
  "__check|Validar symlinks||__check|"
  "__clean|Limpiar sistema||__clean|"
)

catalog_entry() {
  local tag="$1" entry
  for entry in "${TOOL_CATALOG[@]}"; do
    if [[ "${entry%%|*}" == "$tag" ]]; then
      printf '%s\n' "$entry"
      return 0
    fi
  done
  return 1
}

catalog_label() {
  local entry label
  if entry="$(catalog_entry "$1")"; then
    IFS='|' read -r _ label _ _ _ <<< "$entry"
    printf '%s' "$label"
  else
    printf '%s' "$1"
  fi
}

list_tools() {
  local entry tag label req pkgs
  printf '%-16s %-38s %-12s %s\n' "TAG" "HERRAMIENTA" "REQUIERE" "CONFIGS"
  printf '%-16s %-38s %-12s %s\n' "----" "-----------" "--------" "-------"
  for entry in "${TOOL_CATALOG[@]}"; do
    IFS='|' read -r tag label req _ pkgs <<< "$entry"
    printf '%-16s %-38s %-12s %s\n' "$tag" "$label" "${req:--}" "${pkgs:--}"
  done
}

run_tool_action() {
  local fn="$1" label="$2"
  case "$fn" in
    "") return 0 ;;
    __apply_all) apply_config_files ;;
    __check) "$REPO_ROOT/check.sh" || true ;;
    __clean) clean ;;
    *)
      if declare -F "$fn" >/dev/null 2>&1; then
        "$fn"
      else
        warn "Acción desconocida: $fn ($label)"
        return 1
      fi
      ;;
  esac
}

installed_tags() {
  local entry tag req
  for entry in "${TOOL_CATALOG[@]}"; do
    IFS='|' read -r tag _ req _ _ <<< "$entry"
    [[ "$tag" == "__installed" ]] && continue
    if [[ -n "$req" ]] && command -v "$req" >/dev/null 2>&1; then
      printf '%s\n' "$tag"
    fi
  done
}

apply_tool() {
  local tag="$1" entry label fn pkgs

  # Pseudo-herramienta: expandir a todo lo que ya está instalado
  if [[ "$tag" == "__installed" ]]; then
    local t
    while IFS= read -r t; do
      if [[ -n "$t" ]]; then
        apply_tool "$t" || true
      fi
    done < <(installed_tags)
    return 0
  fi

  if ! entry="$(catalog_entry "$tag")"; then
    warn "Herramienta desconocida: $tag"
    return 1
  fi
  IFS='|' read -r _ label _ fn pkgs <<< "$entry"

  # --config-only: solo acciones que aplican configs
  # install_keyd también cuenta: su "config" vive en /etc, no en stow.
  if [[ "$CONFIG_ONLY" == true && -z "$pkgs" && "$fn" != "__apply_all" && "$fn" != "__check" && "$fn" != "install_keyd" ]]; then
    warn "$label: no tiene configs para aplicar (modo --config-only)."
    return 0
  fi

  log "▶ $label"

  if [[ "$DRY_RUN" == true ]]; then
    case "$fn" in
      "") ;;
      __apply_all|__check|__clean) echo "   acción   → $fn" ;;
      *) [[ "$CONFIG_ONLY" == true ]] || echo "   instalar → $fn" ;;
    esac
    [[ -z "$pkgs" ]] || echo "   configs  → link.sh $pkgs"
    return 0
  fi

  if [[ "$CONFIG_ONLY" != true && -n "$fn" ]]; then
    run_tool_action "$fn" "$label" || warn "Falló: $label"
  fi

  if [[ -n "$pkgs" ]]; then
    if [[ "$CONFIG_MODE" == "copy" ]]; then
      warn "Modo --copy: usá 'Aplicar TODOS los dotfiles' para copiar configs."
    else
      # shellcheck disable=SC2086  # lista controlada desde el catálogo
      "$REPO_ROOT/link.sh" $pkgs || warn "No se pudo aplicar la config de $label"
    fi
  fi
}

build_checklist_items() {
  local entry tag label req state
  CHECKLIST_ITEMS=()
  for entry in "${TOOL_CATALOG[@]}"; do
    IFS='|' read -r tag label req _ _ <<< "$entry"
    state="OFF"
    # Preseleccionar lo ya instalado: Enter = sincronizar configs
    if [[ -n "$req" ]] && command -v "$req" >/dev/null 2>&1; then
      state="ON"
    fi
    CHECKLIST_ITEMS+=("$tag" "$label" "$state")
  done
}

run_numeric_menu() {
  local i=1 entry tag label req choice n
  echo "Herramientas disponibles:"
  for entry in "${TOOL_CATALOG[@]}"; do
    IFS='|' read -r tag label req _ _ <<< "$entry"
    printf '  %2d) %-38s %s\n' "$i" "$label" "${req:+[$req]}"
    i=$((i + 1))
  done
  printf '\nNúmeros separados por espacio (ej: 1 3 5), "a" = todas, Enter = salir: '
  read -r choice || return 0
  [[ -z "$choice" ]] && { log "Cancelado."; return 0; }

  local tags=()
  if [[ "$choice" == "a" || "$choice" == "all" ]]; then
    for entry in "${TOOL_CATALOG[@]}"; do
      tags+=("${entry%%|*}")
    done
  else
    for n in $choice; do
      if [[ ! "$n" =~ ^[0-9]+$ ]]; then
        warn "Ignorando: $n"
        continue
      fi
      entry="${TOOL_CATALOG[$((n - 1))]:-}"
      if [[ -z "$entry" ]]; then
        warn "Fuera de rango: $n"
        continue
      fi
      tags+=("${entry%%|*}")
    done
  fi

  [[ ${#tags[@]} -eq 0 ]] && return 0
  for tag in "${tags[@]}"; do
    apply_tool "$tag" || true
  done
  [[ "$DRY_RUN" == true ]] || "$REPO_ROOT/check.sh" || true
}

build_fzf_list() {
  local entry tag label req state
  for entry in "${TOOL_CATALOG[@]}"; do
    IFS='|' read -r tag label req _ _ <<< "$entry"
    state="○"
    if [[ -n "$req" ]] && command -v "$req" >/dev/null 2>&1; then
      state="●"
    fi
    printf '%s\t%s\t%s\n' "$tag" "$label" "$state"
  done
}

run_fzf_menu() {
  local tmp tag entry req
  tmp="$(mktemp)"

  if ! build_fzf_list | fzf --multi --height=100% --reverse --cycle \
      --delimiter='\t' --with-nth=2,3 \
      --highlight-line \
      --header='Tab marca · Ctrl-a todo · Ctrl-d nada · rueda/PgUp desplaza · Enter aplica' \
      --prompt='Instalar y configurar> ' \
      --bind='ctrl-a:select-all,ctrl-d:deselect-all' \
      --color="fg:${MENU_FG},bg:${MENU_BG},hl:${MENU_COLOR3},fg+:#ffffff,bg+:${MENU_ACCENT},hl+:#ffffff,selected-bg:${PALETTE_SEL_BG:-#170830},selected-fg:#ffffff,pointer:${MENU_PINK},marker:${MENU_PINK},header:${MENU_COLOR3},prompt:${MENU_PINK},spinner:${MENU_COLOR3},info:${MENU_COLOR7},border:${MENU_ACCENT},label:${MENU_COLOR3},query:${MENU_FG}" > "$tmp"; then
    rm -f "$tmp"
    log "Cancelado."
    return 0
  fi

  local tags=()
  while IFS=$'\t' read -r tag _; do
    [[ -n "$tag" ]] && tags+=("$tag")
  done < "$tmp"
  rm -f "$tmp"

  # Enter sin marcar nada: sincronizar lo que ya está instalado
  if [[ ${#tags[@]} -eq 0 ]]; then
    for entry in "${TOOL_CATALOG[@]}"; do
      IFS='|' read -r tag _ req _ _ <<< "$entry"
      if [[ -n "$req" ]] && command -v "$req" >/dev/null 2>&1; then
        tags+=("$tag")
      fi
    done
  fi

  if [[ ${#tags[@]} -eq 0 ]]; then
    warn "No seleccionaste nada."
    return 0
  fi

  for tag in "${tags[@]}"; do
    apply_tool "$tag" || true
  done

  if [[ "$DRY_RUN" != true ]]; then
    log "Validando symlinks..."
    "$REPO_ROOT/check.sh" || true
  fi
}

run_checklist_menu() {
  if ! command -v whiptail >/dev/null 2>&1; then
    warn "whiptail no está instalado; usando menú numérico."
    run_numeric_menu
    return 0
  fi

  build_checklist_items

  # Resalta la casilla enfocada con el acento de la paleta
  local newt_colors="actcheckbox=white,${MENU_ACCENT}"

  local out
  if ! out="$(NEWT_COLORS="$newt_colors" whiptail --title "Dotfiles — herramientas" \
      --separate-output --checklist \
      "Espacio marca/desmarca · PgUp/PgDn desplaza · Enter aplica" \
      26 82 18 "${CHECKLIST_ITEMS[@]}" 3>&1 1>&2 2>&3)"; then
    log "Cancelado."
    return 0
  fi

  local chosen=() line
  while IFS= read -r line; do
    [[ -n "$line" ]] && chosen+=("$line")
  done <<< "$out"

  if [[ ${#chosen[@]} -eq 0 ]]; then
    warn "No seleccionaste nada."
    return 0
  fi

  local labels=() tag mode list confirm_text
  for tag in "${chosen[@]}"; do
    labels+=("$(catalog_label "$tag")")
  done
  mode="instalar paquetes + aplicar configs"
  [[ "$CONFIG_ONLY" == true ]] && mode="solo aplicar configs"

  list="$(printf '  • %s\n' "${labels[@]}")"
  printf -v confirm_text 'Modo: %s\n\n%s\n¿Continuar?' "$mode" "$list"

  if ! whiptail --title "Confirmar" --yesno "$confirm_text" 22 78; then
    log "Cancelado."
    return 0
  fi

  for tag in "${chosen[@]}"; do
    apply_tool "$tag" || true
  done

  if [[ "$DRY_RUN" != true ]]; then
    log "Validando symlinks..."
    "$REPO_ROOT/check.sh" || true
  fi
}

run_tool_menu() {
  case "$UI_MODE" in
    fzf) run_fzf_menu ;;
    whiptail) run_checklist_menu ;;
    numeric) run_numeric_menu ;;
    auto)
      if command -v fzf >/dev/null 2>&1; then
        run_fzf_menu
      elif command -v whiptail >/dev/null 2>&1; then
        run_checklist_menu
      else
        run_numeric_menu
      fi
      ;;
    *)
      warn "UI desconocida: $UI_MODE (usá fzf, whiptail o numeric)."
      run_checklist_menu
      ;;
  esac
}

# ==============================================================================
# Punto de entrada
# ==============================================================================
if [[ "$LIST_MODE" == true ]]; then
  list_tools
  exit 0
fi

if [[ "$ALL_MODE" == true ]]; then
  install_all
  exit 0
fi

if [[ -n "$ONLY_TAGS" ]]; then
  IFS=',' read -r -a ONLY_LIST <<< "$ONLY_TAGS"
  for tag in "${ONLY_LIST[@]}"; do
    [[ -z "$tag" ]] || apply_tool "$tag" || true
  done
  [[ "$DRY_RUN" == true ]] || "$REPO_ROOT/check.sh" || true
  exit 0
fi

run_tool_menu

