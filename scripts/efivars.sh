#!/usr/bin/env bash
set -euo pipefail

# Check we have been passed an argument
if [[ -z "${1}" ]]; then
    echo "Usage: $0 <argument>" >&2
    exit 1
fi

# Check for pre-reqs
command -v jq >/dev/null || exit 10
command -v xxd >/dev/null || exit 10

# Source config from env file
source "config/${1}.env"

# Create tempfiles
VARS_TMP_A="$(mktemp)"
VARS_TMP_B="$(mktemp)"
OVERLAY_TMP="$(mktemp)"
trap 'rm -f "$VARS_TMP_A" "$VARS_TMP_B" "$OVERLAY_TMP"' EXIT

# Copy predownloaded vars template with Secure Boot keys etc
cp pinewall-latest_vars.json "${VARS_TMP_A}"

# tar-gzip the overlay tree for our specified directory and inject it as an EFI var
tar --owner=0 --group=0 --numeric-owner -czf "$OVERLAY_TMP" -C "config/${1}" .
jq --arg data "$(xxd -p -c 1000000 "$OVERLAY_TMP" | tr -d '\n')" \
  '.variables += [{"name": "overlay", "guid": "00000000-0000-0000-0000-000000000000", "attr": 7, "data": $data}]' \
  "${VARS_TMP_A}" > "${VARS_TMP_B}" && \
mv "${VARS_TMP_B}" "${VARS_TMP_A}"

# Declare comma-separated list of services to enable at runtime
SVC="${SERVICES}"
jq --arg data "$(echo ${SVC} | xxd -p -c 1000000 | tr -d '\n')" \
  '.variables += [{"name": "services", "guid": "00000000-0000-0000-0000-000000000000", "attr": 7, "data": $data}]' \
  "${VARS_TMP_A}" > "${VARS_TMP_B}" && \
mv "${VARS_TMP_B}" "${VARS_TMP_A}"

# Copy out completed vars file to local dir
[[ -f "pinewall-${VMSUFFIX}_config.json" ]] && mv "pinewall-${VMSUFFIX}_config.json" "pinewall-${VMSUFFIX}_config_prev.json"
cp "${VARS_TMP_A}" "pinewall-${VMSUFFIX}_config.json"
