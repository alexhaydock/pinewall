#!/bin/sh
set -eu

./mkimage.sh --tag v$ALPINEVER --outdir /tmp/images --workdir /tmp/cache --arch $TARGETARCH --repository $ALPINEREPO/v$ALPINEVER/main --profile $PROFILENAME
