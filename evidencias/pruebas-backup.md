# Pruebas de backup — 29 de octubre de 2026

Ejecutadas sobre TPServer mediante `verificar_backup.sh`.

| Prueba | Resultado |
|---|---|
| Sintaxis Bash y -help | Correctos |
| Faltan argumentos | Rechazo |
| Origen inexistente | Rechazo |
| Destino /tmp | Rechazo |
| /backup_dir desmontado en namespace aislado | Rechazo antes de copiar |
| /www_dir desmontado en namespace aislado | Rechazo antes de copiar |
| Montajes reales tras las pruebas | Ambos presentes |
| Copia de /www_dir | Generada |
| gzip -t | Correcto |
| Segunda copia con mismo nombre y fecha | Rechazo; no reemplaza la anterior |
| Restauración y comparación de index.php | Archivos idénticos |
| Backups de cron | Dos archivos observados; gzip válido |

Restauración: `/tmp/restauracion-tp.xXy3G9`. Copia de prueba: `/backup_dir/prueba-backup.HzrDVu/`.

El backup de logs registró que archivos cambiaron durante la lectura. El script conserva el archivo verificable, advierte y devuelve código 1; no se presenta como una instantánea atómica. El logo no se probó porque todavía no está disponible.
