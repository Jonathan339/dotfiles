---
name: paleta
description: "Pipeline de colores del entorno (paleta Solo Leveling): config/colors/palette.sh es la fuente única y `make palette` regenera los formatos de kitty, alacritty y ghostty. Usar al cambiar colores o temas, o tocar cualquier archivo de colors/."
---

# Paleta — colores del entorno

Fuente única: **`config/colors/palette.sh`** (repo `~/.dotfiles`). Todo lo demás se **genera**.

## Flujo

1. Editar solo `config/colors/palette.sh` (variables `PALETTE_*`: BG, FG, cursor, selección, COLOR0–15, accent, tabs).
2. Regenerar: `make palette` (corre `scripts/generate-palette.sh`).
3. Verificar: `make check`.
4. Commit con convención (ej. `feat(palette): ...` o `style(palette): ...`).

## Archivos generados (NO editar a mano)

| Archivo | Consumidor |
|---|---|
| `config/colors/kitty-colors.conf` | kitty (`kitty.conf` lo incluye vía `include colors/kitty-colors.conf`) |
| `config/colors/alacritty-colors.toml` | alacritty |
| `config/colors/ghostty-colors` | ghostty |

Si editás un generado, el cambio se pierde en la próxima regeneración. Cualquier ajuste va en `palette.sh`.

## Notas

- Mantené la cabecera "generado por scripts/generate-palette.sh" de los archivos generados.
- Otros consumidores de color (rofi, waybar, lualine, etc.) pueden tener su propio manejo: revisá antes de asumir que la paleta los alcanza.
- Para ver el cambio, recargá o reiniciá el terminal (depende del terminal y de si tenés remote control activo).
