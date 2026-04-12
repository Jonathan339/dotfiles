# Dotfiles

Repositorio de configuración personal para entorno Linux (terminal + shell + Neovim).

## Qué incluye

- `install.sh`: instalador interactivo por menú para preparar el sistema.
- `stow/`: paquetes de dotfiles para desplegar configuración con GNU Stow.
- `config/nvim`: configuración modular de Neovim en Lua.
- `config/kitty.conf`: configuración de Kitty.
- `config/alacritty/alacritty.toml`: configuración de Alacritty.
- `config/wezterm.lua`: configuración de WezTerm.
- `config/.zshrc`, `config/.zsh_aliases`, `config/.bashrc`: configuración de shell.

## Requisitos mínimos

- Ubuntu/Debian con `sudo`.
- `curl` y `git`.

## Uso rápido

```bash
chmod +x install.sh
./install.sh
```

El script permite:

- Instalar dependencias APT comunes de desarrollo.
- Aplicar dotfiles con **GNU Stow** (default y recomendado) o copiarlos al `$HOME`.
- Instalar herramientas opcionales (Bun, Node.js con FNM, Yarn, lazygit).
- Instalar aplicaciones por `snap` (VS Code, Spotify, Android Studio, Neovim).

También podés usar modo rápido sin menú:

```bash
# Instala todo usando GNU Stow (default)
./install.sh --all

# Instala todo copiando archivos (opcional)
./install.sh --all --copy
```

## GNU Stow vs copia

- **GNU Stow (default)**: cualquier cambio en este repo se refleja inmediatamente en tu entorno mediante symlinks ordenados por paquete.
- **Copiar**: deja una copia estática de la configuración en tu `$HOME`.

### Paquetes Stow

- `stow/shell` → `~/.zshrc`, `~/.zsh_aliases`, `~/.bashrc`
- `stow/nvim` → `~/.config/nvim`
- `stow/kitty` → `~/.config/kitty/kitty.conf`
- `stow/alacritty` → `~/.config/alacritty/alacritty.toml`
- `stow/wezterm` → `~/.config/wezterm/wezterm.lua`

## Ruta de configs destino

- `~/.zshrc`
- `~/.zsh_aliases`
- `~/.bashrc`
- `~/.config/nvim`
- `~/.config/kitty/kitty.conf`
- `~/.config/alacritty/alacritty.toml`
- `~/.config/wezterm/wezterm.lua`

## Nota

Si ya tenés herramientas instaladas, el instalador intenta detectarlas y saltar su reinstalación para que el proceso sea más rápido e idempotente.
