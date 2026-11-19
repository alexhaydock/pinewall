#!/usr/bin/env bash
set -euo pipefail

# Check we have been passed an argument
if [[ -z "${1}" ]]; then
    echo "Usage: $0 <argument>" >&2
    exit 1
fi

# Check for pre-reqs
command -v qemu-system-x86_64 >/dev/null || exit 10

# Source config from env file
source "config/${1}.env"

# Define our MAC generator
# We need this because the bridge-helper scripts allocate MACs
# incrementally on a per-VM basis rather than keeping track of
# allocated addresses globally - so it's entirely possible to
# end up with duplicate MACs on the same bridge with a complex
# router config like this
generate_mac() {
    printf '02:%02x:%02x:%02x:%02x:%02x\n' \
        "$(( RANDOM % 256 ))" \
        "$(( RANDOM % 256 ))" \
        "$(( RANDOM % 256 ))" \
        "$(( RANDOM % 256 ))" \
        "$(( RANDOM % 256 ))"
}

# Generate MACs for this VM invocation
MAC1=$(generate_mac)
MAC2=$(generate_mac)

# Copy vars to temp dir
VARS_TMP="$(mktemp)"
trap 'rm -f "$VARS_TMP"' EXIT
cp -fv "pinewall-${VMSUFFIX}_config.json" "${VARS_TMP}"

# Boot Pinewall UKI in QEMU with EFI firmware that supports passing
# PV vars into the VM using a JSON file
#
# We invoke qemu-bridge-helper with `vhost=on` directly to ensure
# we're using vhost-net which moves most of the packet processing
# for the VirtIO NICs into the host kernel and out of QEMU userspace.
# Test with:
#    PID=$(pgrep -n qemu-system-x86_64) ls -l /proc/$PID/fd | grep vhost
qemu-system-x86_64 \
    -name "pinewall-${VMSUFFIX}" \
    -machine q35,smm=off,vmport=off,accel=kvm \
    -cpu host \
    -smp 4 \
    -m 1G \
    -drive if=pflash,format=raw,unit=0,file="${OVMF}",readonly=on \
    -device uefi-vars-x64,jsonfile="${VARS_TMP}" \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -netdev tap,id=nic1,br="${VMNIC1}",helper=/usr/lib/qemu/qemu-bridge-helper,vhost=on \
    -device virtio-net-pci,netdev=nic1,mac="${MAC1}" \
    -netdev tap,id=nic2,br="${VMNIC2}",helper=/usr/lib/qemu/qemu-bridge-helper,vhost=on \
    -device virtio-net-pci,netdev=nic2,mac="${MAC2}" \
    -display none \
    -serial mon:stdio \
    -kernel pinewall-latest_uki.efi -append console=ttyS0
