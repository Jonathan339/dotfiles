# shellcheck shell=zsh
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

# -------------------------
# PATH (sin duplicados)
# -------------------------
typeset -U path PATH

export ANDROID_HOME="$HOME/Android/Sdk"
export FNM_PATH="$HOME/.local/share/fnm"
export PATH="$HOME/.opencode/bin:$PATH"
path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/pnpm"
  "$HOME/.bun/bin"
  "$FNM_PATH"
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/tools"
  "$ANDROID_HOME/tools/bin"
  $path
)

export PATH

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
# Update del sistema
# -------------------------
update() {
  local start_time end_time duration
  start_time=$SECONDS

  echo
  echo "${fg[blue]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
  echo "${fg[cyan]}🚀 Iniciando actualización - $(date '+%H:%M:%S')${reset_color}"
  echo "${fg[blue]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"

  echo "${fg[yellow]}▶ Actualizando repositorios...${reset_color}"
  if ! sudo apt update; then
    echo "${fg[red]}✖ Error en apt update${reset_color}"
    return 1
  fi

  echo "${fg[yellow]}▶ Actualizando sistema...${reset_color}"
  if ! sudo apt full-upgrade -y; then
    echo "${fg[red]}✖ Error en full-upgrade${reset_color}"
    return 1
  fi

  echo "${fg[yellow]}▶ Limpiando dependencias...${reset_color}"
  if ! sudo apt autoremove -y; then
    echo "${fg[red]}✖ Error en autoremove${reset_color}"
    return 1
  fi

  echo "${fg[yellow]}▶ Limpiando cache...${reset_color}"
  sudo apt clean

  end_time=$SECONDS
  duration=$(( end_time - start_time ))

  echo "${fg[green]}✔ Sistema actualizado correctamente.${reset_color}"
  echo "${fg[magenta]}⏱ Duración: ${duration}s${reset_color}"
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
# Starship
# -------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

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
