#!/bin/bash

echo "v1.0"
# Create partition table
SDCARD="UpdateiNAND.img"
IMAGE_ROOTFS_ALIGNMENT="4096"
BOOTDD_VOLUME_ID="kernel"
if [  -f ${SDCARD} ]; then
rm ${SDCARD}
fi
#mount partition
kernelmntpoint="/media/hio_kernel"
rootmntpoint="/media/hio_rootfs"
umount ${kernelmntpoint}
umount ${rootmntpoint}
# Align boot partition and calculate total SD card image size
#BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ROOTFS_ALIGNMENT} - 1)
#BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ROOTFS_ALIGNMENT})
#SDCARD_SIZE=$(expr ${IMAGE_ROOTFS_ALIGNMENT} + ${BOOT_SPACE_ALIGNED} + $ROOTFS_SIZE + ${IMAGE_ROOTFS_ALIGNMENT})


#dd if=/dev/zero of=${SDCARD} bs=1024 count=0 seek=$(expr 1024 \* ${SDCARD_SIZE})
#parted -s $SDCARD mklabel msdos

#parted -s $SDCARD mkpart primary fat32 100M 1000M
#parted -s $SDCARD mkpart primary ext2 1100M 2100M 
##flashing uboot
echo '==============write uboot'
dd if=/dev/zero of=${SDCARD} bs=1024 count=0 seek=768000

losetup -d /dev/loop0;losetup -d /dev/loop1;
losetup /dev/loop0 ${SDCARD}

sfdisk --force -uM /dev/loop0 << EOF
10,500,b
510,,83
EOF
sleep 1
losetup -o 8225280  /dev/loop1 /dev/loop0
mkfs.vfat /dev/loop1 && sync;losetup -d /dev/loop1;

losetup -o 534643200 /dev/loop1 /dev/loop0
mkfs.ext2 /dev/loop1 && sync;losetup -d /dev/loop1;

losetup -d /dev/loop0

#mk_tf start
dir_loc=$(pwd)
kernel_loc=${dir_loc/}/uImage
dtb_loc=${dir_loc}/*.dtb
rootfs_loc=${dir_loc}/usb_rootfs.tar.bz2
uboot_loc=${dir_loc}/u-boot.imx

#mount partition
mkdir -p ${kernelmntpoint} || exit
mkdir -p ${rootmntpoint} || exit
dd if=${uboot_loc} of=${SDCARD} bs=512 seek=2 conv=notrunc || exit
mount -o loop,offset=8225280 ${SDCARD} ${kernelmntpoint}

#copy kernel
echo '===========copy kernel image'
cp ${kernel_loc} ${kernelmntpoint} || exit 
cp ${dtb_loc} ${kernelmntpoint} || exit
cp -rf ${dir_loc}/update/ ${kernelmntpoint} || exit 
sync
sleep 1
#end copy kernel image

#copy root fs
echo '================copy yocto root fs'
mount -o loop,offset=534643200 ${SDCARD} ${rootmntpoint}
tar -xf ${rootfs_loc} -C ${rootmntpoint} || exit
sync
#enn cp rootfs
sync

#umount all patition
echo '=====================umount all patition'
umount ${kernelmntpoint}
umount ${rootmntpoint}
rmdir ${kernelmntpoint} ${rootmntpoint}
