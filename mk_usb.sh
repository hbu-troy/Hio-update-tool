#!/bin/bash
begintime=`date +%s`

# check the if root?
userid=`id -u`
if [ $userid -ne "0" ]; then
        echo "you're not root?"
        exit
fi

disk=$1
#for_inand_flash=1


dir_loc=$(pwd)
uboot_loc=${dir_loc}/u-boot.imx
kernel_loc=${dir_loc}
rootfs_loc=${dir_loc}/usb_rootfs.tar.bz2


#cusimg=${dir_loc}/YoctoOS150520.img
logpath=${dir_loc}/
starttime=$(date "+%Y%m%d_%H:%M")
logfile="${logpath}log_${starttime}"
touch ${logfile}

function unmount_all 
{
	echo "unmount all partitions on "${disk} >> ${logfile}
	for i in $(seq 16)
	do
        	if [ -e "${disk}$i" ]
        	then
                	echo "${disk}$i" " exist" >> ${logfile}
                	umount "${disk}$i" 2>>${logfile}
        	fi
	done
}


#create partition table
# partition size in MB
echo disk:$disk >> ${logfile}

unmount_all

total_size=`sfdisk -s ${disk}`
total_size=`expr ${total_size} / 1024`
boot_start=8
total_size=`expr ${total_size} - ${boot_start}`
OTHER=80
BOOT_SIZE=5048
#RECOVERY_SIZE=1300
#ROOT_SIZE=`expr $total_size - $BOOT_SIZE - $RECOVERY_SIZE - $OTHER`
ROOT_SIZE=`expr $total_size - $BOOT_SIZE - $OTHER`

seprate=40

root_start=`expr ${boot_start} + ${BOOT_SIZE} + ${seprate}`
#recovery_start=`expr ${root_start} + ${ROOT_SIZE} + ${seprate}`
echo boot_start:$boot_start >> ${logfile}
echo BOOT_SIZE:$BOOT_SIZE >> ${logfile}
echo root_start:$root_start >> ${logfile}
echo ROOT_SIZE:$ROOT_SIZE >> ${logfile}
#echo recovery_start:$recovery_start >> ${logfile}
#echo RECOVERY_SIZE:$RECOVERY_SIZE >> ${logfile}

# destroy the partition table
echo 'destroy the partition table' >> ${logfile}
dd if=/dev/zero of=${disk} bs=1024 count=1 2>>${logfile}

sfdisk --force -uM ${disk} << EOF
${boot_start},${BOOT_SIZE},b
${root_start},${ROOT_SIZE},83
EOF
#${recovery_start},${RECOVERY_SIZE},83


sync
#end create partition table

#formating partition
echo 'formating partition' >> ${logfile}
mkfs.vfat ${disk}1 -nkernel 2>>${logfile}
mkfs.ext4 ${disk}2 -Lroot 2>>${logfile}
#mkfs.ext4 ${disk}3 -Lrecovery 2>>${logfile}
sync
#end formating partition

unmount_all

#make some dir for mount
echo 'make some dir for mount' >> ${logfile}
kernelmntpoint="/media/kernel"
rootmntpoint="/media/root"
#recoverymntpoint="/media/vki_recovery"
mkdir -p ${kernelmntpoint} 2>>${logfile}
mkdir -p ${rootmntpoint} 2>>${logfile}
#mkdir -p ${recoverymntpoint} 2>>${logfile}
#end make dir

#mount patition
echo '==========mount patition' >> ${logfile}
mount ${disk}1 ${kernelmntpoint} 2>>${logfile}
mount ${disk}2 ${rootmntpoint} 2>>${logfile}
#mount ${disk}3 ${recoverymntpoint} 2>>${logfile}
sync
#end mount patition

#flashing uboot
echo ======uboot file:${uboot_loc} >> ${logfile}
dd if=/dev/zero of=${disk} bs=512 seek=2 skip=2 count=1536 conv=fsync conv=notrunc 2>>${logfile}
dd if=${uboot_loc} of=${disk} bs=512 seek=2 conv=fsync 2>>${logfile}
sync
#end flashing uboot

#copy kernel image
echo '===========copy kernel image' >> ${logfile}
echo kernel_loc:${kernel_loc} >> ${logfile}
cp ${kernel_loc}/uImage ${kernelmntpoint} 2>>${logfile}
cp ${kernel_loc}/*.dtb ${kernelmntpoint} 2>>${logfile}
cp -rf ${kernel_loc}/update/ ${kernelmntpoint} 2>>${logfile}
sync
sleep 1
echo =============copy kernel image end
#end copy kernel image

#copy root fs
echo '================cp yocto root fs' >> ${logfile}
echo rootfs_loc:${rootfs_loc} >> ${logfile}
echo 'it will take five minutes, please wait....'
tar -xf ${rootfs_loc} -C ${rootmntpoint} 2>>${logfile}
#tar xvf ${rootfs_loc}
sync
sleep 2
#end copy root fs

#check if all file is ok
echo "==================checking===================="
df
if [ ! -f ${kernelmntpoint}/imx6dl-sabresd.dtb ]; then
	echo -e '\033[31m cp dtb file error!!! \033[0m'
	echo -e 'cp dtb file error!!!' >> ${logfile}
else
	echo -e '\033[32m cp dtb file success!!! \033[0m'
	echo -e 'cp dtb file success!!!' >> ${logfile}
fi

if [ ! -f ${kernelmntpoint}/uImage ]; then
	echo -e '\033[31m cp uImage error!!! \033[0m'
	echo -e 'cp uImage error!!!' >> ${logfile}
else
	echo -e '\033[32m cp uImage success!!! \033[0m'
	echo -e 'cp uImage success!!!' >> ${logfile}
fi

:<<!
if [ "${for_inand_flash}" -eq "1" ]; then
if [ ! -d ${rootmntpoint}/flash_image_mmc ]; then
	echo -e '\033[31m cp root fs error!!! \033[0m'
	echo -e 'cp root fs error!!!' >> ${logfile}
else
	echo -e '\033[32m cp root fs success!!! \033[0m'
	echo -e 'cp root fs success!!!' >> ${logfile}
fi
else
if [ ! -d ${rootmntpoint}/etc ]; then
	echo -e '\033[31m cp root fs error!!! \033[0m'
	echo -e 'cp root fs error!!!' >> ${logfile}
else
	echo -e '\033[32m cp root fs success!!! \033[0m'
	echo -e 'cp root fs success!!!' >> ${logfile}
fi
fi
!

sleep 1
sync
echo 'if there no error, then make success!!!!!'
echo "================end checking========================"
#end check

#umount all patition
echo ================umount all patition
unmount_all
echo ================umount all patition end
#end umount

#fsck 
echo "e2fsck ..."
e2fsck ${disk}2 -y

#delete all tmp file
echo ====================delete all tmp file >> ${logfile}
rmdir ${kernelmntpoint} ${rootmntpoint} ${recoverymntpoint} 2>>${logfile}
echo ====================delete all tmp file end
#end delete

endtime=`date +%s`
duration=$(($endtime-$begintime))
echo cost $duration in seconds
echo cost $(($duration/60)) in minutes
echo cost $(($duration/60)) in minutes >> ${logfile}
