#!/bin/sh

mount /dev/mmcblk0p4 /mnt || {
	mount -t tmpfs none /storage
	exit 1
}

[ -d /mnt/game ] || mkdir -p /mnt/game

if [ -f /mnt/game/script.sh ] ; then
	. /mnt/game/script.sh
fi

mount --bind /mnt/game /storage || {
	mount -t tmpfs none /storage
	exit 1
}

echo "bind /mnt/game to /storage DONE"

