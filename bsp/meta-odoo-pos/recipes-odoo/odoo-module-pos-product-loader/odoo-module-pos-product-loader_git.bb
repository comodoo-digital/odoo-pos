SUMMARY = "Odoo POS Product Loader Module"
DESCRIPTION = "Custom Odoo module from comodoo-digital/odoo-modules for advanced product loading in POS."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

# Apunta al repositorio principal y especifica la rama 'main'
SRC_URI = "git://github.com/comodoo-digital/odoo-modules.git;protocol=https;branch=main"

# Siempre usa la última revisión de la rama 'main'
SRCREV = "${AUTOREV}"

inherit skip-fakeroot-tar

# Función para instalar el módulo en el path de addons persistente
do_install() {
    # Ruta de destino en la imagen final (coincide con IOTBOX_ADDONS_DEST en iotbox.bb)
    install -d ${D}${localstatedir}/lib/odoo/custom_addons/pos_product_loader

    # Copia el contenido del módulo desde el directorio fuente clonado
    cp -r ${S}/pos_product_loader/* ${D}${localstatedir}/lib/odoo/custom_addons/pos_product_loader/
}

# Especifica los ficheros que este paquete instala.
FILES:${PN} += "${localstatedir}/lib/odoo/custom_addons/pos_product_loader"
