#!/bin/sh
loc_dir=${pwd}
rootfs=..${loc_dir}/usb_rootfs.tar.bz2
echo ${rootfs}
if [ -e ${rootfs} ];then
rm ${rootfs}
fi
tar cjvf ${rootfs} *
sync
