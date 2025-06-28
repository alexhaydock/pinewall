#!/usr/bin/env sh
set -eu

# This script configures some post-"install" settings in the Alpine
# environment. Mainly it focuses on configuring the services that need
# to be configured to run with init.d

# This function does the same thing as `rc-update add` does if
# we were using chroot mode
rc_add() {
  mkdir -p "$ROOTFS"/etc/runlevels/"$2"
  ln -sf /etc/init.d/"$1" "$ROOTFS"/etc/runlevels/"$2"/"$1"
}

# Based heavily on
# https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/scripts/genapkovl-dhcp.sh

# add sysinit-runlevel services
rc_add devfs sysinit
rc_add dmesg sysinit

# add mdev services
rc_add mdev sysinit
rc_add hwdrivers sysinit

# add boot-runlevel services
rc_add bootmisc boot
rc_add hostname boot
rc_add hwclock boot
rc_add klogd boot
rc_add modules boot
rc_add networking boot
rc_add rngd boot
rc_add sysctl boot
rc_add syslog boot

# add shutdown-runlevel services
rc_add killprocs shutdown
rc_add mount-ro shutdown

# add acpid to accept Proxmox ACPI commands (shutdown mainly)
rc_add acpid default

# add default-runlevel services
rc_add chronyd default
rc_add crond default
rc_add local default

# add custom permission helper scripts
rc_add enforceperms default

# add pinewall main workload
rc_add corerad default
rc_add dropbear default
rc_add iperf3 default
rc_add kea-dhcp4 default
rc_add nftables boot
rc_add node-exporter default
rc_add ulogd default
rc_add unbound default

# update password for root
# (default pw is `hello`)
#
# Again, this is the same as echoing the same string into `chpasswd`
# but we operate on the shadowfile directly because we're not chrooted
# into the environment here
sed -i 's|^root:[^:]*:|root:$6$UIgiYBYh6IhLhm5D$Q2ZN2Pruh3ZJdJmjKiLdZQ5ziPT/1SFSmAhAuK4yttgUxG6cpdDUagWL8Egl.uKUz1JiyjeeqDjxwfT1x9T3b.:|' "$ROOTFS"/etc/shadow
