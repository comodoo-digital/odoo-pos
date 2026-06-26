#!/bin/sh
# =============================================================================
# disk-write-cache.sh — Endurecimiento de la durabilidad del almacenamiento
#
# Objetivo: evitar que la cache de escritura VOLATIL de discos SSD/eMMC de
# consumo (sin proteccion ante perdida de energia, PLP) "mienta" sobre los
# fsync() que emite PostgreSQL. En ese hardware, un fsync() puede regresar
# con exito mientras los datos siguen en una cache volatil que se pierde al
# cortar la energia, produciendo corrupcion de pagina en disco del tipo:
#   InternalError: invalid page in block N of relation base/.../...
#
# Estrategia (defensa en profundidad, por cada disco fisico):
#   1) Intentar deshabilitar la cache de escritura del disco con `hdparm -W0`.
#      Es la garantia mas fiable: el disco confirma escrituras solo cuando
#      estan en medio persistente.
#   2) Si hdparm no esta disponible o el disco no soporta -W0, forzar el modo
#      "write through" del bloque via sysfs (/sys/block/<dev>/queue/write_cache).
#      Asi el kernel no asume una cache de respaldo volatil.
#
# Este script es idempotente y tolerante a fallos: si un disco no soporta una
# operacion concreta, se registra y se continua con el siguiente.
# =============================================================================
set -u

log() {
    # Enviar a journal/consola via stdout; el servicio systemd captura la salida.
    echo "disk-write-cache: $*"
}

# -----------------------------------------------------------------------------
# Lista de discos fisicos a endurecer. Se descubren dinamicamente desde sysfs
# para no depender de nombres fijos (sda, nvme0n1, mmcblk0, ...). Se excluyen
# dispositivos claramente no persistentes (loop, ram, zram).
# -----------------------------------------------------------------------------
discover_disks() {
    for dev in /sys/block/*; do
        name="$(basename "${dev}")"
        case "${name}" in
            loop*|ram*|zram*|sr*|fd*)
                continue
                ;;
        esac
        # Solo dispositivos de bloque reales con nodo en /dev.
        if [ -b "/dev/${name}" ]; then
            echo "${name}"
        fi
    done
}

# -----------------------------------------------------------------------------
# 1) Deshabilitar cache de escritura del disco con hdparm.
#    Devuelve 0 si lo consigue, 1 en caso contrario.
# -----------------------------------------------------------------------------
disable_cache_hdparm() {
    dev="$1"
    if ! command -v hdparm >/dev/null 2>&1; then
        return 1
    fi
    # -W0 deshabilita la cache de escritura del disco.
    if hdparm -W0 "/dev/${dev}" >/dev/null 2>&1; then
        log "cache de escritura deshabilitada con hdparm -W0 en /dev/${dev}"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# 2) Forzar write-through via sysfs (mecanismo del kernel, independiente de
#    hdparm; util para NVMe/eMMC donde hdparm puede no aplicar).
# -----------------------------------------------------------------------------
force_write_through_sysfs() {
    dev="$1"
    wc="/sys/block/${dev}/queue/write_cache"
    if [ -w "${wc}" ]; then
        if echo "write through" > "${wc}" 2>/dev/null; then
            log "write_cache forzado a 'write through' via sysfs en /dev/${dev}"
            return 0
        fi
    fi
    return 1
}

main() {
    disks="$(discover_disks)"
    if [ -z "${disks}" ]; then
        log "no se detectaron discos fisicos; nada que hacer"
        return 0
    fi

    for dev in ${disks}; do
        if disable_cache_hdparm "${dev}"; then
            # Aun asi reforzamos el modo del kernel para coherencia.
            force_write_through_sysfs "${dev}" || true
        elif force_write_through_sysfs "${dev}"; then
            log "hdparm no aplicable en /dev/${dev}; usado write-through via sysfs"
        else
            log "AVISO: no se pudo endurecer la cache de escritura en /dev/${dev}"
        fi
    done

    return 0
}

main "$@"
