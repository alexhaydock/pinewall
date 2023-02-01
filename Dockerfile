FROM docker.io/library/alpine:edge as builder

# Run an APK update so we have a recent cache ready in the Docker image
# (if we don't do this then the "apk fetch" stages of the build that fetch
# packages like the Raspberry Pi bootloader will fail).
RUN apk update

# Install build deps
# We still need to layer the sudo package into this builder image
# instead of doas, as abuild-keygen expects it to be there
RUN apk add \
  alpine-conf \
  alpine-sdk \
  apk-tools \
  build-base \
  busybox \
  dosfstools \
  fakeroot \
  grub-efi \
  mtools \
  squashfs-tools \
  sudo \
  tzdata \
  xorriso

# We can't use the build/builder user that most examples use because
# then it can't access the pseudo device that xorriso creates during
# the ISO build process:
#     https://stackoverflow.com/a/58297342
RUN addgroup root abuild

RUN mkdir /tmp/abuild
WORKDIR /tmp/abuild

RUN abuild-keygen -i -a -n

# Clone the aports repo for our specific branch
# If building from Alpine Edge, we need to use the master branch
RUN git clone --depth 1 --branch master https://gitlab.alpinelinux.org/alpine/aports.git

# Add our custom profile into the abuild scripts directory
COPY mkimg.pinewall_rpi.sh /tmp/abuild/aports/scripts/mkimg.pinewall_rpi.sh

# Make our scripts executable
RUN chmod +x /tmp/abuild/aports/scripts/mkimage.sh
RUN chmod +x /tmp/abuild/aports/scripts/mkimg.pinewall_rpi.sh

# Enter the script directory
WORKDIR /tmp/abuild/aports/scripts

# Create our output dir
RUN mkdir /tmp/images

# Build our image
RUN ./mkimage.sh --tag edge --outdir /tmp/images --workdir /tmp/cache --arch aarch64 --repository https://dl-cdn.alpinelinux.org/alpine/edge/main --profile pinewall_rpi

# List the contents of our image directory
RUN ls -lah /tmp/images

# --------------------------------------------- #

FROM docker.io/library/alpine:edge as overlay

# Bind mount a directory into /tmp/overlays when running this image
# to output a built overlay into it

# Add some packages that we'll use as sources for overlay data
RUN apk --no-cache add tzdata

# Add our custom APK overlay script
COPY genapkovl-pinewall.sh /genapkovl-pinewall.sh
RUN chmod +x /genapkovl-pinewall.sh

# Add in all our configs
COPY config/etc/ /tmp/etc/

# Create overlays directory to store our outputted overlay
RUN mkdir -p /tmp/overlays

RUN ./genapkovl-pinewall.sh

# --------------------------------------------- #

# Copy our built image into a new container
FROM docker.io/library/alpine:edge

# Install mtools to build FAT32 images without mounting them
RUN apk --no-cache add mtools

# Copy our built images and settings from the build container
COPY --from=builder /tmp/images/alpine-pinewall_rpi-edge-aarch64.tar.gz /tmp/images/pinewall.tar.gz

# Set workdir
WORKDIR /opt

# Extract the .tar.gz that Alpine's script builds for us
RUN mkdir /opt/pinewall
RUN tar -xvf /tmp/images/pinewall.tar.gz --no-same-owner -C /opt/pinewall

# Import our overlay from the overlay build container
COPY --from=overlay /tmp/overlays/pinewall.apkovl.tar.gz /opt/pinewall/pinewall.apkovl.tar.gz

# Add in our Pi firmware tweaks
COPY usercfg.txt /opt/pinewall/usercfg.txt

# Build a FAT32 image with our overlay and the contents of our archive
RUN dd if=/dev/zero of=/opt/pinewall.img bs=1M count=128
RUN mformat -i /opt/pinewall.img ::
RUN mcopy -si /opt/pinewall.img /opt/pinewall/* ::
RUN mdir -i /opt/pinewall.img ::

# --------------------------------------------- #

# We don't set an entrypoint in this container as our preferred method for
# retrieving the built image from it is to use `podman create` to create an
# instance of the container, and then `podman cp` to copy /tmp/pinewall.img
# to the host machine.
