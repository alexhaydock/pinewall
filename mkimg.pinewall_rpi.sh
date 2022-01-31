profile_pinewall_rpi() {
  # Source the env vars from the "rpi" profile below (see mkimg.arm.sh)
  profile_rpi

  # Override the kernel_flavors variable that builds both "rpi" and "rpi4",
  # even for aarch64. We don't want to support anything before the Pi 4 since
  # anything below that had the ethernet controller on the USB bus so wouldn't
  # make a great router anyway.
  kernel_flavors="rpi4"

  # We don't want the kernel addons from the Standard profile, which includes
  # xtables-addons. We don't want any *tables stuff since we're fully nftables.
  kernel_addons=""

  # Don't forget to include $apks below to include the ones which we already read into this variable
  # from mkimg.base.sh (if we don't, we end up overwriting the variable)
  apks="$apks
    avahi
    chrony
    conntrack-tools
    dbus
    dhcp-server-vanilla
    dns-root-hints
    doas
    ethtool
    htop
    ifupdown-ng-ppp
    ifupdown-ng-wireguard
    iperf3
    nano
    nftables
    nload
    openssh
    openssl
    ppp-pppoe
    radvd
    raspberrypi
    rng-tools
    tcpdump
    tftp-hpa
    unbound
    wireguard-tools-wg
    "
}
