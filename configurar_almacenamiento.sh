#!/bin/bash
# Ejecutar UNA VEZ en la VM TPVMCA preparada para este trabajo.
# El numero de serie fija inequívocamente el disco nuevo de esta instalación.
set -Eeuo pipefail
[[ $EUID -eq 0 && $(hostname) == TPServer ]] || exit 1
disco=/dev/sdc
[[ $(lsblk -dn -o SERIAL "$disco") == VBde107bc3-d2f76d9d ]] || { echo 'Disco distinto del esperado' >&2; exit 1; }
[[ $(blockdev --getsize64 "$disco") -eq 10737418240 ]] || exit 1
[[ $(lsblk -nr -o NAME "$disco" | wc -l) -eq 1 ]] || { echo 'El disco ya tiene particiones' >&2; exit 1; }
[[ -z $(wipefs -n "$disco") ]] || { echo 'El disco contiene firmas existentes' >&2; exit 1; }
for ruta in /www_dir /backup_dir; do
    [[ ! -e "$ruta" ]] || { echo "El directorio ya existe: $ruta" >&2; exit 1; }
done
sfdisk "$disco" <<'EOF'
label: dos
unit: sectors

start=2048, size=6291456, type=83
size=12582912, type=83
EOF
udevadm settle
mkfs.ext4 -L www_dir /dev/sdc1
mkfs.ext4 -L backup_dir /dev/sdc2
mkdir /www_dir /backup_dir
cp -a /etc/fstab /etc/fstab.tp-original
printf '\n# Particiones del trabajo practico\n' >> /etc/fstab
printf 'UUID=%s /www_dir ext4 defaults 0 2\n' "$(blkid -s UUID -o value /dev/sdc1)" >> /etc/fstab
printf 'UUID=%s /backup_dir ext4 defaults 0 2\n' "$(blkid -s UUID -o value /dev/sdc2)" >> /etc/fstab
systemctl daemon-reload
mount /www_dir
mount /backup_dir
chmod 755 /www_dir
chmod 700 /backup_dir
findmnt --verify --verbose
lsblk -f
