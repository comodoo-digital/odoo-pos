Dos ficheros, el original con la seccion [Service] y un segundo fichero con la misma seccion [Service]. Cual se aplica?

En systemd, lo que estás viendo es un mecanismo nativo de herencia y personalización llamado Drop-in files (o ficheros de extensión).

La respuesta corta es: Se aplican ambos, pero el fichero de /etc/... tiene la última palabra. No es que uno anule por completo al otro, sino que se fusionan, y en caso de conflicto, los valores del fichero en /etc sobrescriben a los de /usr.

El orden exacto en el que systemd lee y procesa la configuración es el siguiente:

El Orden de Preferencia (Jerarquía de carpetas)
systemd busca y carga la configuración de abajo hacia arriba en esta jerarquía:

1. /usr/lib/systemd/system/triggerhappy.service Es el archivo de servicio principal proporcionado por el paquete o la receta de Yocto. Se considera la configuración "de fábrica" o por defecto.

2. /etc/systemd/system/triggerhappy.service.d/99-run-as-root.conf Es el archivo drop-in. Los archivos dentro de /etc están pensados para que el administrador del sistema (o una receta de Yocto que personalice la imagen) añada o modifique configuraciones sin tocar el archivo principal de /usr.

¿Cómo se fusiona la sección [Service]?
Cuando systemd arranca el servicio, junta las secciones [Service] de ambos archivos aplicando estas reglas:

Propiedades de valor único (ej. User=, Group=, Type=): El archivo drop-in de /etc sobrescribe por completo al de /usr. Si el archivo principal dice User=nobody y tu archivo 99-run-as-root.conf dice User=root, el servicio se ejecutará como root.

Propiedades de lista (ej. ExecStart=, Environment=): Estas propiedades se acumulan, a menos que las vacíes explícitamente. Por ejemplo, si intentas cambiar el comando de arranque (ExecStart), necesitas vaciarlo primero en el drop-in, de lo contrario systemd intentará ejecutar ambos comandos y dará un error.

Ejemplo de cómo lo interpreta systemd:
Si tu archivo principal en /usr/lib/... tiene:

Ini, TOML
[Service]
Type=simple
ExecStart=/usr/sbin/thd --udev /dev/input/event*
User=nobody
Y tu archivo en /etc/.../.d/99-run-as-root.conf tiene:

Ini, TOML
[Service]
User=root
El resultado final que aplica systemd en memoria será:

Ini, TOML
[Service]
Type=simple
ExecStart=/usr/sbin/thd --udev /dev/input/event*
User=root  <-- Ganó el drop-in de /etc