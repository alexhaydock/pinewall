profile_pinewall_x86() {
  # Source the env vars from the "standard" profile below (see mkimg.base.sh)
  profile_standard

  # Force x86_64
  arch="x86_64"

  # We don't want the kernel addons from the Standard profile, which includes
  # xtables-addons. We don't want any *tables stuff since we're fully nftables.
  kernel_addons=""

  # Include AMD and Intel microcode updates (taken from the default "Extended" profile)
  # (Disabled since I'm only targeting KVM VMs for x86_64 targets)
  ##boot_addons="amd-ucode intel-ucode"
  ##initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"

  # Don't forget to include $apks below to include the ones which we already read into this variable
  # from mkimg.base.sh (if we don't, we end up overwriting the variable)
  apks="$apks
    avahi
    chrony
    conntrack-tools
    corerad
    dbus
    dhcp-server-vanilla
    dns-root-hints
    doas
    dropbear
    ethtool
    htop
    ifupdown-ng-ppp
    ifupdown-ng-wireguard
    iperf3
    irqbalance
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
