---
name: git
description: "Convención de commits y flujo git de este entorno. Usar SIEMPRE para tareas de git: hacer commit, pushear o subir cambios, staging, mensajes de commit, ramas, historial, conflictos. Commit convention: Conventional Commits con descripción en español."
---

# Git — convención y flujo

## Convención de commits (obligatoria, siempre)

Formato **Conventional Commits**, descripción en **español**: `tipo(scope): descripción`

- **Tipos**: `feat`, `fix`, `chore`, `docs`, `refactor`, `perf`, `test`, `ci`, `build`, `style`.
- **Scope** = área tocada, en minúsculas: `opencode`, `shell`, `nvim`, `kitty`, `alacritty`, `hypr`, `rofi`, `link`, `check`, `git`, `arch`, `fonts`, `terminales`, `palette`, etc.
- Descripción breve, minúscula inicial, sin punto final, **una sola línea** (el historial no usa cuerpo ni emojis).
- Un commit = un cambio lógico y completo. No mezclar temas distintos en el mismo commit.
- Ejemplos reales del historial:
  - `feat(opencode): integrar codebase-memory-mcp (MCP + plugin + AGENTS)`
  - `chore(shell): agregar ~/.local/bin al PATH para codebase-memory-mcp`
  - `fix(link): no tocar archivos fuente alcanzados por directorios plegados`
  - `docs: actualizar README (capas, paquetes reales, notas Arch)`

## Firma de commits

- La firma SSH está activa (`commit.gpgsign=true`, `gpg.format=ssh`). **No** desactivarla ni usar `--no-gpg-sign`.
- Verificar después de cada commit: `git log --format='%G? %h %s' -1` -> debe mostrar `G`.

## Flujo estándar

1. `git status --short` y `git diff` — ver el alcance real de los cambios.
2. `git fetch origin` y comparar: `git status -sb` y `git rev-list --left-right --count origin/<rama>...HEAD`.
3. Stage selectivo: `git add <paths>`; nunca `git add -A` a ciegas.
4. Commit con la convención de arriba.
5. `git push origin HEAD` y confirmar que quedó sincronizado (`0 0`, sin ahead/behind).

Sin pedido explícito, nunca: `push --force`, `commit --amend` sobre commits ya pusheados, `--no-verify`.
Nunca commitear secretos: claves SSH, tokens, `service.json`, cookies, `.env`.

## Contexto del entorno

- Dotfiles: `~/.dotfiles` — remoto SSH `github.com:Jonathan339/dotfiles.git`; rama de trabajo actual `dotfiles-layers`.
- Los archivos reales de config viven en `config/` (stow los linkea); tras tocar configs, correr `make check`.
- Copia en `Disco exter/.dotfiles` (exFAT): los `D` de symlinks son estado normal ahí; no commitear ni pushear desde esa copia sin revisar.
