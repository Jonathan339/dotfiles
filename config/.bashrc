# =========================
#  .bashrc optimizado
#  Fecha: 2025-08-11
# =========================

# 0) Salir si no es interactivo (acelera scripts que usan bash)
case $- in
  *i*) ;;
  *) return ;;
esac

# 1) Si hay zsh, pasate a zsh en sesiones interactivas (y no recurses)
if [ -t 1 ] && [ -z "${ZSH_VERSION:-}" ] && command -v zsh >/dev/null 2>&1; then
  exec /bin/zsh -l
fi

# --- A partir de acá solo corre si te quedaste en bash ---

# 2) Historial más útil
HISTCONTROL=ignoreboth # ignora duplicados y líneas que empiezan con espacio
shopt -s histappend    # append en vez de overwrite
HISTSIZE=10000
HISTFILESIZE=20000
PROMPT_COMMAND='history -a; history -c; history -r; '"$PROMPT_COMMAND"

# 3) Tamaño de terminal correcto tras cada comando
shopt -s checkwinsize

# 4) less más inteligente
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# 5) Prompt básico (solo si te quedaste en bash)
case "$TERM" in
  xterm-color | *-256color) color_prompt=yes ;;
esac
if [ "$color_prompt" = yes ] && [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt

# 6) Colores y aliases útiles
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

# 7) Bash completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# 8) fzf (si está)
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# 9) Homebrew (arreglo: ejecutar eval, no echo)
if command -v /home/linuxbrew/.linuxbrew/bin/brew >/dev/null 2>&1; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# 10) bun
export BUN_INSTALL="$HOME/.bun"
case ":$PATH:" in
  *":$BUN_INSTALL/bin:"*) ;;
  *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
esac

# 11) Deno (si existe env)
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# 12) pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# 13) ~/.bash_aliases opcional
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Fin

# fnm
FNM_PATH="/home/jonathan/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell bash)"
fi
