SUMMARY = "Odoo POS Icon Picker Module"
DESCRIPTION = "Custom Odoo module from itcomercio/odoo-modules to allow icon picking in the POS UI."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

# Apunta al repositorio principal y especifica la rama 'main'
SRC_URI = "git://github.com/itcomercio/odoo-modules.git;protocol=https;branch=main"

# Siempre usa la última revisión de la rama 'main'
SRCREV = "${AUTOREV}"

inherit skip-fakeroot-tar

# El código fuente se clonará en ${WORKDIR}/git
# S = "${WORKDIR}/git" # Esta línea es incorrecta en versiones modernas de Yocto

# Función para instalar el módulo en el path de addons persistente
do_install() {
    # Ruta de destino en la imagen final (coincide con IOTBOX_ADDONS_DEST en iotbox.bb)
    install -d ${D}${localstatedir}/lib/odoo/custom_addons/pos_icon_picker

    # Copia el contenido del módulo desde el directorio fuente clonado
    cp -r ${S}/pos_icon_picker/* ${D}${localstatedir}/lib/odoo/custom_addons/pos_icon_picker/
}

# Especifica los ficheros que este paquete instala.
FILES:${PN} += "${localstatedir}/lib/odoo/custom_addons/pos_icon_picker"
