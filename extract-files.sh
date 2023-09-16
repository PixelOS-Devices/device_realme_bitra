#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=bitra
VENDOR=realme

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        product/etc/sysconfig/com.android.hotwordenrollment.common.util.xml)
            sed -i "s|my_product|product|" "${2}"
            ;;
        vendor/lib/libgui1_vendor.so)
            patchelf --replace-needed "libui.so" "libui-v30.so" "${2}"
            ;;
        vendor/etc/libnfc-nci.conf)
            sed -i 's|NFC_DEBUG_ENABLED=1|NFC_DEBUG_ENABLED=0|g' "${2}"
            ;;
        vendor/etc/libnfc-nxp-21619.conf)
            sed -i 's|LOGLEVEL=0x03|LOGLEVEL=0x01|g' "${2}"
            sed -i 's|NFC_DEBUG_ENABLED=1|NFC_DEBUG_ENABLED=0x00|g' "${2}"
            ;;
        vendor/etc/libnfc-nxp-2169B.conf)
            sed -i 's|LOGLEVEL=0x03|LOGLEVEL=0x01|g' "${2}"
            sed -i 's|NFC_DEBUG_ENABLED=1|NFC_DEBUG_ENABLED=0x00|g' "${2}"
            ;;
        vendor/etc/msm_irqbalance.conf)
            sed -i "s/IGNORED_IRQ=27,23,38$/&,115,332/" "${2}"
            ;;
        vendor/lib64/hw/camera.qcom.so)
            grep -q libcamera_metadata_shim.so "${2}" || "${PATCHELF}" --add-needed "libcamera_metadata_shim.so" "${2}"
            ;;
        vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so)
            "${SIGSCAN}" -p "AF 0B 00 94" -P "1F 20 03 D5" -f "${2}"
            ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
