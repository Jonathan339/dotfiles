# shellcheck shell=bash
# =========================
# Zsh config — ULTRA CLEAN
# =========================

# Salir si no es interactiva
[[ $- != *i* ]] && return

# -------------------------
# Opciones rápidas
# -------------------------
setopt autocd correct \
       hist_ignore_all_dups share_history inc_append_history \
       extended_glob glob_dots no_beep notify nobanghist

# Deshabilitar XON/XOFF para que <C-s> funcione en Neovim
[[ -t 0 ]] && stty -ixon

# -------------------------
# PATH unificado
# -------------------------
[[ -f "$HOME/.config/shell/path.sh" ]] && source "$HOME/.config/shell/path.sh"
typeset -U path PATH

# -------------------------
# Editor
# -------------------------
export EDITOR=nvim

# -------------------------
# JAVA_HOME sin procesos extra
# -------------------------
if [[ -z "$JAVA_HOME" && -x /usr/bin/java ]]; then
  export JAVA_HOME="${${$(command -v java):A}:h:h}"
fi

# -------------------------
# Cache
# -------------------------
ZSH_CACHE="$HOME/.cache/zsh"
mkdir -p "$ZSH_CACHE"

# -------------------------
# Oh My Zsh mínimo
# -------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"

plugins=(git tmux)

# Autostart de tmux: cada terminal abre con una sesión tmux (Ctrl+a para pestañas)
ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_AUTOSTART_ONCE=true
# No cerrar la terminal al despegarse (Ctrl+a d)
ZSH_TMUX_AUTOQUIT=false

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# -------------------------
# compinit optimizado
# -------------------------
autoload -Uz compinit
ZCOMPFILE="$ZSH_CACHE/zcompdump"

if [[ -f "$ZCOMPFILE" ]]; then
  compinit -C -d "$ZCOMPFILE"
else
  compinit -d "$ZCOMPFILE"
fi

# -------------------------
# Lazy loads reales
# -------------------------
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
[[ -f "$HOME/.deno/env" ]] && source "$HOME/.deno/env"

# -------------------------
# Virtualenvwrapper lazy real
# -------------------------
export WORKON_HOME="$HOME/.virtualenvs"

load_virtualenvwrapper() {
  for f in \
    "$HOME/.local/bin/virtualenvwrapper.sh" \
    "/usr/share/virtualenvwrapper/virtualenvwrapper.sh"
  do
    [[ -r "$f" ]] && source "$f" && unfunction load_virtualenvwrapper && return
  done
}

alias workon='load_virtualenvwrapper && workon'
alias mkvirtualenv='load_virtualenvwrapper && mkvirtualenv'

# -------------------------
# Python venv por proyecto (.venv)
# -------------------------
mkvenv() {
  command -v python3 >/dev/null || { echo "x python3 no encontrado"; return 1 }
  python3 -m venv .venv && source .venv/bin/activate
}

venv_auto() {
  [[ -f .venv/bin/activate ]] && source .venv/bin/activate
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd venv_auto
venv_auto

# -------------------------
# Update del sistema
# -------------------------
update() {
  local start_time end_time duration
  start_time=$SECONDS

  echo
  echo "${fg[blue]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
  echo "${fg[cyan]}Actualizando sistema - $(date '+%H:%M:%S')${reset_color}"
  echo "${fg[blue]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"

  echo "${fg[yellow]}> apt update${reset_color}"
  sudo apt update || { echo "${fg[red]}x Error en apt update${reset_color}"; return 1; }

  echo "${fg[yellow]}> apt full-upgrade${reset_color}"
  sudo apt full-upgrade -y || { echo "${fg[red]}x Error en full-upgrade${reset_color}"; return 1; }

  echo "${fg[yellow]}> snap refresh${reset_color}"
  command -v snap >/dev/null && timeout 60 sudo snap refresh 2>/dev/null || echo "  snap: timeout o error"

  echo "${fg[yellow]}> pip${reset_color}"
  command -v pip3 >/dev/null && pip3 install --upgrade pip setuptools wheel --break-system-packages 2>/dev/null || true
  command -v pip >/dev/null && pip install --upgrade pip setuptools wheel --break-system-packages 2>/dev/null || true

  echo "${fg[yellow]}> bun upgrade${reset_color}"
  command -v bun >/dev/null && bun upgrade || true

  echo "${fg[yellow]}> apt autoremove${reset_color}"
  sudo apt autoremove -y || { echo "${fg[red]}x Error en autoremove${reset_color}"; return 1; }

  echo "${fg[yellow]}> apt clean${reset_color}"
  sudo apt clean

  end_time=$SECONDS
  duration=$(( end_time - start_time ))

  echo
  echo "${fg[green]}Sistema actualizado (${duration}s)${reset_color}"
  echo "${fg[blue]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
  echo
}

# -------------------------
# Aliases desde archivo externo
# -------------------------
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# -------------------------
# Android emulator helper
# -------------------------
androidemulator() {
  local avd

  if command -v fzf >/dev/null 2>&1; then
    avd="${1:-$(emulator -list-avds | fzf)}"
  else
    avd="${1:-$(emulator -list-avds | head -n1)}"
  fi

  [[ -z "$avd" ]] && return

  if pgrep -f "emulator -avd $avd" >/dev/null; then
    echo "Ya está ejecutándose."
  else
    emulator -avd "$avd" -read-only &
  fi
}

# -------------------------
# FNM Auto Use
# -------------------------
if [ -d "$FNM_PATH" ]; then
  eval "$(fnm env --use-on-cd)"
fi

# -------------------------
# Profiling opcional
# -------------------------
if [[ "$ZSH_PROFILING" == "1" ]]; then
  zmodload zsh/zprof
  zprof
fi
fpath+=${ZDOTDIR:-~}/.zsh_functions

# bun completions
[ -s "/home/jonathan/.bun/_bun" ] && source "/home/jonathan/.bun/_bun"
