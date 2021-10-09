#!/bin/sh
set -eu

./mkimage.sh --tag v$ALPINEVER --outdir /tmp/images --workdir /tmp/cache --arch $TARGETARCH --repository $ALPINEREPO/v$ALPINEVER/main --repository $ALPINEREPO/v$ALPINEVER/community --profile $PROFILENAME
