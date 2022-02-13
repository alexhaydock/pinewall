#!/usr/bin/env sh

# Configure our Alpine repo and version here
# Do not include a trailing slash on the repo URL!
export ALPINEREPO="https://dl-cdn.alpinelinux.org/alpine"

# Configure the Alpine version we're targeting here.
export ALPINEVER="edge"
#export ALPINEVER="3.15"

# Autodiscover our current architecture
export ARCH="$(uname -m)"

# Assume we want the Pi build if we're building for an arm64 platform
if [ $ARCH == "aarch64" ]; then
  export PROFILENAME=pinewall_rpi
else
  export PROFILENAME=pinewall_x86
fi

# Use our ALPINEVER variable to work out some others
if [ $ALPINEVER == "edge" ]; then
  export ALPINETAG=$ALPINEVER
  export ALPINEGIT=master
else
  export ALPINETAG=v$ALPINEVER
  export ALPINEGIT=$ALPINEVER-stable
fi
