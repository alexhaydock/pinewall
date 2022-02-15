#!/usr/bin/env bash
set -xe

# This script expects you to be running it in a container
# with variables configured in a script at /settings.sh
source /settings.sh

# Autodiscover the image name that we built in the builder
# step and copied into the container that will run this script
# (We don't control this name)
IMGNAME="alpine-$PROFILENAME-$ALPINETAG-$(uname -m)"

# Set our destination image name to something better
# (Include the date we built the image)
IMGDEST="alpine-$PROFILENAME-$ALPINETAG-$(date -I)-$(uname -m)"

# Rename the image
mv -fv "/tmp/images/$IMGNAME.tar.gz" "/tmp/images/$IMGDEST.tar.gz" 

# Discover our new image path
IMGNAME="$IMGDEST"
IMGPATH="/tmp/images/$IMGDEST"

# Create 1G image
rm -v "$IMGPATH.img" || true
truncate -s 256M "$IMGPATH.img"

# Create a 255MB partition on the image we just created
sfdisk "$IMGPATH.img" << EOF
,$((2048*255)),c
EOF

# Detach all loop devices (WARNING! - also affects the host!)
losetup -d $(ls -1 /dev/loop?) || true

# Mount our loop device and then discover our loop device specifics
# We run this in an Ubuntu container because in an Alpine container
# the losetup binary is provided by Busybox and doesn't support the
# --partscan flag, and for whatever reason the one that ships with
# Fedora gives us this issue: https://github.com/RPi-Distro/pi-gen/issues/257
LOOP_DEV="$(losetup --partscan --show --find ${IMGPATH}.img)"
PART_DEV="$LOOP_DEV"p1

# Wait a bit before trying to format it
sleep 2

# Make a VFAT filesystem on the image
mkfs.vfat -F32 "$PART_DEV"
fatlabel "$PART_DEV" PINEWALL

# Make a directory and mount our FAT partition into it
mkdir -p /tmp/pinewall
mount --make-private "$PART_DEV" /tmp/pinewall

# Extract our generated filesystem content into the mounted filesystem
tar -xvf "$IMGPATH.tar.gz" --no-same-owner -C /tmp/pinewall

# Copy in our Pi firmware tweaks before creating the final image
cp -fv /opt/usercfg.txt /tmp/pinewall/usercfg.txt

# Sync disks twice, just to make sure
sync
sync

# Unmount the filesystem
umount -lf /tmp/pinewall

# Detach the loop device (very important otherwise it'll stick around including on the host)
losetup -d "$LOOP_DEV"

# Compress our final image into our output directory
gzip -c "$IMGPATH.img" > "/tmp/output/$IMGNAME.img.gz"

# Move the uncompressed image over too, so we can keep it
mv -fv "$IMGPATH.img" "/tmp/output/$IMGNAME.img"

# Checksum the 3 files we now have in the output dir (we assume the *.tar.gz file is still here from our previous run)
cd /tmp/output
sha256sum "$IMGNAME.img" "$IMGNAME.img.gz" > CHECKSUMS.sha256
