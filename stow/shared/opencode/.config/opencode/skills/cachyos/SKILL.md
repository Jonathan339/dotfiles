---
name: cachyos
description: "Mantenimiento del sistema CachyOS (Arch): actualizaciones con pacman, mirrors (cachyos-rate-mirrors/reflector), caché y huérfanos, systemd/journalctl y diagnóstico. Usar para updates, limpieza, errores del sistema o revisar logs."
---

# CachyOS / Arch — mantenimiento

Sistema: **CachyOS** (Arch-based), pacman. Hay `paccache`, `cachyos-rate-mirrors` y `reflector` instalados.
**No hay helper AUR** (`paru`/`yay` no están): si una tarea lo necesita, preguntar antes de instalar uno.

## Actualizaciones

- Update completo: `sudo pacman -Syu`. Nunca `-Sy` solo ni updates parciales.
- Antes de updates grandes, revisar noticias: https://archlinux.org/news/ (puede haber intervención manual).
- Después de update de kernel o drivers de video: reiniciar.
- Si aparecen `.pacnew`: resolver con `pacdiff`, sin pisar a ciegas.

## Mirrors y caché

- CachyOS: `sudo cachyos-rate-mirrors`.
- `reflector` también está disponible para regenerar la mirrorlist por tasa.
- Caché de paquetes: `paccache -r` (conserva 3 versiones) o `paccache -rk1` (más agresivo).
- Huérfanos: listar con `pacman -Qtdq`; limpiar con `sudo pacman -Rns $(pacman -Qtdq)` — revisar la lista antes.
- Journal: `journalctl --disk-usage`; recortar con `sudo journalctl --vacuum-time=2weeks` (o `--vacuum-size=500M`).

## Diagnóstico

- Unidades fallidas: `systemctl --failed`; detalle: `journalctl -u <unidad> -b`.
- Errores del boot actual: `journalctl -b -p err`; mensajes del kernel: `journalctl -k -b -p err`.
- Paquete dueño de un archivo: `pacman -Qo <ruta>`; contenido: `pacman -Ql <pkg>`; info: `pacman -Si <pkg>`.
- Integridad de archivos: `pacman -Qkk <pkg>`.

## Notas

- CachyOS trae herramientas y kernels propios (`linux-cachyos`, `cachyos-*`): si un comando no existe, verificarlo antes de asumir.
- Cuidado con scripts de terceros que hagan `pacman -Sy`: rompen la regla de no-updates-parciales.
- Logs de apps de usuario: `journalctl --user -u <unidad>` o el archivo de log del programa.
