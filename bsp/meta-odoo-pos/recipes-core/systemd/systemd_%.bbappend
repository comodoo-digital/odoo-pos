FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " file://logind.conf"

# Drop-in para systemd-logind. Por defecto, en Yocto los parametros del
# fichero /etc/systemd/logind.conf vienen comentados (sin efecto). En el
# kiosko POS queremos un comportamiento determinista de las teclas de
# energia y de la tapa del portatil:
#   - HandlePowerKey=poweroff  -> el boton de encendido apaga el equipo.
#   - HandleSuspendKey=ignore  -> ignorar la tecla de suspension.
#   - HandleHibernateKey=ignore-> ignorar la tecla de hibernacion.
#   - HandleLidSwitch=ignore   -> no suspender al cerrar la tapa.
#
# Usamos un drop-in en /etc/systemd/logind.conf.d/ (recomendado por systemd)
# en lugar de sobrescribir el fichero del paquete. El prefijo numerico 99
# garantiza que tiene prioridad sobre el drop-in 00-systemd-conf del paquete
# systemd-conf.
do_install:append() {
    install -d ${D}${sysconfdir}/systemd/logind.conf.d
    install -m 0644 ${UNPACKDIR}/logind.conf \
        ${D}${sysconfdir}/systemd/logind.conf.d/99-odoo-pos.conf
}

FILES:${PN} += "${sysconfdir}/systemd/logind.conf.d/99-odoo-pos.conf"
