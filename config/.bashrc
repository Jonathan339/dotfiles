# shellcheck shell=bash
# =========================
#  .bashrc optimizado
#  Fecha: 2026-04-12
# =========================
# 0) Salir si no es interactivo
case $- in
  *i*) ;;
  *) return ;;
esac

# 1) Auto-switch a zsh si existe
if [ -t 1 ] && [ -z "${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
  exec /bin/zsh -l
fi

# -------------------------
# Historial mejorado
# -------------------------
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000

shopt -s histappend
PROMPT_COMMAND='history -a; history -c; history -r; '"$PROMPT_COMMAND"

# -------------------------
# Terminal resize fix
# -------------------------
shopt -s checkwinsize

# -------------------------
# Less inteligente
# -------------------------
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# -------------------------
# Prompt bash fallback
# -------------------------
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac

if [ "$color_prompt" = yes ] && [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

unset color_prompt

# -------------------------
# Aliases / colores
# -------------------------
if command -v dircolors >/dev/null 2>&1; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"

  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias path='echo "$PATH" | tr ":" "\n" | nl'

# -------------------------
# Bash completion
# -------------------------
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# -------------------------
# FZF
# -------------------------
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# -------------------------
# Homebrew
# -------------------------
if command -v /home/linuxbrew/.linuxbrew/bin/brew >/dev/null 2>&1; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# -------------------------
# PATH unificado
# -------------------------
[ -f "$HOME/.config/shell/path.sh" ] && source "$HOME/.config/shell/path.sh"

# -------------------------
# Deno
# -------------------------
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# -------------------------
# Bash aliases extra
# -------------------------
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# -------------------------
# FNM runtime
# -------------------------
if [ -d "$FNM_PATH" ]; then
  eval "$(fnm env --shell bash)"
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"
