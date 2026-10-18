---
name: dotfiles
description: "Flujo del repo de dotfiles (~/.dotfiles): capas stow, regla de archivos reales en config/, link/check/lint/backup, hooks y errores típicos. Usar al editar configs, agregar paquetes o capas, linkear, reparar symlinks rotos o correr make en el repo."
---

# Dotfiles — flujo del repo

Repo: `~/.dotfiles` (remoto `git@github.com:Jonathan339/dotfiles.git`; rama de trabajo actual `dotfiles-layers`).
Idioma del repo: español (comentarios, docs y commits — ver skill `git`).
El repo tiene su propio `AGENTS.md` con más detalle: leerlo si la tarea es grande.

## Modelo de capas (crítico)

Precedencia (la última gana): `stow/shared` < `stow/os/<id>` < `stow/wm/<de>` < `stow/host/<hostname>`.
`link.sh`/`check.sh` detectan solas la capa: OS por `/etc/os-release` (`ID`/`ID_LIKE`), WM por `XDG_CURRENT_DESKTOP` (fallback `pgrep Hyprland` / `pgrep xfce4-session`), host por `hostname`. **No hardcodees capas.**
Hoy existen `shared` (alacritty, ghostty, kitty, nvim, opencode, rofi, shell, wezterm) y `wm` (hyprland). Repo multi-distro: `install.sh` soporta apt y pacman.

## Regla de oro: no edites un symlink intermedio

- Los archivos reales viven en `config/`; en `stow/<capa>/<pkg>/…` hay **symlinks** hacia `config/…` (los mantiene el repo). Stow crea los symlinks finales desde `$HOME` hacia `stow/`.
- Para editar: tocá el archivo real de `config/`. No escribas dentro de `stow/` ni asumas que tocar `~/.config/...` edita el repo.
- Excepciones: algunos paquetes guardan los archivos reales directamente en `stow/` (hoy `opencode` y `rofi`; no existen `config/opencode` ni `config/rofi`).
- Ante la duda, seguí la cadena con `ls -la` hasta el archivo sin flechas y editá ese.

## Comandos (usá el Makefile)

| Comando | Qué hace |
|---|---|
| `make install` / `make install-all` | `./install.sh [--all]`; `--copy` copia en vez de stow |
| `make link` | `./link.sh` (aplica stow) |
| `make link-fix` | repara conflictos con backups `*.bak.<ts>` |
| `make check` | valida symlinks; exit 0 = OK — **correr siempre después de tocar configs** |
| `make palette` | regenera colores (ver skill `paleta`) |
| `make lint` | shellcheck sobre los scripts |
| `make backup` | copia `config/` a `/tmp/dotfiles-backup-<ts>` |

Verificación típica: `make check`; si tocaste colores, `make palette && make check`; si tocaste scripts shell, `make lint`.

## Quirks que no son errores

- **Stow condicional**: `link.sh` salta un paquete si falta su comando (tabla `REQUIREMENTS`). "No aplicado: ghostty/wezterm" sin esos programas instalados es esperado.
- **Git hooks activos** (`core.hooksPath=.githooks`): `post-checkout` y `post-merge` corren `check.sh` y sugieren `./link.sh --fix` si hay symlinks rotos. No los saltees.
- `~/.config/opencode` es un directorio real (no symlink): adentro conviven archivos del repo (AGENTS.md, JSONs, plugins) con cosas locales (skills/, agents/, service.json).
- `scripts/`: `generate-palette.sh` (colores, ver skill `paleta`) y `mkc.sh` (crea esqueletos de proyectos C/C++).

## Agregar un archivo o paquete

1. Crear el archivo real en `config/…`.
2. Si es nuevo, crear en `stow/<capa>/<pkg>/…` el symlink hacia `config/…` (mismo árbol relativo).
3. `make link` (si hay estructura nueva) y `make check`.
4. Commit con la convención del skill `git` (ej. `feat(kitty): ...`).

## Estilo

Shell con `set -euo pipefail`; shellcheck (`.shellcheckrc`, severity=warning); 2 espacios (`.editorconfig`), tabs en Makefile.
