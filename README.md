# Dotfiles

Repositorio de configuración personal para entorno Linux (terminal + shell + Neovim).

## Qué incluye

- `install.sh`: instalador interactivo por menú para preparar el sistema.
- `config/nvim`: configuración modular de Neovim en Lua.
- `config/kitty.conf`: configuración de Kitty.
- `config/alacritty/alacritty.toml`: configuración de Alacritty.
- `config/.zshrc`, `config/.zsh_aliases`, `config/.bashrc`: configuración de shell.

## Requisitos mínimos

- Arch Linux o Manjaro con `sudo`.
- `curl` y `git`.

## Uso rápido

```bash
chmod +x install.sh
./install.sh
```

El script permite:

- Instalar paquetes del sistema con `pacman`.
- Instalar paquetes desde AUR (Android Studio, Spotify, VS Code).
- Inicializar paru como helper de AUR.
- Aplicar dotfiles con **GNU Stow** (default y recomendado) o copiarlos al `$HOME`.
- Instalar herramientas (Bun, Node.js con FNM, Yarn, lazygit, Nerd Fonts).

> Si venías del modo de enlaces antiguo, el instalador limpia symlinks heredados en rutas administradas antes de aplicar Stow para evitar conflictos.

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

La carpeta `stow/` contiene symlinks que apuntan a `config/`. Al ejecutar `stow`, se crean los symlinks en `$HOME`.

- `shell` → `~/.zshrc`, `~/.zsh_aliases`, `~/.bashrc`, `~/.tmux.conf`, `~/.gitconfig`, `~/.config/shell/path.sh`
- `nvim` → `~/.config/nvim`
- `kitty` → `~/.config/kitty/kitty.conf`, `~/.config/kitty/colors/kitty-colors.conf`
- `alacritty` → `~/.config/alacritty/alacritty.toml`, `~/.config/alacritty/colors/alacritty-colors.toml`
- `ghostty` → `~/.config/ghostty/config`, `~/.config/ghostty/colors/ghostty-colors`
- `wezterm` → `~/.config/wezterm/wezterm.lua`

## Ruta de configs destino

- `~/.zshrc`
- `~/.zsh_aliases`
- `~/.bashrc`
- `~/.tmux.conf`
- `~/.gitconfig`
- `~/.config/nvim`
- `~/.config/kitty/kitty.conf`
- `~/.config/kitty/colors/kitty-colors.conf`
- `~/.config/alacritty/alacritty.toml`
- `~/.config/alacritty/colors/alacritty-colors.toml`
- `~/.config/ghostty/config`
- `~/.config/ghostty/colors/ghostty-colors`
- `~/.config/wezterm/wezterm.lua`
- `~/.config/shell/path.sh`

## Nota

Si ya tenés herramientas instaladas, el instalador intenta detectarlas y saltar su reinstalación para que el proceso sea más rápido e idempotente.

## Troubleshooting

Si al ejecutar `./install.sh` aparece un error como `error sintáctico cerca del elemento inesperado '<<<'`, normalmente hay marcadores de merge sin resolver en tu copia local.

```bash
# Verificar marcadores de merge
rg -n "^(<<<<<<<|=======|>>>>>>>)" install.sh README.md config

# Si aparece algo, refrescar el branch
git fetch origin
git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)

# Si estás en medio de un merge y el conflicto es en install.sh
git checkout --ours install.sh
git add install.sh
git merge --continue
```
