profile_pinewall_x86() {
  # Source the env vars from the "standard" profile below (see mkimg.base.sh)
  profile_standard

  # We don't want the kernel addons from the Standard profile, which includes
  # xtables-addons. We don't want any *tables stuff since we're fully nftables.
  kernel_addons=

  # Include AMD and Intel microcode updates (taken from the default "Extended" profile)
  boot_addons="amd-ucode intel-ucode"
  initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"

  # Don't forget to include $apks below to include the ones which we already read into this variable
  # from mkimg.base.sh (if we don't, we end up overwriting the variable)
  apks="$apks
    avahi
    conntrack-tools
    dbus
    dhcp-server-vanilla
    ethtool
    htop
    iperf3
    nano
    nftables
    nginx
    nload
    openssh
    sudo
    tcpdump
    tftp-hpa
    unbound
    vnstat
    wireguard-tools-wg
    "

  local _k _a
  for _k in $kernel_flavors; do
    apks="$apks linux-$_k"
    for _a in $kernel_addons; do
      apks="$apks $_a-$_k"
    done
  done

  # I tried excluding this but I think because it's included as a kernel addon by the
  # "base" profile, it gets pulled in anyway. So we might as well have it here so that
  # we've got the metapackage available.
  apks="$apks linux-firmware"

  # To make the packages downloaded above in the "apks=" variable available on boot, I have
  # adapted the .apkovl generation script below to generate us an appropriate APK overlay:
  #
  #   https://raw.githubusercontent.com/alpinelinux/aports/master/scripts/genapkovl-dhcp.sh
  #
  apkovl="genapkovl-pinewall.sh"
}
