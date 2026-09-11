#!/bin/sh

DISK="/dev/mmcblk0p4"
POINT="/run/idisk"

[ -d "$POINT" ] || mkdir -p "$POINT"

mount "$DISK" "$POINT" || {
	mount -t tmpfs none /storage
	exit 1
}

[ -d "${POINT}/game" ] || mkdir -p "${POINT}/game"

mount --bind "${POINT}/game" /storage || {
	mount -t tmpfs none /storage
	exit 1
}

echo "bind ${POINT}/game to /storage DONE" > /dev/console
