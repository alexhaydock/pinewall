#!/usr/bin/env sh
set -eu

# The variables used here are defined in the ENV vars of
# the respective Dockerfile being used to run this script:
./mkimage.sh \
  --tag $ALPINETAG \
  --outdir /tmp/images \
  --workdir /tmp/cache \
  --arch $ARCH \
  --repository $ALPINEREPO/$ALPINETAG/main \
  --profile $PROFILENAME
