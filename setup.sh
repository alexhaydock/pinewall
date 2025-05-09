#!/bin/sh
set -e

rc-update add devfs sysinit
rc-update add dmesg sysinit
rc-update add udev sysinit
rc-update add udev-settle sysinit
rc-update add udev-trigger sysinit

rc-update add bootmisc boot
rc-update add hostname boot
rc-update add hwclock boot
rc-update add klogd boot
rc-update add modules boot
rc-update add networking boot
rc-update add nftables boot
rc-update add rngd boot
rc-update add sysctl boot
rc-update add syslog boot

rc-update add killprocs shutdown
rc-update add mount-ro shutdown

rc-update add acpid default
rc-update add chronyd default
rc-update add crond default
rc-update add irqbalance default
rc-update add local default
rc-update add udev-postmount default

# pinewall helper scripts
rc-update add enforceperms default

# pinewall main workload
rc-update add corerad default
rc-update add dropbear default
rc-update add iperf3 default
rc-update add kea-dhcp4 default
rc-update add ulogd default
rc-update add unbound default

# default pw is `hello`
chpasswd -e <<'EOF'
root:$6$UIgiYBYh6IhLhm5D$Q2ZN2Pruh3ZJdJmjKiLdZQ5ziPT/1SFSmAhAuK4yttgUxG6cpdDUagWL8Egl.uKUz1JiyjeeqDjxwfT1x9T3b.
EOF
