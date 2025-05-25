#!/usr/bin/env sh
set -eu

# This function does the same thing as `rc_add` does if
# we were using chroot mode
rc_add() {
  mkdir -p "$ROOTFS"/etc/runlevels/"$2"
  ln -sf /etc/init.d/"$1" "$ROOTFS"/etc/runlevels/"$2"/"$1"
}

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add udev sysinit
rc_add udev-settle sysinit
rc_add udev-trigger sysinit

rc_add bootmisc boot
rc_add hostname boot
rc_add hwclock boot
rc_add klogd boot
rc_add modules boot
rc_add networking boot
rc_add nftables boot
rc_add rngd boot
rc_add sysctl boot
rc_add syslog boot

rc_add killprocs shutdown
rc_add mount-ro shutdown

rc_add acpid default
rc_add chronyd default
rc_add crond default
rc_add irqbalance default
rc_add local default
rc_add udev-postmount default

# pinewall helper scripts
rc_add enforceperms default

# pinewall main workload
rc_add corerad default
rc_add dropbear default
rc_add iperf3 default
rc_add kea-dhcp4 default
rc_add ulogd default
rc_add unbound default

# update password for root
# (default pw is `hello`)
#
# Again, this is the same as echoing the same string into `chpasswd`
# but we operate on the shadowfile directly because we're not chrooted
# into the environment here
sed -i 's|^root:[^:]*:|root:$6$UIgiYBYh6IhLhm5D$Q2ZN2Pruh3ZJdJmjKiLdZQ5ziPT/1SFSmAhAuK4yttgUxG6cpdDUagWL8Egl.uKUz1JiyjeeqDjxwfT1x9T3b.:|' "$ROOTFS"/etc/shadow
