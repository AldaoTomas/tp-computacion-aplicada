#!/bin/bash
# Instalar en /opt/scripts/backup_full.sh y ejecutar con Bash.
set -Eeuo pipefail
umask 077

ayuda() {
    cat <<'EOF'
Uso: backup_full.sh ORIGEN DESTINO
     backup_full.sh -help

Comprime un directorio en nombre_bkp_YYYYMMDD.tar.gz.
DESTINO debe estar dentro de la particion montada en /backup_dir.
Ejemplo: backup_full.sh /www_dir /backup_dir
Ejemplo: backup_full.sh /var/log /backup_dir
No reemplaza un backup existente del mismo origen y fecha.
EOF
}

fallar() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
if [[ $# -eq 1 && ( "$1" == '-help' || "$1" == '--help' ) ]]; then
    ayuda
    exit 0
fi
[[ $# -eq 2 ]] || { ayuda >&2; exit 2; }
for comando in realpath findmnt mountpoint tar date mktemp flock mv; do
    command -v "$comando" >/dev/null || fallar "Falta el comando $comando"
done
origen=$(realpath -e -- "$1") || fallar 'El origen no existe'
destino=$(realpath -e -- "$2") || fallar 'El destino no existe'
[[ -d "$origen" && -r "$origen" && -x "$origen" ]] || fallar 'Origen no accesible'
[[ -d "$destino" && -w "$destino" && -x "$destino" ]] || fallar 'Destino no escribible'
[[ "$origen" != '/' ]] || fallar 'Indicar un directorio concreto como origen'
[[ "$destino/" != "$origen/"* ]] || fallar 'El destino no puede estar dentro del origen'

# Evitar una copia silenciosa al disco raiz cuando falta la particion.
mountpoint -q /backup_dir || fallar '/backup_dir no esta montado'
[[ "$destino" == '/backup_dir' || "$destino" == /backup_dir/* ]] || fallar 'Destino fuera de /backup_dir'
findmnt -n -T "$origen" >/dev/null || fallar 'Sistema de archivos de origen no disponible'
findmnt -n -T "$destino" >/dev/null || fallar 'Sistema de archivos de destino no disponible'

# Detectar montajes configurados pero ausentes en el origen o sus ancestros.
actual="$origen"
while [[ "$actual" != '/' ]]; do
    if findmnt --fstab -n -M "$actual" >/dev/null 2>&1; then
        mountpoint -q "$actual" || fallar "Montaje de origen ausente: $actual"
    fi
    actual=$(dirname -- "$actual")
done
if [[ "$origen" == '/www_dir' || "$origen" == /www_dir/* ]]; then
    mountpoint -q /www_dir || fallar '/www_dir no esta montado'
fi

# Serializar ejecuciones, incluidas las iniciadas por cron.
exec 9> /backup_dir/.backup_full.lock
flock -n 9 || fallar 'Ya hay un backup en ejecucion'
nombre=$(basename -- "$origen")
archivo="$destino/${nombre}_bkp_$(date +%Y%m%d).tar.gz"
[[ ! -e "$archivo" ]] || fallar "Ya existe: $archivo"
temporal=$(mktemp "$destino/.backup_full.XXXXXX")
trap 'rm -f -- "$temporal"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# GNU tar devuelve 1 si un archivo cambia durante la lectura (habitual en logs).
estado=0
tar -czf "$temporal" -C "$(dirname -- "$origen")" -- "$nombre" || estado=$?
if [[ "$estado" -gt 1 ]]; then
    fallar "tar fallo (codigo $estado); no se publica el archivo incompleto"
fi
tar -tzf "$temporal" >/dev/null || fallar 'No se pudo verificar el archivo comprimido'
mv -- "$temporal" "$archivo"
printf 'Backup generado: %s\n' "$archivo"
if [[ "$estado" -eq 1 ]]; then
    printf 'ADVERTENCIA: hubo archivos que cambiaron durante la copia; revisar mensajes de tar.\n' >&2
    exit 1
fi
