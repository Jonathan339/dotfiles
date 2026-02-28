# =========================
#  Zsh config — optimizado
#  Fecha: 2026-02-21
# =========================

# =========================
# Zsh config — ULTRA OPTIMIZADO
# =========================

# Salir si no es interactiva
[[ $- != *i* ]] && return

# -------------------------
# Opciones core rápidas
# -------------------------
setopt autocd
setopt correct
setopt hist_ignore_all_dups
setopt share_history
setopt inc_append_history
setopt extended_glob
setopt glob_dots
setopt no_beep
setopt notify
setopt nobanghist

# -------------------------
# PATH optimizado
# -------------------------
typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/pnpm"
  "$HOME/.bun/bin"
  $path
)

export ANDROID_HOME="$HOME/Android/Sdk"

path+=(
  "$ANDROID_HOME/emulator"
  "$ANDROID_HOME/platform-tools"
  "$ANDROID_HOME/tools"
  "$ANDROID_HOME/tools/bin"
)

export PATH

# -------------------------
# Editor
# -------------------------
export EDITOR=nvim

# -------------------------
# JAVA_HOME rápido (sin forks extra)
# -------------------------
if [[ -z "$JAVA_HOME" && -L /etc/alternatives/java ]]; then
  export JAVA_HOME=${${$(readlink -f /etc/alternatives/java):h}:h}
fi

# -------------------------
# Cache dirs
# -------------------------
ZSH_CACHE="$HOME/.cache/zsh"
mkdir -p "$ZSH_CACHE"

# -------------------------
# Oh My Zsh (modo rápido)
# -------------------------
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(
  git
  tmux
  command-not-found
  zsh-interactive-cd
)

# cargar solo si existe
[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# -------------------------
# compinit ULTRA rápido
# -------------------------
autoload -Uz compinit

ZCOMPFILE="$ZSH_CACHE/zcompdump-$ZSH_VERSION"

if [[ -f "$ZCOMPFILE" ]]; then
  compinit -d "$ZCOMPFILE"
else
  compinit -d "$ZCOMPFILE"
fi

# -------------------------
# Lazy load fzf
# -------------------------
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
fi

# -------------------------
# Lazy load Deno
# -------------------------
[[ -f "$HOME/.deno/env" ]] && source "$HOME/.deno/env"

# -------------------------
# Virtualenvwrapper lazy
# -------------------------
export WORKON_HOME="$HOME/.virtualenvs"

load_virtualenvwrapper() {
  for f in \
    "$HOME/.local/bin/virtualenvwrapper.sh" \
    "/usr/share/virtualenvwrapper/virtualenvwrapper.sh"
  do
    [[ -r "$f" ]] && source "$f" && return
  done
}

alias workon='load_virtualenvwrapper && workon'
alias mkvirtualenv='load_virtualenvwrapper && mkvirtualenv'

# -------------------------
# Android emulator helper
# -------------------------
is_emulator_running() {
  pgrep -f "emulator -avd $1" >/dev/null
}

androidemulator() {

  local avd

  if command -v fzf >/dev/null; then
    avd="${1:-$(emulator -list-avds | fzf)}"
  else
    avd="${1:-$(emulator -list-avds | head -n1)}"
  fi

  [[ -z "$avd" ]] && return

  if is_emulator_running "$avd"; then
    echo "Ya está ejecutándose."
  else
    emulator -avd "$avd" -read-only &
  fi
}

alias em='androidemulator'

# -------------------------
# Aliases seguros
# -------------------------
alias ls='ls --color=auto'
alias ll='ls -alF'
alias grep='grep --color=auto'

alias rm='rm -I'
alias cp='cp -i'
alias mv='mv -i'

alias gs='git status'
alias gp='git pull'
alias gpp='git push'
alias gc='git commit -am'

alias update='sudo apt update && sudo apt upgrade -y'

# -------------------------
# Starship prompt (rápido)
# -------------------------
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# -------------------------
# Profiling opcional
# -------------------------
if [[ "$ZSH_PROFILING" == "1" ]]; then
  zmodload zsh/zprof
  zprof
fi
