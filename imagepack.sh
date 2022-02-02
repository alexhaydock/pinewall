#!/usr/bin/env bash
set -xe

# This script expects you to be running it in a container
# with variables configured in a script at /settings.sh
source /settings.sh

# Autodiscover the image name
IMGNAME="/tmp/output/alpine-$PROFILENAME-v$ALPINEVER-$(uname -m)"

# Create 1G image
rm -v "$IMGNAME.img" || true
truncate -s 1G "$IMGNAME.img"

# Create a partition on the image we just created
fdisk -H 255 -S 63 "$IMGNAME.img" <<-EOF
o
n
p
1


w
EOF

# Detach all loop devices (WARNING! - also affects the host!)
losetup -d $(ls -1 /dev/loop?) || true

# Mount our loop device and then discover our loop device specifics
# We run this in an Ubuntu container because in an Alpine container
# the losetup binary is provided by Busybox and doesn't support the
# --partscan flag, and for whatever reason the one that ships with
# Fedora gives us this issue: https://github.com/RPi-Distro/pi-gen/issues/257
LOOP_DEV="$(losetup --partscan --show --find ${IMGNAME}.img)"
PART_DEV="$LOOP_DEV"p1

# Wait a bit before trying to format it
sleep 2

# Make a VFAT filesystem on the image
# We run this in an Ubuntu container since the version of dosfstools
# that ships with Fedora gives us an issue about CP850 to UTF-8
# translation for the FAT volume name that I can only find on this
# Russian forum without a real solution attached: https://www.linux.org.ru/forum/linux-install/16201697
mkfs.vfat -F32 -n PINEWALL "$PART_DEV"

# Make a directory and mount our VFAT partition into it
mkdir -p /tmp/pinewall
mount --make-private "$PART_DEV" /tmp/pinewall

# Extract our generated filesystem content into the mounted filesystem
tar -xvf "$IMGNAME.tar.gz" --no-same-owner -C /tmp/pinewall

# Sync disks twice, just to make sure
sync
sync

# Unmount the filesystem
umount -lf /tmp/pinewall

# Detach the loop device (very important otherwise it'll stick around including on the host)
losetup -d "$LOOP_DEV"

# Compress our final image
gzip -c "$IMGNAME.img" > "$IMGNAME.img.gz"
rm -fv "$IMGNAME.img"
