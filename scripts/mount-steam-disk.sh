#!/usr/bin/env bash
# Monta el disco WD (UUID fijo) en /mnt/steam de forma permanente para Steam.
# Uso (tras reinstalar o en una máquina nueva):
#   sudo bash ~/.dotfiles/scripts/mount-steam-disk.sh
# Requiere: el disco conectado. El UUID es único del disco, no cambia al formatear el SO.

set -euo pipefail

UUID="a75839fa-0548-4eef-afa3-0bbde5864b57"
MP="/mnt/steam"
OWNER="jonathan:jonathan"

if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse con sudo." >&2
    exit 1
fi

if ! blkid -U "$UUID" >/dev/null 2>&1; then
    echo "No se encontró el disco con UUID $UUID. ¿Está conectado?" >&2
    exit 1
fi

echo "Desmontando montajes previos del disco..."
while read -r dev mnt rest; do
    if [[ "$dev" == "UUID=$UUID" || "$dev" == "/dev/"* ]] && mountpoint -q "$mnt" 2>/dev/null; then
        :
    fi
done < /proc/mounts
# Desmontar cualquier punto que use este UUID
for mnt in $(findmnt -rn -S "UUID=$UUID" -o TARGET 2>/dev/null || true); do
    umount "$mnt" 2>/dev/null || true
done

echo "Creando punto de montaje $MP..."
mkdir -p "$MP"

echo "Respaldando /etc/fstab..."
cp /etc/fstab "/etc/fstab.bak.$(date +%s)"

echo "Limpiando entradas previas del UUID en /etc/fstab..."
grep -v "$UUID" /etc/fstab > /tmp/fstab.new || true
echo "UUID=$UUID $MP ext4 defaults,noatime 0 2" >> /tmp/fstab.new
cp /tmp/fstab.new /etc/fstab

echo "Montando $MP..."
mount "$MP"

echo "Asignando propiedad a $OWNER..."
chown -R "$OWNER" "$MP"

echo "Creando carpeta steamapps..."
mkdir -p "$MP/steamapps"
chown "$OWNER" "$MP/steamapps"

echo "Listo. Disco montado permanentemente en $MP"
