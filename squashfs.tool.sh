#!/bin/bash

function squashfs_init()
{
	sudo apt install -y build-essential zlib1g-dev liblzma-dev liblzo2-dev liblz4-dev libzstd-dev
	git clone https://github.com/plougher/squashfs-tools.git
	cd squashfs-tools/squashfs-tools
	make ZSTD_SUPPORT=1
	sudo make install
}

# Number  Start (sector)    End (sector)  Size       Code  Name
#    1           32768         4227071   2.0 GiB     0700  system
#    2         4227072         4292607   32.0 MiB    8300  storage


#  tree -L 3
# .
# ├── KERNEL
# ├── KERNEL.md5
# ├── SYSTEM
# ├── SYSTEM.md5
# ├── device_trees
# │   └── rk3399-anbernic-rg552.dtb
# └── extlinux
#     └── extlinux.conf

# cat extlinux.conf
# LABEL ROCKNIX
#   LINUX /KERNEL
#   FDT /device_trees/rk3399-anbernic-rg552.dtb
#   APPEND boot=LABEL=ROCKNIX disk=LABEL=STORAGE quiet console=ttyS2,115200 console=tty0 systemd.debug_shell=ttyS2

function rocknix_download_img()
{
	wget https://github.com/ROCKNIX/distribution/releases/download/20260901/ROCKNIX-RK3399.aarch64-20260901.img.gz
	gunzip ROCKNIX-RK3399.aarch64-20260901.img.gz
	dd if=ROCKNIX-RK3399.aarch64-20260901.img of=rock.img bs=512 skip=32768
	rm -f ROCKNIX-RK3399.aarch64-20260901.img
	mkdir temp 
	sudo mount rock.img temp 
	cp temp/SYSTEM ./rocknix.rootfs.raw
	umount temp 
	rm -rf rock.img temp 
}

function squashfs_info()
{
	unsquashfs -s ./rocknix.rootfs.raw
}

function squashfs_extract()
{
	[ -d ./rootfs.sqfs ] && sudo rm -rf ./rootfs.sqfs
	sudo unsquashfs -d ./rootfs.sqfs ./rocknix.rootfs.raw
}

function squashfs_pack()
{
	[ -e rootfs.sqfs ] || return 1
	[ -e SYSTEM.sqfs ] && rm SYSTEM.sqfs
	sudo mksquashfs ./rootfs.sqfs SYSTEM.sqfs -comp zstd -Xcompression-level 19 -b 1048576 -no-xattrs

	unsquashfs -s SYSTEM.sqfs
	md5sum SYSTEM.sqfs > SYSTEM.sqfs.md5
	cp -f SYSTEM.sqfs ./bootimg/SYSTEM
	cp -f SYSTEM.sqfs.md5 ./bootimg/SYSTEM.md5
	ls -al ./bootimg
}

function squashfs_patch()
{
	[ -e rootfs.sqfs ] || return 1
	if [ "$KERNEL_PATH" = "" ] ; then
		echo "KERNEL_PATH is not set"
		return 1
	else 
		VERSION=$(cat $KERNEL_PATH/include/generated/utsrelease.h | grep UTS_RELEASE |awk '{gsub(/"/,"");print $3}')
		sudo cp -rf ./patch/* ./rootfs.sqfs
		sudo depmod -b ./rootfs.sqfs/usr/lib/kernel-overlays/base $VERSION
	fi
}



case "$1" in
	init)
		squashfs_init
		rocknix_download_img
		;;
	info)
		squashfs_info 
		;;
	extract)
		squashfs_extract
		;;
	patch)
		squashfs_patch
		;;
	pack)
		squashfs_pack
		;;
		*)
		;;
	*)
		echo "Usage: $0 {init|info|extract|pack|patch}"
		exit 1
		;;
esac