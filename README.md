# Dotfiles

Repositorio de configuración personal para entorno Linux: shell, terminales, Neovim,
entorno gráfico (Hyprland/Waybar/Dunst), Rofi y OpenCode.

Soporta **Debian/Ubuntu (apt)** y **Arch/CachyOS (pacman)** con el mismo árbol de configs.

## Qué incluye

- `install.sh`: instalador interactivo por menú, con soporte multi-distro (apt/pacman).
- `link.sh`: aplica los paquetes de `stow/` a `$HOME` con GNU Stow (detección automática de capas).
- `check.sh`: valida que todos los symlinks existan y apunten bien.
- `config/`: archivos reales de configuración (nvim, shell, terminales, paleta de colores).
- `stow/`: paquetes que Stow enlaza a `$HOME`, organizados en capas.
- `scripts/generate-palette.sh`: regenera los colores de kitty/alacritty/ghostty
  desde `config/colors/palette.sh` (fuente única).

## Modelo de capas (GNU Stow)

Precedencia (la última gana): `shared` < `os/<so>` < `wm/<wm>` < `host/<hostname>`.

`link.sh` y `check.sh` detectan las capas solas:

- SO: `/etc/os-release` (`ID` / `ID_LIKE`).
- Escritorio: `XDG_CURRENT_DESKTOP` (con fallback a `pgrep Hyprland` / `pgrep xfce4-session` / `pgrep plasmashell`).
- Host: `hostname`.

Los archivos reales viven en `config/`; dentro de `stow/` hay symlinks hacia `config/`
(los mantiene el repo). Los paquetes que no tienen contraparte en `config/`
(`rofi`, `opencode`, `hypr`, `waybar`, `dunst`, `kde`) viven íntegros dentro de `stow/`.

> ⚠️ El repo necesita un filesystem con soporte de symlinks (ext4, btrfs, xfs…).
> En exFAT/NTFS/FAT los symlinks internos no se pueden materializar y el checkout queda incompleto.

## Requisitos mínimos

- Linux con `sudo`, `curl` y `git`.
- Gestor de paquetes soportado: `apt` (Debian/Ubuntu) o `pacman` (Arch/CachyOS).
- `stow` para el modo stow (el instalador lo instala junto al resto de los paquetes).

## Uso rápido

```bash
make install                # menú interactivo
make install-all            # instala todo (stow como default)
./install.sh --all --copy   # instala todo copiando archivos (sin stow)
make link                   # aplica stow en $HOME
make link-fix               # aplica + repara conflictos (backups *.bak.<ts>)
make check                  # valida symlinks (exit 0 = OK)
make palette                # regenera colores desde config/colors/palette.sh
make lint                   # shellcheck (requiere shellcheck instalado)
make backup                 # copia config/ a /tmp/dotfiles-backup-<ts>
```

También podés aplicar paquetes sueltos:

```bash
./link.sh shell nvim kitty
```

## GNU Stow vs copia

- **GNU Stow (default)**: cualquier cambio en este repo se refleja al instante en tu entorno
  mediante symlinks ordenados por paquete.
- **Copiar** (`--copy`): deja una copia estática en `$HOME`. Los paquetes que viven solo
  dentro de `stow/` (rofi, opencode, hypr…) no se copian en este modo.

## Paquetes Stow

- `shared`:
  - `shell` → `.zshrc`, `.bashrc`, `.zsh_aliases`, `.tmux.conf`, `.gitconfig`, `.config/shell/path.sh`
  - `nvim` → `.config/nvim`
  - `kitty`, `alacritty`, `ghostty`, `wezterm` → configuración + colores de cada terminal
  - `rofi`, `opencode` → viven íntegros en `stow/`
- `wm/hyprland`: `hypr` (`.config/hypr` + scripts en `.local/bin`), `waybar`, `dunst`.
- `os/<so>` y `host/<equipo>`: vacías por ahora; ahí van desviaciones por sistema o por máquina.

`link.sh` salta un paquete si falta su binario (tabla `REQUIREMENTS`), por ejemplo
no aplica `kitty` si `kitty` no está instalado.

## Ruta de configs destino

- `~/.zshrc`, `~/.zsh_aliases`, `~/.bashrc`, `~/.tmux.conf`, `~/.gitconfig`
- `~/.config/shell/path.sh`
- `~/.config/nvim`
- `~/.config/kitty/` (`kitty.conf` + `colors/kitty-colors.conf`)
- `~/.config/alacritty/` (`alacritty.toml` + `colors/alacritty-colors.toml`)
- `~/.config/ghostty/` (`config` + `colors/ghostty-colors`)
- `~/.config/wezterm/wezterm.lua`
- `~/.config/rofi/`, `~/.config/opencode/`
- `~/.config/hypr/`, `~/.config/waybar/`, `~/.config/dunst/`, `~/.local/bin/` (scripts de Hyprland)

## Notas por distro

### Arch / CachyOS

- Paquetes base: `rust` (provee `cargo`), `powerline-fonts`, `neovim`, `ttf-hack-nerd`,
  `tree-sitter-cli`, entre otros.
- VS Code se instala desde repos oficiales (`code`); Spotify y Android Studio vía AUR
  si hay `paru`/`yay` disponibles (si no, el instalador te avisa).
- `update()` en `.zshrc` usa `pacman -Syu`, `paru/yay -Sua` y `paccache` (si existen).
- La fuente DroidSansM Nerd Font la descarga el instalador (no viene empaquetada).

### Debian / Ubuntu

- Apps por snap: VS Code, Spotify, Android Studio y Neovim.
- `update()` en `.zshrc` usa `apt update` + `apt full-upgrade` + `snap refresh`.

## Hooks de Git

El repo trae hooks versionados en `.githooks/` (validan symlinks en checkout/pull/merge).
En un clon nuevo activalos con:

```bash
git config core.hooksPath .githooks
```

## Nota

Si ya tenés herramientas instaladas, el instalador intenta detectarlas y saltar su
reinstalación para que el proceso sea más rápido e idempotente.

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
