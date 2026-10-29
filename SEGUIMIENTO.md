# Seguimiento final — 29 de octubre de 2026

Implementación y pruebas completadas en TPVMCA/TPServer. El detalle técnico actualizado está en README.md; esta lista reemplaza el seguimiento preliminar.

- VM importada, root recuperado y hostname configurado.
- SSH con clave verificado desde Windows.
- Apache/PHP y MariaDB funcionando; 15 registros visibles.
- IP estática 192.168.1.211/24, gateway/DNS 192.168.1.1; sin reserva DHCP en el router.
- Tercer disco de 10 GiB con particiones MBR tipo 83 de 3 GiB y 6 GiB, ext4 y fstab por UUID.
- Persistencia de red, montajes y servicios verificada después de reiniciar.
- Script backup_full.sh probado, incluyendo restauración y montajes ausentes simulados sin afectar los montajes reales.
- Ejecuciones reales de cron observadas a las 23:00 y 00:00. Backup de logs válido con advertencia por archivos en modificación.
- Exportaciones completas guardadas en .local/exportaciones-completas del proyecto y /home/entrega-tp/completos de la VM.
- Exportaciones revisadas en Entrega/exportaciones, con /var dividido en partes de 10 MiB y SHA256SUMS verificado.
- Repositorio privado creado: https://github.com/AldaoTomas/tp-computacion-aplicada

## Pendientes del grupo

1. Descargar el logo.png original, instalarlo y actualizar evidencias/exportaciones afectadas.
2. Completar el apellido de Josefina y la fecha de entrega en README.md.
3. Dar acceso al docente al repositorio privado.
4. Confirmar con el docente la captura de /proc y las exportaciones con exclusiones. Las copias completas se conservan localmente.
5. Revisar la conectividad antes de la defensa, por no contar con reserva DHCP.

No se subieron la VM, los RAR ni la clave privada del material adicional.
