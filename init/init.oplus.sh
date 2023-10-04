#! /vendor/bin/sh
#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

prjname=`getprop ro.boot.prjname`

# NFC
if [ "$prjname" = "21619" ] || [ "$prjname" = "2161A" ]; then
    setprop persist.vendor.nfc.config_file_name "libnfc-nxp-china.conf"
elif [ "$prjname" = "2169A" ] || [ "$prjname" = "2169B" ]; then
    setprop persist.vendor.nfc.config_file_name "libnfc-nxp-global.conf"
fi

# Wifi
persistbdf=`md5sum /mnt/vendor/persist/bdwlan.elf |cut -d" " -f1`
persistRegdb=`md5sum /odm/etc/wifi/regdb.bin |cut -d" " -f1`
vendorbdf=`md5sum /odm/etc/wifi/bdwlan.elf |cut -d" " -f1`
vendorRegdb=`md5sum /mnt/vendor/persist/regdb.bin |cut -d" " -f1`

if [ x"$vendorbdf" != x"$persistbdf" ]; then
    cp /odm/etc/wifi/bdwlan.elf /mnt/vendor/persist/bdwlan.elf
    sync
    echo "bdf check"
fi

if [ x"$vendorRegdb" != x"$persistRegdb" ]; then
    cp /odm/etc/wifi/regdb.bin /mnt/vendor/persist/regdb.bin
    sync
    echo "regdb check"
fi

chmod 666 /mnt/vendor/persist/bdwlan.elf
chmod 666 /mnt/vendor/persist/regdb.bin
chown system:wifi /mnt/vendor/persist/bdwlan.elf
chown system:wifi /mnt/vendor/persist/regdb.bin
