# Guía para la defensa oral

## Demostración

1. Mostrar TPVMCA y su tercer disco de 10 GiB en VirtualBox.
2. Conectarse por SSH desde Windows. Explicar que la contraseña root requerida sirve en consola; SSH usa la clave privada del cliente y la pública autorizada en el servidor.
3. Mostrar `hostnamectl`, `ip -4 address show enp0s3`, `ip route` y `/etc/network/interfaces`. Explicar la limitación de no tener una reserva DHCP.
4. Mostrar `lsblk -f`, `fdisk -l /dev/sdc`, `/etc/fstab` y `findmnt`. Distinguir los discos originales del nuevo.
5. Abrir la página desde Windows. Explicar: Apache recibe HTTP, PHP ejecuta index.php, mysqli consulta MariaDB y devuelve HTML con los datos.
6. Mostrar `/etc/cron.d/tp-backup`, la ayuda del script, las copias existentes y `/var/log/tp-backup.log`.
7. Listar un tar y extraerlo en una carpeta temporal. Comparar el archivo restaurado; no restaurar directamente sobre el sitio durante la defensa.
8. Mostrar el repositorio, el diagrama y los hashes de las exportaciones.

## Preguntas para practicar

**¿Por qué puente?** Permite que la VM participe de la red física y sea accesible por su IP. NAT necesitaría configuración adicional para conexiones entrantes.

**¿Para qué sirven dirección, máscara y gateway?** La dirección identifica la interfaz, la máscara delimita la red local y el gateway permite alcanzar otras redes. DNS resuelve nombres.

**¿Por qué UUID?** Identifica el sistema de archivos aunque cambie el orden de enumeración de discos; `/dev/sdX` puede cambiar.

**¿Qué es tipo 83?** El identificador Linux en una tabla MBR. No equivale a ext4: el formateo se realiza por separado.

**¿Partición, sistema de archivos y montaje?** La partición delimita espacio, ext4 organiza archivos y el montaje conecta ese sistema con un directorio.

**¿Por qué verificar el montaje?** Un directorio puede existir aunque su partición esté desmontada. Sin comprobarlo, el backup podría llenar el disco raíz.

**¿Cómo funciona SSH con claves?** El servidor conserva la clave pública y el cliente demuestra que posee la privada sin enviarla. Los permisos protegen la autorización y la clave.

**¿Por qué no copiar todo /proc?** Es información virtual y dinámica del kernel, con entradas que no funcionan como archivos comunes. Se entregó una captura seleccionada y documentada.

**¿Es atómico un backup de logs?** No. Los servicios pueden escribir durante la lectura. El script comunica esa situación; gzip válido no significa que todos los archivos reflejen un mismo instante.

**¿Cómo se respaldó MariaDB?** Con un dump lógico de ingenieria. Además, MariaDB se detuvo durante la copia completa de /var. La versión publicada usa el dump y excluye los archivos internos de la base.

**¿Cómo se comprobó el backup?** Con gzip, listado del tar, extracción temporal y comparación del archivo del sitio con el original.

**¿Qué significan los campos cron?** Minuto, hora, día del mes, mes y día de la semana; en /etc/cron.d siguen el usuario y el comando. `0 23 * * 1,3,5` corresponde a lunes, miércoles y viernes a las 23:00.

**¿Qué falta?** Logo original, datos administrativos y acceso del docente. Explicar las limitaciones de DHCP, procfs y exportaciones sin ocultarlas.
