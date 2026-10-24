# Capa KDE Plasma (`wm/kde`)

Se activa sola cuando `XDG_CURRENT_DESKTOP=KDE` (fallback: `pgrep plasmashell`).
Precedencia: `shared` < `os/<so>` < `wm/kde` < `host/<hostname>`.

## Paquete `plasma`

| Archivo | Qué controla |
|---|---|
| `~/.config/kxkbrc` | Disposiciones de teclado de KWin. `latam` **sin variante** → teclas muertas activas (`´` + `o` = ó). |
| `~/.config/kcminputrc` | Teclado: repetición (40/s, 250 ms) y NumLock al iniciar. |

KConfig escribe sobre el symlink en vez de reemplazarlo (verificado con
`kwriteconfig6`), así que lo que cambies desde Configuración del sistema queda
reflejado en este repo: `git diff` lo muestra.

## Qué no se versiona (a propósito)

- `kwinrc`, `kglobalshortcutsrc`, `kdeglobals`, `plasma-org.kde.plasma.desktop-appletsrc`:
  Plasma los reescribe seguido (estado de ventanas, atajos, panel) y generan ruido.
- Las secciones `[Libinput][vendor][product][nombre]` de `kcminputrc` (touchpad/ratón):
  son específicas de cada equipo, van mejor en `stow/host/<hostname>`.

## Cómo agregar un archivo

1. Copiarlo a `stow/wm/kde/plasma/.config/…` (mismo árbol relativo a `$HOME`).
2. `./link.sh plasma` para stowearlo.
3. `make check`.

## Notas

- Si corrés `make link` desde otra sesión (por ejemplo SSH), exportá
  `XDG_CURRENT_DESKTOP=KDE` para que se detecte la capa.
- `kxkbrc` y `kcminputrc` también se pueden editar desde Configuración del sistema →
  Dispositivos de entrada.
