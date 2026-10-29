#!/bin/bash
set -Eeuo pipefail
[[ $EUID -eq 0 && $(hostname) == TPServer ]] || exit 1
mountpoint -q /www_dir
mountpoint -q /backup_dir
cp -an /etc/hosts /etc/hosts.tp-original
sed -i 's/^127\.0\.1\.1.*/127.0.1.1\tTPServer/' /etc/hosts
hostnamectl set-hostname TPServer
timedatectl set-timezone America/Argentina/Buenos_Aires
install -d -m 755 /opt/scripts
install -m 750 /root/backup_full.sh /opt/scripts/backup_full.sh
install -m 644 /root/index.php /www_dir/index.php
if [[ -f /root/logo.png ]]; then install -m 644 /root/logo.png /www_dir/logo.png; fi
cp -an /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.tp-original
cat > /etc/apache2/sites-available/000-default.conf <<'EOF'
<VirtualHost *:80>
    ServerName TPServer
    DocumentRoot /www_dir
    DirectoryIndex index.php
    <Directory /www_dir>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
printf 'ServerName TPServer\n' > /etc/apache2/conf-available/tp-servername.conf
a2enconf tp-servername
systemctl enable --now mariadb
if ! mariadb -Nse 'SHOW DATABASES' | grep -qx ingenieria; then
    mariadb < /root/db.sql
fi
apache2ctl configtest
systemctl enable ssh apache2 mariadb cron
systemctl restart apache2

# La consigna nombra /var/logs y su ejemplo usa /var/log.
# Se conserva el origen literal de cron mediante un enlace al directorio real.
if [[ ! -e /var/logs && ! -L /var/logs ]]; then ln -s /var/log /var/logs; fi
[[ $(readlink -f /var/logs) == /var/log ]] || { echo 'Revisar /var/logs' >&2; exit 1; }
cat > /etc/cron.d/tp-backup <<'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 0 * * * root /opt/scripts/backup_full.sh /var/logs /backup_dir >> /var/log/tp-backup.log 2>&1
0 23 * * 1,3,5 root /opt/scripts/backup_full.sh /www_dir /backup_dir >> /var/log/tp-backup.log 2>&1
EOF
chmod 644 /etc/cron.d/tp-backup
cat > /etc/logrotate.d/tp-backup <<'EOF'
/var/log/tp-backup.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF
cp -an /etc/network/interfaces /etc/network/interfaces.tp-original
cat > /etc/network/interfaces <<'EOF'
source /etc/network/interfaces.d/*
auto lo
iface lo inet loopback

# ADDRESS, NETMASK y GATEWAY: campos de ifupdown en minusculas.
# Reservar 192.168.1.211 para MAC 08:00:27:55:9b:cc en el router.
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.211
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 192.168.1.1
EOF
printf 'nameserver 192.168.1.1\n' > /etc/resolv.conf
ifquery enp0s3

# /proc no permite crear archivos arbitrarios. Guardar evidencia persistente.
install -d -m 700 /root/evidencias/proc
cat /proc/partitions > /root/evidencias/proc/particion
cat /proc/partitions > /root/evidencias/proc/partitions
printf 'Configuracion aplicada. Reiniciar y comprobar persistencia de red y montajes.\n'
