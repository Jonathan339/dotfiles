export ANDROID_HOME="$HOME/Android/Sdk"
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"
export FNM_PATH="$HOME/.local/share/fnm"

path_add() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

path_add "$HOME/.local/bin"
path_add "$PNPM_HOME"
path_add "$BUN_INSTALL/bin"
path_add "$FNM_PATH"
path_add "$HOME/.opencode/bin"
path_add "$ANDROID_HOME/emulator"
path_add "$ANDROID_HOME/platform-tools"
path_add "$ANDROID_HOME/tools"
path_add "$ANDROID_HOME/tools/bin"
