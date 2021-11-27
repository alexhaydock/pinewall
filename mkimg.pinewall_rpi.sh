profile_pinewall_rpi() {
  # Source the env vars from the "rpi" profile below (see mkimg.arm.sh)
  profile_rpi

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
    iperf3
    nano
    nftables
    nload
    openssh
    openssl
    ppp-pppoe
    tcpdump
    tftp-hpa
    unbound
    "
}
