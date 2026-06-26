SUMMARY = "Storage durability hardening for the Odoo POS appliance"
DESCRIPTION = "Disables the volatile disk write cache (or forces write-through) \
on boot so that PostgreSQL fsync()/fdatasync() calls are honoured by the \
underlying SSD/eMMC. This prevents on-disk page corruption (e.g. 'invalid page \
in block N of relation') after an abrupt power-loss on consumer-grade storage \
without power-loss protection (PLP)."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# No tarball: all sources are file:// — S must point to UNPACKDIR
S = "${UNPACKDIR}"

# Workaround for Fedora Python 3.14 pseudo/fakeroot tar issue (matches other
# file-only recipes in this layer).
inherit systemd skip-fakeroot-tar

SRC_URI = " \
    file://disk-write-cache.sh \
    file://disk-write-cache.service \
"

# hdparm is the primary mechanism to disable the disk write cache (-W0).
RDEPENDS:${PN} = "hdparm"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "disk-write-cache.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${libexecdir}
    install -m 0755 ${UNPACKDIR}/disk-write-cache.sh ${D}${libexecdir}/disk-write-cache.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/disk-write-cache.service \
        ${D}${systemd_system_unitdir}/disk-write-cache.service
}

FILES:${PN} += " \
    ${libexecdir}/disk-write-cache.sh \
    ${systemd_system_unitdir}/disk-write-cache.service \
"
