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

path=(
  "$HOME/.local/bin"
  "$HOME/.local/share/pnpm"
  "$HOME/.bun/bin"
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

# Virtualenvwrapper lazy real
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
# Aliases limpios (sin duplicados)
# -------------------------
alias ls='ls --color=auto'
alias ll='ls -alF'
alias grep='grep --color=auto'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -rf'

alias gs='git status'
alias gp='git pull'
alias gpp='git push'
alias gc='git commit -am'

alias expo='bunx create-expo-app@latest --template blank-typescript'
alias android='yarn android && code .'
alias run-react='yarn react-native run-android && yarn react-native start'
alias em='androidemulator'
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

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
# Starship (más rápido que agnoster)
# -------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# -------------------------
# Profiling opcional
# -------------------------
if [[ "$ZSH_PROFILING" == "1" ]]; then
  zmodload zsh/zprof
  zprof
fi
