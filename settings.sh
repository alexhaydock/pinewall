#!/usr/bin/env sh

# Configure our Alpine repo and version here
# Do not include a trailing slash on the repo URL!
export ALPINEREPO=https://dl-cdn.alpinelinux.org/alpine
export ALPINEVER=3.15

# Autodiscover our current architecture
export ARCH="$(uname -m)"

# Assume we want the Pi build if we're building for an arm64 platform
if [ $ARCH == "aarch64" ]; then
  export PROFILENAME=pinewall_rpi
else
  export PROFILENAME=pinewall_x86
fi
