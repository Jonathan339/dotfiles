# AGENTS.md — Dotfiles (CachyOS/Arch + KDE; repo multi-distro apt/pacman)

Configs personales enlazadas a `$HOME` con GNU Stow. Idioma: **español** (comentarios, docs, commits).
Rama de trabajo: `dotfiles-layers`. Convención de commits y flujo git: skill `git` (Conventional Commits
en español, firma SSH activa; no usar `--no-gpg-sign`).

## Regla de oro: editá el archivo real, no el symlink

Cadena de dos saltos: `~/.config/x` → `stow/<capa>/<pkg>/.config/x` → `config/x`.

- Casi todo se edita en `config/`. Ese árbol **no** replica `$HOME`
  (ej. `stow/shared/kitty/.config/kitty/kitty.conf → config/kitty.conf`).
- **Excepciones que viven enteras en `stow/`** (archivos reales, se editan ahí): `rofi`, `opencode`,
  `hypr`, `waybar`, `dunst` y `kde/plasma`.
- Para saber cuál es el archivo real: `readlink -f ~/.config/loquesea`; si resuelve a `config/…`, editá eso.
- No todo `~/.config` es repo: `~/.config/opencode/{agents,skills/codebase-memory,service.json}` y
  `~/.config/kitty` son directorios reales con symlinks por archivo.

## Capas

Precedencia (la última gana): `stow/shared` < `stow/os/<id>` < `stow/wm/<de>` < `stow/host/<hostname>`.

- Presentes: `shared` (shell, nvim, terminales, rofi, opencode) y `wm` (`hyprland`: hypr/waybar/dunst;
  `kde`: plasma). `os/` y `host/` todavía no existen.
- Detección automática: `/etc/os-release`, `XDG_CURRENT_DESKTOP` (fallback `pgrep`), `hostname`. Si el
  directorio de capa no existe, se omite: no hardcodees capas en scripts.

## Comandos

- `make check` → valida symlinks; exit 0 = OK. **Corrélo después de tocar cualquier config.**
- `make lint` → shellcheck (severity=warning) sobre `install.sh`, `link.sh`, `check.sh`, `scripts/*.sh`
  y `config/colors/palette.sh`.
- `make link` → aplica stow; `make link-fix` → repara conflictos con backups `*.bak.<ts>`.
- `./link.sh shell nvim` → aplica paquetes sueltos (los busca en la última capa donde existan).
- `make palette` → regenera colores; `make backup` → copia `config/` a `/tmp`.
- **No corras `make install` / `make install-all`** sin pedido explícito: es interactivo, usa `sudo`,
  instala paquetes y re-aplica stow. Para enlazar usá `make link`.
- No hay tests: la verificación es `make check` (+ `make lint`, + `make palette` si tocaste colores).

## Trampas

- **`check.sh` valida solo listas hardcodeadas** (`SHELL_LINKS`, tablas `TERMINAL_*`, lista de opencode,
  bloque KDE). Si agregás un archivo validable, sumalo ahí: un `make check` verde no prueba un paquete nuevo.
- `check.sh` termina con `exit $errors`: los warnings ("No aplicado: ghostty/wezterm") no fallan.
- **Stow condicional**: `link.sh` salta un paquete si falta su binario (tabla `REQUIREMENTS`); un
  "no aplicado" puede ser esperado.
- `--fix` solo resuelve archivos, symlinks rotos y directorios vacíos; un directorio con contenido se
  avisa y se deja para resolución manual.
- Los `*.bak.<ts>` son backups intencionales; no los borres sin preguntar.
- El repo necesita un FS con symlinks (ext4/btrfs/xfs); en exFAT/NTFS el checkout queda incompleto.

## Agregar configs

1. Archivo real en `config/…`.
2. Symlink **relativo** en `stow/<capa>/<pkg>/…` apuntando a `config/…` (no hace falta replicar `$HOME`).
3. `make link` y `make check`; si debe validarse, actualizá `check.sh`.
4. Commit con el scope del área (`feat(kitty): …`).

## Generado

- `config/colors/{kitty-colors.conf,alacritty-colors.toml,ghostty-colors}` se generan desde
  `config/colors/palette.sh`: editá la fuente y corré `make palette`, nunca los archivos generados.
- Lockfiles de nvim (`lazy-lock.json`, `bun.lock`, `package-lock.json`) se actualizan con sus herramientas.

## Git y CI

- Hooks versionados activos (`core.hooksPath=.githooks`; en un clon nuevo: `git config core.hooksPath .githooks`).
  `post-checkout`/`post-merge` corren `check.sh`; no usar `--no-verify`.
- CI (`.github/workflows/shellcheck.yml`) solo corre en push a `main` y en PRs: en `dotfiles-layers`,
  `make lint` local es la única barrera antes de pushear.

## Estilo

`set -euo pipefail`; shellcheck severity=warning (`.shellcheckrc`); 2 espacios (`.editorconfig`), tabs en Makefile.
