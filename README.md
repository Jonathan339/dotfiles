# Dotfiles

Repositorio de configuración personal para entorno Linux (terminal + shell + Neovim).

## Qué incluye

- `install.sh`: instalador interactivo por menú para preparar el sistema.
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
- Enlazar (default y recomendado) o copiar dotfiles al `$HOME`.
- Instalar herramientas opcionales (Bun, Node.js con FNM, Yarn, lazygit).
- Instalar aplicaciones por `snap` (VS Code, Spotify, Android Studio, Neovim).

También podés usar modo rápido sin menú:

```bash
# Instala todo usando enlaces simbólicos (default)
./install.sh --all

# Instala todo copiando archivos (opcional)
./install.sh --all --copy
```

## Enlace simbólico vs copia

- **Enlazar (default)**: cualquier cambio en este repo se refleja inmediatamente en tu entorno.
- **Copiar**: deja una copia estática de la configuración en tu `$HOME`.

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
