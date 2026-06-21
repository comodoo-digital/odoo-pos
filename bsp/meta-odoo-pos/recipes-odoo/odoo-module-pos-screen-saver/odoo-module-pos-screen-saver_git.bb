SUMMARY = "Odoo POS Screen Saver Module"
DESCRIPTION = "Custom Odoo module from comodoo-digital/odoo-modules to add a screen saver in the POS UI."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

# Apunta al repositorio principal y especifica la rama 'main'
SRC_URI = "git://github.com/comodoo-digital/odoo-modules.git;protocol=https;branch=main"

# Siempre usa la ultima revision de la rama 'main'
SRCREV = "${AUTOREV}"

inherit skip-fakeroot-tar

# Funcion para instalar el modulo en el path de addons persistente
do_install() {
    # Ruta de destino en la imagen final (coincide con IOTBOX_ADDONS_DEST en iotbox.bb)
    install -d ${D}${localstatedir}/lib/odoo/custom_addons/pos_screen_saver

    # Copia el contenido del modulo desde el directorio fuente clonado
    cp -r ${S}/pos_screen_saver/* ${D}${localstatedir}/lib/odoo/custom_addons/pos_screen_saver/
}

# Especifica los ficheros que este paquete instala.
FILES:${PN} += "${localstatedir}/lib/odoo/custom_addons/pos_screen_saver"
