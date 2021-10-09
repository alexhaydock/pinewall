profile_pinewall_rpi() {
  # Source the env vars from the "rpi" profile below (see mkimg.arm.sh)
  profile_rpi

  # We can't change the default hostname of the Pi here like we do with our x86 release, because
  # the build scripts use the default ("rpi") hostname of the Pi as a trigger to decide whether
  # they need to inject certain Pi-specific stuff (like config.txt and cmdline.txt into the built
  # image .tar.gz).
  #
  # https://gitlab.alpinelinux.org/alpine/aports/-/blob/a888f0d762e845e89b07396ff9e8d1e93b58df3e/scripts/mkimg.arm.sh#L84

  # Don't forget to include $apks below to include the ones which we already read into this variable
  # from mkimg.base.sh (if we don't, we end up overwriting the variable)
  apks="$apks
    alpine-base
    avahi
    chrony
    conntrack-tools
    dbus
    dhcp-server-vanilla
    dns-root-hints
    ethtool
    htop
    ifupdown-ng-ppp
    iperf3
    nano
    nftables
    nginx
    nload
    openssh
    openssl
    ppp-pppoe
    sudo
    tcpdump
    tftp-hpa
    unbound
    wireguard-tools-wg
    "

  local _k _a
  for _k in $kernel_flavors; do
    apks="$apks linux-$_k"
    for _a in $kernel_addons; do
      apks="$apks $_a-$_k"
    done
  done

  # To make the packages downloaded above in the "apks=" variable available on boot, I have
  # adapted the .apkovl generation script below to generate us an appropriate APK overlay:
  #
  #   https://raw.githubusercontent.com/alpinelinux/aports/master/scripts/genapkovl-dhcp.sh
  #
  apkovl="genapkovl-pinewall.sh"
}
