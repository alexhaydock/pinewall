#!/usr/bin/env bash
set -xe

# This script expects you to be running it in a container
# with variables configured in a script at /settings.sh
source /settings.sh

# Configure our destination image name
# (Include the date we built the image)
IMGNAME="alpine-$PROFILENAME-$ALPINETAG-$(date -I)-$(uname -m)"

# Rename the image we built in the build step
mv -fv "/tmp/images/pinewall.tar.gz" "/tmp/images/$IMGNAME.tar.gz"

# Discover our new image path
IMGPATH="/tmp/images/$IMGNAME"

# Create 1G image
rm -v "$IMGPATH.img" || true
truncate -s 256M "$IMGPATH.img"

# Create a 255MB partition on the image we just created
sfdisk "$IMGPATH.img" << EOF
,$((2048*255)),c
EOF

# Decide on our loop device location
PART_DEV="/tmp/dev/loop0"

# Detach loop device if we've already got one mounted from a previous run
losetup -d $(ls -1 $PART_DEV) || true

# Make a place for us to mount this inside /tmp/dev
mkdir -p /tmp/dev

# Mount the loop device to our new location with losetup
mknod -m 0660 "$PART_DEV" b 7 0
losetup --partscan "$PART_DEV" ${IMGPATH}.img

# Print our loop devices for debug purposes
ls -lah /tmp/dev
losetup -a

# Make a VFAT filesystem on the image
# (try the mkfs command 3 times in case it doesn't work the first time)
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

# Make a copy of the image with a basic name so we can use it in our CI run
# TODO: Make this approach better
cp -fv "/tmp/output/$IMGNAME.img.gz" "/tmp/output/pinewall.img.gz"

# Move the uncompressed image over too, so we can keep it
mv -fv "$IMGPATH.img" "/tmp/output/$IMGNAME.img"

# Checksum our images
cd /tmp/output
sha256sum "$IMGNAME.img" "$IMGNAME.img.gz" > CHECKSUMS.sha256
