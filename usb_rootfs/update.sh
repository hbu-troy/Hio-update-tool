# check the if root?
userid=`id -u`
if [ $userid -ne "0" ]; then
        echo "you're not root?"
        exit
fi
if [ -e /dev/sda1 ];then
update_disk=/dev/sda1
else update_disk=/dev/mmcblk1p1
fi
dir_loc=/mnt/usb/update
mkdir -p ${dir_loc}
mount $update_disk $dir_loc
updateini=$dir_loc/update/update.ini

ROOTFS=`grep rootfs $updateini |  cut -d= -f2`
OPTIONS=`grep OPTION $updateini |  cut -d= -f2`
cd /
case ${OPTIONS} in
   all)
	sh update.sh_all
	;;
   kernel)
       sh update.sh_kernel
	;;
   uboot)
	sh update.sh_uboot
 	;;
   rootfs)
	sh update.sh_rootfs
	;;
   kerneluboot)
	sh update.sh_kerneluboot
	;;
#    *)
#	sh update.sh_all
esac
