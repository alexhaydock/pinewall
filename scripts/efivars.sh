#!/usr/bin/env bash
set -euo pipefail

command -v jq >/dev/null || exit 10

# Create tempfiles
VARS_TMP_A="$(mktemp)"
VARS_TMP_B="$(mktemp)"
OVERLAY_TMP="$(mktemp)"
trap 'rm -f "$VARS_TMP_A" "$VARS_TMP_B" "$OVERLAY_TMP"' EXIT

# Download JSON EFI vars store with Pinewall Secure Boot keys baked in
VARS_URL=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "https://api.github.com/repos/alexhaydock/pinewall-image/releases/latest" |
  grep -Po '"browser_download_url":\s*"\K[^"]+\.json' | head -n1)
curl -o "${VARS_TMP_A}" -sL "${VARS_URL}"

# tar-gzip the overlay tree and inject it as an EFI var
tar -czf "$OVERLAY_TMP" -C overlay .
jq --arg data "$(xxd -p -c 1000000 "$OVERLAY_TMP" | tr -d '\n')" \
  '.variables += [{"name": "overlay", "guid": "00000000-0000-0000-0000-000000000000", "attr": 7, "data": $data}]' \
  "${VARS_TMP_A}" > "${VARS_TMP_B}" && \
mv "${VARS_TMP_B}" "${VARS_TMP_A}"

# Declare comma-separated list of services to enable at runtime
SERVICES="corerad,dropbear,iperf3,kea-dhcp4,lockmodules,node-exporter,ulogd,unbound,unbound-exporter"
jq --arg data "$(echo ${SERVICES} | xxd -p -c 1000000 | tr -d '\n')" \
  '.variables += [{"name": "services", "guid": "00000000-0000-0000-0000-000000000000", "attr": 7, "data": $data}]' \
  "${VARS_TMP_A}" > "${VARS_TMP_B}" && \
mv "${VARS_TMP_B}" "${VARS_TMP_A}"

# Copy out completed vars file to local dir
cp "${VARS_TMP_A}" OVMF_VARS.json
