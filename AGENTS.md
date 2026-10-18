# AGENTS.md — Dotfiles (workstation Ubuntu, gestionado con GNU Stow)

Idioma del repo: comentarios, docs y mensajes en **español**. Mantené ese estilo.

## Modelo de capas (crítico)
Precedencia (la última gana): `stow/shared` < `stow/os/<id>` < `stow/wm/<de>` < `stow/host/<hostname>`.
`link.sh`/`check.sh` las detectan solas: OS por `/etc/os-release` (`ID`/`ID_LIKE`), WM por `XDG_CURRENT_DESKTOP`
(con fallback a `pgrep Hyprland` / `pgrep xfce4-session`), host por `hostname`. No hardcodees capas.

**Dos niveles de symlink — editá solo `config/`:**
- Los archivos reales viven en `config/`.
- `stow/<capa>/<pkg>/…` son symlinks hacia `config/…` (los mantiene el repo).
- Stow crea los symlinks finales desde `$HOME` hacia `stow/`.
Nunca edites dentro de `stow/` ni el symlink de `$HOME`: tocá `config/`.

## Comandos (usá el Makefile)
- `make install` / `make install-all` → `./install.sh [--all]`. Instalador por menú; modo `--copy` copia en vez de stow.
- `make link` → `./link.sh` (aplica stow); `make link-fix` → `./link.sh --fix` (repara conflictos creando backups `*.bak.<ts>`).
- `make check` → `./check.sh` valida symlinks; exit 0 = OK. **Corré `make check` después de tocar configs.**
- `make palette` → regenera colores (ver "Paleta").
- `make lint` → `shellcheck` sobre `install.sh link.sh check.sh scripts/*.sh config/shell/path.sh config/colors/palette.sh`.
- `make backup` → copia `config/` a `/tmp/dotfiles-backup-<ts>`.

Verificación tras cambios: `make lint && make palette` (si tocaste colores) `&& make check`.

## Quirks que un agente suele errar
- **Paleta**: fuente única = `config/colors/palette.sh`. Los `kitty-colors.conf`, `alacritty-colors.toml` y `ghostty-colors` (en `config/colors/`) son **GENERADOS**. Editá `palette.sh` y corré `make palette`; no edites los generados.
- **Stow condicional**: `link.sh` salta un paquete si falta su comando (tabla `REQUIREMENTS`), p.ej. no aplica `kitty` si `kitty` no está instalado. Un paquete "no aplicado" puede ser esperado.
- **Git hooks activos** (`core.hooksPath=.githooks`): `post-checkout` y `post-merge` corren `check.sh` y avisan `./link.sh --fix` si hay symlinks rotos. No los saltees.
- **Config de opencode** vive en `stow/shared/opencode/.config/opencode/` (symlinkeada a `~/.config/opencode`); su `AGENTS.md` es el bloque de `codebase-memory-mcp`.
- **Neovim**: lazy.nvim modular en `config/nvim/lua/` (`config/` + `plugins/`). Lockfiles versionados: `lazy-lock.json`, `bun.lock`, `package-lock.json`.
- **Estilo shell**: `set -euo pipefail`; shellcheck con `.shellcheckrc` (severity=warning); 2 espacios (`.editorconfig`), tabs en Makefile.
- **Multi-distro**: `install.sh` soporta apt (Debian/Ubuntu) y pacman (Arch); las funciones solo-apt usan `warn_pm` para saltarse en otros gestores.
- README tiene troubleshooting de marcadores de merge (`<<<<<<<`) que rompen `install.sh`.
