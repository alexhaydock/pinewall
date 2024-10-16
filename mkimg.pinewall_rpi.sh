profile_pinewall_rpi() {
  # Source the env vars from the "rpi" profile below (see mkimg.arm.sh)
  profile_rpi

  # Force aarch64
  arch="aarch64"

  # We don't want the kernel addons from the Standard profile, which includes
  # xtables-addons. We don't want any *tables stuff since we're fully nftables.
  kernel_addons=""

  # Override our apks variable that we import from aports' mkimg.base.sh, by
  # including just the packages we actually find loaded on a running Pi system
  # (it includes a bunch we never end up needing, like e2fsprogs and openntpd)
  #
  # Doing this slims down our image quite a bit.
  #
  # See: https://gitlab.com/pinewall/pinewall/-/issues/1
  apks="alpine-base
    busybox
    chrony
    openssl
    "

  # Add common APKs list to current APK list
  # This list should be the same for both mkimg.pinewall_rpi.sh and
  # mkimg.pinewall_x86.sh:
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

  # Add any Pi-specific APKs to the APK list
  apks="$apks
    raspberrypi
    "

  # Build our APK overlay into the built image automatically
  apkovl="genapkovl-pinewall.sh"
}
