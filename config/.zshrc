# =========================
#  Zsh config — optimizado
#  Fecha: 2025-08-11
# =========================

# Salir si la shell no es interactiva (acelera scripts)
[[ $- != *i* ]] && return

# -------------------------
# Opciones de shell útiles
# -------------------------
setopt autocd correct                    # cd implícito y sugerencias
setopt hist_ignore_all_dups              # evita duplicados en historial
setopt share_history inc_append_history  # comparte y agrega al vuelo
setopt extended_glob glob_dots           # glob avanzado e incluye dotfiles
setopt no_beep notify                    # sin beep, notifica jobs
setopt nobanghist                        # no expande ! en historial

# -------------------------
# PATH limpio y ordenado
# -------------------------
typeset -U path
path=("$HOME/.local/bin" $path)
path+=("$HOME/.local/share/pnpm")
export ANDROID_HOME="$HOME/Android/Sdk"
path+=("$ANDROID_HOME/emulator" "$ANDROID_HOME/avd" "$ANDROID_HOME/tools" "$ANDROID_HOME/tools/bin" "$ANDROID_HOME/platform-tools")
path+=("$HOME/.bun/bin")
export PATH

# -------------------------
# Editores / utilidades
# -------------------------
export EDITOR=nvim

# -------------------------
# Java (resolver JAVA_HOME una sola vez)
# -------------------------
if [[ -z "$JAVA_HOME" && -e /etc/alternatives/java ]]; then
  export JAVA_HOME="$(dirname "$(dirname "$(readlink -f /etc/alternatives/java)")")"
fi

# -------------------------
# Oh-My-Zsh
# -------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
CASE_SENSITIVE="false"
export UPDATE_ZSH_DAYS=7
DISABLE_FZF_AUTO_COMPLETION="false"

# Quitamos 'virtualenvwrapper' de plugins para evitar doble carga
plugins=(git tmux fzf command-not-found autopep8 zsh-interactive-cd sublime-merge themes)

# Cargar Oh-My-Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# fzf (si está instalado)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Deno env (opcional)
[[ -f "$HOME/.deno/env" ]] && . "$HOME/.deno/env"

# -------------------------
# Autocompletado rápido
# -------------------------
zmodload zsh/complist 2>/dev/null
autoload -Uz compinit && compinit -C

# -------------------------
# Virtualenvwrapper seguro
# -------------------------
export WORKON_HOME="$HOME/.virtualenvs"
export VIRTUALENVWRAPPER_PYTHON="${VIRTUALENVWRAPPER_PYTHON:-/usr/bin/python3}"
export VIRTUALENVWRAPPER_VIRTUALENV="$HOME/.local/bin/virtualenv"

if "$VIRTUALENVWRAPPER_PYTHON" - <<'PY' 2>/dev/null
import importlib.util, sys
sys.exit(0 if importlib.util.find_spec("virtualenvwrapper.hook_loader") else 1)
PY
then
  for f in "$HOME/.local/bin/virtualenvwrapper.sh" \
           "/usr/share/virtualenvwrapper/virtualenvwrapper.sh" \
           "/usr/bin/virtualenvwrapper.sh"
  do
    [[ -f "$f" ]] && source "$f" && break
  done
fi

install_virtualenvwrapper() {
  if ! command -v pip &> /dev/null; then
    echo "pip no está instalado. Instalalo primero."
    return 1
  fi
  if ! "$VIRTUALENVWRAPPER_PYTHON" -m pip show virtualenvwrapper &> /dev/null; then
    echo "Instalando virtualenvwrapper para $VIRTUALENVWRAPPER_PYTHON..."
    "$VIRTUALENVWRAPPER_PYTHON" -m pip install --user virtualenv virtualenvwrapper
    echo "Listo. Reiniciá la shell."
  else
    echo "virtualenvwrapper ya está instalado."
  fi
}

# -------------------------
# Android emulator helper
# -------------------------
is_emulator_running() {
  pgrep -f "emulator -avd $1" > /dev/null
}

androidemulator() {
  local avd
  if command -v fzf >/dev/null 2>&1; then
    avd="${1:-$(emulator -list-avds | grep -v '^INFO' | fzf --prompt='AVD> ')}"
  else
    avd="${1:-$(emulator -list-avds | grep -v '^INFO' | head -n1)}"
  fi

  [[ -z "$avd" ]] && { echo "No hay AVD seleccionado."; return 1; }

  if is_emulator_running "$avd"; then
    echo "El AVD '$avd' ya está en ejecución."
  else
    echo "Iniciando AVD: $avd…"
    emulator -avd "$avd" -read-only
  fi
}
alias em='androidemulator'

# -------------------------
# Aliases más seguros
# -------------------------
alias code='code .'
alias expo='bunx create-expo-app@latest'
alias android='yarn android && code .'
alias update='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt clean'
alias run-react='yarn react-native run-android && yarn react-native start'
alias ls='ls --color=auto'
alias ll='ls -al --color=auto'
alias path='echo $PATH | tr ":" "\n" | nl'
alias tree='tree -I "node_modules" -L 4'
alias grep='grep --color=auto'
if command -v trash >/dev/null 2>&1; then
  alias rm='trash'
else
  alias rm='rm -I'
fi
alias cp='cp -i'
alias mv='mv -i'
alias gs='git status'
alias gp='git pull'
alias gpp='git push'
alias gc='git commit -am'

# -------------------------
# Prompt moderno (opcional)
# -------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# -------------------------
# Profiling de arranque
# -------------------------
if [[ -n "$ZPROF" ]]; then
  zmodload zsh/zprof
  zprof
fi
