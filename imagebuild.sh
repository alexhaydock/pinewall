#!/bin/sh
set -eu

# The variables used here are defined in the ENV vars of
# the respective Dockerfile being used to run this script:
./mkimage.sh \
  --tag v$ALPINEVER \
  --outdir /tmp/images \
  --workdir /tmp/cache \
  --arch $TARGETARCH \
  --repository $ALPINEREPO/v$ALPINEVER/main \
  --profile $PROFILENAME
