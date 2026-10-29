#!/bin/bash
set -Eeuo pipefail
script=/opt/scripts/backup_full.sh
fallo_esperado() {
    if "$@"; then echo 'FALLO: se esperaba rechazo' >&2; exit 1; fi
}
bash -n "$script"
"$script" -help
fallo_esperado "$script"
fallo_esperado "$script" /origen-inexistente-tp /backup_dir
fallo_esperado "$script" /www_dir /tmp

# Desmontar solo en un espacio de montajes aislado; la VM conserva sus montajes.
unshare --mount bash -euc 'mount --make-rprivate /; umount /backup_dir; if /opt/scripts/backup_full.sh /www_dir /backup_dir; then exit 1; fi'
unshare --mount bash -euc 'mount --make-rprivate /; umount /www_dir; if /opt/scripts/backup_full.sh /www_dir /backup_dir; then exit 1; fi'
mountpoint -q /www_dir
mountpoint -q /backup_dir

destino=$(mktemp -d /backup_dir/prueba-backup.XXXXXX)
"$script" /www_dir "$destino"
archivo="$destino/www_dir_bkp_$(date +%Y%m%d).tar.gz"
gzip -t "$archivo"
fallo_esperado "$script" /www_dir "$destino"
restauracion=$(mktemp -d /tmp/restauracion-tp.XXXXXX)
tar -xzf "$archivo" -C "$restauracion"
cmp /www_dir/index.php "$restauracion/www_dir/index.php"
if [[ -f /www_dir/logo.png ]]; then cmp /www_dir/logo.png "$restauracion/www_dir/logo.png"; fi
printf 'OK: ayuda, argumentos, montajes ausentes, copia, integridad, duplicados y restauracion.\n'
printf 'Copia de prueba: %s\nRestauracion: %s\n' "$archivo" "$restauracion"
printf '\nBackups ejecutados por cron:\n'
find /backup_dir -maxdepth 1 -name '*_bkp_*.tar.gz' -type f -print -exec gzip -t {} \;
cat /var/log/tp-backup.log
