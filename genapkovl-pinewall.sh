#!/bin/sh -e

# Read in the variable that gets passed to the script.
# We might as well, but we'll just set /etc/hostname to
# 'pinewall' instead anyway further down in this script.
HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
  echo "usage: $0 hostname"
  exit 1
fi

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
  cp -fv "$SOURCE" "$DEST"
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
pinewall
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# By default, it seems like /etc/apk/world on a system without
# an apkovl being loaded contains just the two entries for
# "alpine-base" and for "openssl". I've replicated those here
# to make sure we don't miss out on them.
mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
avahi
chrony
conntrack-tools
dbus
dhcp-server-vanilla
ethtool
htop
iperf3
lighttpd
nano
nftables
nload
openssh
openssl
sudo
tcpdump
tftp-hpa
unbound
vnstat
wireguard-tools-wg
EOF

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
mkdir -p "$tmp"/home/pinewall
chown 5000:5000 "$tmp"/home/pinewall
chmod 0750 "$tmp"/home/pinewall

# Allow pinewall user sudo access
mkdir -p "$tmp"/etc/sudoers.d
makefile root:root 0440 "$tmp"/etc/sudoers.d/pinewall <<EOF
pinewall ALL=(ALL) ALL
EOF

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

# Write an inittab which is the same as the default but that doesn't
# spawn as many TTYs by default
mkdir -p "$tmp"/etc
copyfile root:root 0644 /tmp/etc/inittab "$tmp"/etc/inittab

mkdir -p "$tmp"/etc/sysctl.d
copyfile root:root 0644 /tmp/etc/sysctl.d/local.conf "$tmp"/etc/sysctl.d/local.conf

mkdir -p "$tmp"/etc/chrony
copyfile root:root 0644 /tmp/etc/chrony/chrony.conf "$tmp"/etc/chrony/chrony.conf

mkdir -p "$tmp"/etc/unbound
copyfile root:root 0644 /tmp/etc/unbound/unbound.conf "$tmp"/etc/unbound/unbound.conf

mkdir -p "$tmp"/etc/unbound
makefile root:root 0644 "$tmp"/etc/unbound/unbound-localzone.conf <<EOF
# /etc/unbound/unbound-localzone.conf

# Define a transparent local zone for our LAN search domain
local-zone: "localdomain." transparent

# You can manually add DNS entries to your local zone here
# I have included some examples below:
#local-data-ptr: "10.10.10.10 nextcloud.localdomain"
#local-data: "nextcloud.localdomain. A 10.10.10.10"
EOF


# Except where commented, these runlevels come from the defaults that can
# be found after a basic Alpine Standard install to HDD with the defaults.

rc_add bootmisc boot
rc_add hostname boot
rc_add hwclock boot
#rc_add loadkmap boot  # Might not be needed unless we specify a keymap
rc_add modules boot
rc_add networking boot
rc_add swap boot  # Won't work unless we have swap which we won't if we're running live
rc_add sysctl boot
rc_add syslog boot
rc_add urandom boot

# Most of our services want to go here in the default runlevel
rc_add acpid default
rc_add chronyd default
rc_add crond default
rc_add iperf3 default
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

tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
