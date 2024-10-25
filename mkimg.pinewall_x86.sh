profile_pinewall_x86() {
  # Source the env vars from the "virt" profile below (see mkimg.standard.sh)
  # Note that this produces an image optimised for running as a virtual guest
  # so it may not support physical hardware appropriately
  profile_virt

  # Force x86_64
  arch="x86_64"

  # Don't forget to include $apks below to include the ones which we already read into this variable
  # from mkimg.base.sh (if we don't, we end up overwriting the variable)
  apks="$apks
    avahi
    chrony
    conntrack-tools
    corerad
    dbus
    dns-root-hints
    doas
    dropbear
    ethtool
    htop
    ifupdown-ng-ppp
    ifupdown-ng-wireguard
    iperf3
    irqbalance
    kea
    logrotate
    nano
    nftables
    nload
    openssl
    ppp-pppoe
    rng-tools
    tcpdump
    ulogd
    unbound
    wireguard-tools-wg
    "

  # Build our APK overlay into the built image automatically
  apkovl="genapkovl-pinewall.sh"
}
