# Cargar alias de bash si existe el archivo
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Obtener el nombre de usuario actual
_user="$(id -u -n)"

# Configuración de Virtualenvwrapper
export VIRTUALENVWRAPPER_PYTHON=$(which python3)
export WORKON_HOME=$HOME/.virtualenvs
export VIRTUALENVWRAPPER_VIRTUALENV=$HOME/.local/bin/virtualenv
source $HOME/.local/bin/virtualenvwrapper.sh

# Configuración del path de Java
export JAVA_HOME=$(dirname $(dirname $(readlink -f /etc/alternatives/java)))

# Configuración del path de Android
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/avd:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools

# Path a la instalación de Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
CASE_SENSITIVE="false"  # Autocompletado insensible a mayúsculas
export UPDATE_ZSH_DAYS=7
DISABLE_FZF_AUTO_COMPLETION="false"

# Plugins de Oh-My-Zsh
plugins=(git virtualenvwrapper tmux zsh-interactive-cd sublime-merge themes fzf command-not-found autopep8)

# Incluir Oh-My-Zsh y fzf si existen
source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Habilitar autocompletado de fzf
autoload -U compinit && compinit

# Función para listar y lanzar AVDs de Android
function get_android_avd() {
  emulator -list-avds
}

# Función para verificar si el emulador ya está en ejecución
function is_emulator_running() {
  pgrep -f "emulator -avd $1" > /dev/null
}

# Función para listar AVDs y lanzar el emulador
function androidemulator() {
  local emulator_avd
  emulator_avd=$(emulator -list-avds | grep -v "INFO")  # Filtrar salida "INFO"

  if [ -n "$emulator_avd" ]; then
    if is_emulator_running "$emulator_avd"; then
      echo "El AVD '$emulator_avd' ya está en ejecución."
    else
      echo "Iniciando AVD: $emulator_avd..."
      emulator -avd "$emulator_avd" -read-only  # Añadir el flag -read-only para evitar conflictos
    fi
  else
    echo "No hay AVDs disponibles."
  fi
}

# Función para instalar virtualenvwrapper si no está instalado
function install_virtualenvwrapper() {
  if ! command -v pip &> /dev/null; then
    echo "pip no está instalado. Por favor, instala pip antes de continuar."
    return 1
  fi

  if ! pip show virtualenvwrapper &> /dev/null; then
    echo "Instalando virtualenvwrapper..."
    pip install virtualenvwrapper
    echo "virtualenvwrapper instalado."
  else
    echo "virtualenvwrapper ya está instalado."
  fi
}

# Alias
alias em=androidemulator
alias code='code .'  # Lanzar VSCode en el directorio actual
alias expo="bunx create-expo-app@latest"
alias android='yarn android && code .'
alias update='sudo apt update && sudo apt upgrade -y'
alias run-react='yarn react-native run-android && yarn react-native start'
alias ls='ls --color=auto'
alias ll='ls -al --color=auto'
alias path='echo $PATH | tr ":" "\n" | nl'
alias tree='tree -I "node_modules" -L 4'
alias grep='grep --color=auto'
alias rm='rm -rf'
alias cp='cp -i'
alias mv='mv -i'
alias gs='git status'
alias gp='git pull'
alias gpp='git push'
alias gc='git commit -am'


export PATH="$HOME/.local/share/pnpm:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# Cargar entorno de Deno si existe
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
