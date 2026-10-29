#!/bin/bash
# Exporta copias completas locales y una version revisada para GitHub.
set -Eeuo pipefail
umask 077
[[ $EUID -eq 0 ]] || exit 1
salida=/home/entrega-tp
[[ ! -e "$salida" ]] || { echo 'La salida ya existe; revisar antes de repetir' >&2; exit 1; }
mkdir -p "$salida/completos" "$salida/repositorio" "$salida/proc-snapshot/proc/net"
mountpoint -q /www_dir
mountpoint -q /backup_dir
mariadb-dump --single-transaction --databases ingenieria > /var/backups/ingenieria.sql
chmod 600 /var/backups/ingenieria.sql
for nombre in partitions mounts meminfo cpuinfo version uptime stat loadavg filesystems swaps; do
    cat "/proc/$nombre" > "$salida/proc-snapshot/proc/$nombre"
done
cat /proc/partitions > "$salida/proc-snapshot/proc/particion"
cat /proc/net/route > "$salida/proc-snapshot/proc/net/route"
cat /proc/net/dev > "$salida/proc-snapshot/proc/net/dev"
cat > "$salida/proc-snapshot/proc/LEEME.txt" <<'EOF'
Instantanea de informacion legible de proc. No es una copia integral del sistema
virtual del kernel. particion contiene la misma captura que partitions.
No se ha creado un archivo real /proc/particion, porque procfs no lo admite.
EOF
tar -czf "$salida/completos/proc.tar.gz" -C "$salida/proc-snapshot" proc

# Detener escrituras de servicios durante la captura de /var.
trap 'systemctl start mariadb apache2 cron' EXIT
systemctl stop cron apache2 mariadb
for nombre in root etc opt www_dir backup_dir; do
    tar -czf "$salida/completos/$nombre.tar.gz" -C / "$nombre"
done
estado=0
tar --warning=no-file-changed -czf "$salida/completos/var.tar.gz" -C / var || estado=$?
[[ $estado -le 1 ]] || exit "$estado"

tar --exclude='root/.bash_history' --exclude='root/.viminfo' --exclude='root/.ssh' \
    --exclude='root/.mysql_history' --exclude='root/.my.cnf' \
    -czf "$salida/repositorio/root.tar.gz" -C / root
tar --exclude='etc/shadow*' --exclude='etc/gshadow*' \
    --exclude='etc/ssh/ssh_host_*_key' --exclude='etc/ssl/private' \
    --exclude='etc/mysql/debian.cnf' -czf "$salida/repositorio/etc.tar.gz" -C / etc
for nombre in opt www_dir backup_dir proc; do
    cp "$salida/completos/$nombre.tar.gz" "$salida/repositorio/"
done
estado=0
tar --warning=no-file-changed --exclude='var/lib/mysql' --exclude='var/cache/apt/archives' \
    --exclude='var/lib/systemd/random-seed' --exclude='var/backups/shadow*' --exclude='var/backups/gshadow*' \
    -czf "$salida/var-publicable.tar.gz" -C / var || estado=$?
[[ $estado -le 1 ]] || exit "$estado"
split -b 10M -d -a 3 "$salida/var-publicable.tar.gz" "$salida/repositorio/var.tar.gz.part-"
systemctl start mariadb apache2 cron
trap - EXIT
for archivo in "$salida/completos/"*.tar.gz "$salida/repositorio/"*.tar.gz; do
    gzip -t "$archivo"
done
cat "$salida/repositorio/"var.tar.gz.part-* | gzip -t
(cd "$salida/completos" && sha256sum *.tar.gz > SHA256SUMS)
(cd "$salida/repositorio" && sha256sum *.tar.gz var.tar.gz.part-* > SHA256SUMS)
du -h "$salida/completos/"* "$salida/repositorio/"*
