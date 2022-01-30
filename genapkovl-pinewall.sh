#!/bin/sh
set -xeu

# Set hostname to "pinewall"
HOSTNAME="pinewall"

cleanup() {
  rm -rf "$tmp"
}

makefile() {
  OWNER="$1"
  PERMS="$2"
  FILENAME="$3"
  cat > "$FILENAME"
  chown "$OWNER" "$FILENAME"
  chmod "$PERMS" "$FILENAME"
}

copyfile() {
  OWNER="$1"
  PERMS="$2"
  SOURCE="$3"
  DEST="$4"
  cp -f "$SOURCE" "$DEST"
  chown "$OWNER" "$DEST"
  chmod "$PERMS" "$DEST"
}

rc_add() {
  mkdir -p "$tmp"/etc/runlevels/"$2"
  ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

# Copy our interfaces file
mkdir -p "$tmp"/etc/network
copyfile root:root 0644 /tmp/etc/network/interfaces "$tmp"/etc/network/interfaces

# By default, it seems like /etc/apk/world on a system without
# an apkovl being loaded contains just the two entries for
# "alpine-base" and for "openssl". I've replicated those in
# the world file to make sure we don't miss out on them.
mkdir -p "$tmp"/etc/apk
copyfile root:root 0644 /tmp/etc/apk/world "$tmp"/etc/apk/world

# Copy the repos file to give us internet repo access
mkdir -p "$tmp"/etc/apk
copyfile root:root 0644 /tmp/etc/apk/repositories "$tmp"/etc/apk/repositories

# Set timezone to UTC
# (This is getting copied from the local Alpine container where the `tzdata` package keeps it)
mkdir -p "$tmp"/etc/zoneinfo
copyfile root:root 0644 /usr/share/zoneinfo/UTC "$tmp"/etc/zoneinfo/UTC
mkdir -p "$tmp"/etc/profile.d
copyfile root:root 0644 /tmp/etc/profile.d/timezone.sh "$tmp"/etc/profile.d/timezone.sh

# Seed our custom users based on the user config files
# in the running container
mkdir -p "$tmp"/etc
copyfile root:root 0644 /etc/group "$tmp"/etc/group
copyfile root:root 0644 /etc/passwd "$tmp"/etc/passwd
copyfile root:root 0644 /etc/shadow "$tmp"/etc/shadow

# Lock the root account
# We're doing this by setting the /sbin/nologin shell
sed -i 's,^root.*,root:x:0:0:root:/root:/sbin/nologin,g' "$tmp"/etc/passwd

# Add a new iperf user and group without a password
echo "iperf:x:520:" >> "$tmp"/etc/group
echo "iperf:x:520:520:iperf user:/home/iperf:/sbin/nologin" >> "$tmp"/etc/passwd
echo "iperf:!::0:::::" >> "$tmp"/etc/shadow

# Add a pinewall user with default password of "pinewall"
echo "pinewall:x:5000:" >> "$tmp"/etc/group
echo "pinewall:x:5000:5000:Pinewall MGMT user:/home/pinewall:/bin/ash" >> "$tmp"/etc/passwd
echo 'pinewall:$6$sFTyHCoLEjykVIXe$aDrddac7iQoqnedKMev5LuEf52/mQvTe5gOZkvERsgu36B7PM7HPj0udJFmSsLOAUac//OyOJpvjdEhEsEPxK.::0:::::' >> "$tmp"/etc/shadow

# Create pinewall user's home directory
# Add a basic file to this so it's not empty otherwise
# the APK overlay doesn't seem to actually create it
# in the loaded system.
mkdir -p "$tmp"/home/pinewall
chmod 0750 "$tmp"/home/pinewall
echo "pinewall" > "$tmp"/home/pinewall/.pinewall
chmod 0640 "$tmp"/home/pinewall/.pinewall
chown -R 5000:5000 "$tmp"/home/pinewall

# Copy doas config to allow the pinewall user to escalate privilege
mkdir -p "$tmp"/etc
copyfile root:root 0400 /tmp/etc/doas.conf "$tmp"/etc/doas.conf

# Add our file based on the iperf3 init.d default file
# but which specifies to use the iperf user.
#
# Note the 0755 here as we want this to match our other
# init.d scripts and actually be executable.
mkdir -p "$tmp"/etc/init.d
copyfile root:root 0755 /tmp/etc/init.d/iperf3 "$tmp"/etc/init.d/iperf3

# Branding generated with:
#   - neofetch --logo --ascii_distro Alpine_small
#   - figlet Pinewall
#   - and some painstaking lining-up
mkdir -p "$tmp"/etc
copyfile root:root 0644 /tmp/etc/motd "$tmp"/etc/motd

# Copy our /etc/fstab which will mount disks labeled PINECONF
# to /media/usb to allow us to use `lbu commit`.
mkdir -p "$tmp"/etc
copyfile root:root 0644 /tmp/etc/fstab "$tmp"/etc/fstab

# Add sysctls
mkdir -p "$tmp"/etc/sysctl.d
copyfile root:root 0644 /tmp/etc/sysctl.d/local.conf "$tmp"/etc/sysctl.d/local.conf

# Add NTP config
mkdir -p "$tmp"/etc/chrony
copyfile root:root 0644 /tmp/etc/chrony/chrony.conf "$tmp"/etc/chrony/chrony.conf

# Add DNS client config
mkdir -p "$tmp"/etc
copyfile root:root 0644 /tmp/etc/resolv.conf "$tmp"/etc/resolv.conf

# Add DNS server config
mkdir -p "$tmp"/etc/unbound
copyfile root:root 0644 /tmp/etc/unbound/unbound.conf "$tmp"/etc/unbound/unbound.conf

# Add IPv6 radvd config
# It seems like radvd is quite particular about making sure its config is not world writable
mkdir -p "$tmp"/etc
copyfile root:root 0400 /tmp/etc/radvd.conf "$tmp"/etc/radvd.conf

# Add nftables rules - note that these are 0754 unlike other files, as they
# need to be executable!
copyfile root:root 0754 /tmp/etc/nftables.nft "$tmp"/etc/nftables.nft
mkdir -p "$tmp"/etc/nftables.d
copyfile root:root 0754 /tmp/etc/nftables.d/00-vars.nft "$tmp"/etc/nftables.d/00-vars.nft
copyfile root:root 0754 /tmp/etc/nftables.d/10-firewall.nft "$tmp"/etc/nftables.d/10-firewall.nft
copyfile root:root 0754 /tmp/etc/nftables.d/20-nat.nft "$tmp"/etc/nftables.d/20-nat.nft

# Add Avahi config
mkdir -p "$tmp"/etc/avahi
copyfile root:root 0644 /tmp/etc/avahi/avahi-daemon.conf "$tmp"/etc/avahi/avahi-daemon.conf

# Add DHCP config
mkdir -p "$tmp"/etc/dhcp
copyfile root:root 0644 /tmp/etc/dhcp/dhcpd.conf "$tmp"/etc/dhcp/dhcpd.conf
copyfile root:root 0644 /tmp/etc/dhcp/dhcpd-ranges.conf "$tmp"/etc/dhcp/dhcpd-ranges.conf
copyfile root:root 0644 /tmp/etc/dhcp/dhcpd-reservations.conf "$tmp"/etc/dhcp/dhcpd-reservations.conf

# Add Netboot.xyz PXE config
mkdir -p "$tmp"/var/tftpboot
copyfile root:root 0644 /tmp/var/tftpboot/netboot.xyz.kpxe "$tmp"/var/tftpboot/netboot.xyz.kpxe

# Add Fedora PXE config
mkdir -p "$tmp"/var/tftpboot
copyfile root:root 0644 /tmp/var/tftpboot/grubx64.efi "$tmp"/var/tftpboot/grubx64.efi
copyfile root:root 0644 /tmp/var/tftpboot/shimx64.efi "$tmp"/var/tftpboot/shimx64.efi
mkdir -p "$tmp"/var/tftpboot/EFI/fedora
copyfile root:root 0644 /tmp/var/tftpboot/EFI/fedora/grub.cfg "$tmp"/var/tftpboot/EFI/fedora/grub.cfg

# Add Fedora 35 Kernel / Initramfs
mkdir -p "$tmp"/var/tftpboot/f35
copyfile root:root 0644 /tmp/var/tftpboot/f35/initrd.img "$tmp"/var/tftpboot/f35/initrd.img
copyfile root:root 0644 /tmp/var/tftpboot/f35/vmlinuz "$tmp"/var/tftpboot/f35/vmlinuz

# Add PPPoE settings
mkdir -p "$tmp"/etc/ppp
copyfile root:root 0600 /tmp/etc/ppp/chap-secrets "$tmp"/etc/ppp/chap-secrets
copyfile root:root 0755 /tmp/etc/ppp/ip-up "$tmp"/etc/ppp/ip-up
mkdir -p "$tmp"/etc/ppp/peers
copyfile root:root 0644 /tmp/etc/ppp/peers/aaisp "$tmp"/etc/ppp/peers/aaisp

# Add modules file
mkdir -p "$tmp"/etc
copyfile root:root 0644 /tmp/etc/modules "$tmp"/etc/modules

# Add rngd config
mkdir -p "$tmp"/etc/conf.d
copyfile root:root 0644 /tmp/etc/conf.d/rngd "$tmp"/etc/conf.d/rngd

# Copy LBU config so that LBU in our running environment will backup
# to the "usb" device by default, which it will mount to /media/usb
#mkdir -p "$tmp"/etc/lbu
#copyfile root:root 0644 /tmp/etc/lbu/lbu.conf "$tmp"/etc/lbu/lbu.conf

# Except where commented, these runlevels come from the defaults that can
# be found after a basic Alpine Standard install to HDD with the defaults.

rc_add bootmisc boot
rc_add hostname boot
rc_add hwclock boot
#rc_add loadkmap boot  # Might not be needed unless we specify a keymap
rc_add modules boot
rc_add networking boot
rc_add swap boot  # Won't work unless we have swap which we won't if we're running live
rc_add rngd boot          # Add rng service for Pi type devices without much entropy available
rc_add sysctl boot
rc_add syslog boot
rc_add urandom boot

# Most of our services want to go here in the default runlevel
rc_add acpid default
rc_add avahi-daemon default
rc_add chronyd default
rc_add crond default
rc_add dhcpd default
rc_add in.tftpd default
rc_add iperf3 default
rc_add nftables default
#rc_add radvd default  # We let ppp start this instead inside /etc/ppp/if-up
rc_add sshd default
rc_add unbound default

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add hwdrivers sysinit
rc_add mdev sysinit
# modloop isn't present for the sysinit runlevel on an installed
# system, but experimentation and documentation online suggests this
# is needed for the live system
rc_add modloop sysinit

# Wrap up our custom /etc and /home into an APK overlay file
tar -c -C "$tmp" etc home var | gzip -9n > /tmp/overlays/$HOSTNAME.apkovl.tar.gz
