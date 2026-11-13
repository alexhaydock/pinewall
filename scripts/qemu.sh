#!/usr/bin/env bash
set -euo pipefail

# Copy vars to temp dir
VARS_TMP="$(mktemp)"
trap 'rm -f "$VARS_TMP"' EXIT
cp -fv "OVMF_VARS.json" "${VARS_TMP}"

# Discover EFI
EFI_URL=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "https://api.github.com/repos/alexhaydock/pinewall-image/releases/latest" |
  grep -Po '"browser_download_url":\s*"\K[^"]+\.efi' | head -n1)
EFI_FILE="$(basename ${EFI_URL})"
test -f ${EFI_FILE} || curl -o "${EFI_FILE}" -L "${EFI_URL}"

# Test in QEMU with UEFI firmware that supports PV vars
qemu-system-x86_64 \
    -name pinewall \
    -m 1G \
    -machine q35,smm=off,vmport=off,accel=kvm \
    -drive if=pflash,format=raw,unit=0,file=/usr/share/edk2/ovmf/OVMF.qemuvars.fd,readonly=on \
    -device uefi-vars-x64,jsonfile="${VARS_TMP}" \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -device virtio-net-pci,netdev=nic1 \
    -netdev user,id=nic1 \
    -device virtio-net-pci,netdev=nic2 \
    -netdev user,id=nic2 \
    -kernel ${EFI_FILE} \
    -append "console=ttyS0" \
    -nographic
