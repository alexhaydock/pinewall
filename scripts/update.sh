#!/usr/bin/env bash
set -euo pipefail

# Check for prerequisites
command -v curl >/dev/null || exit 10
command -v jq >/dev/null || exit 10

# Fetch latest release metadata (one API call)
RELEASE=$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "https://api.github.com/repos/alexhaydock/pinewall-image/releases/latest")

# Extract asset URLs
EFI_URL=$(jq -r '.assets[].browser_download_url | select(endswith(".efi"))' <<< "$RELEASE" | head -n1)
VARS_URL=$(jq -r '.assets[].browser_download_url | select(endswith(".json"))' <<< "$RELEASE" | head -n1)

# Download UKI image
curl -fsSL -o pinewall-latest_uki.efi.download "$EFI_URL"
[[ -f pinewall-latest_uki.efi ]] && mv pinewall-latest_uki.efi pinewall-latest_uki_prev.efi
mv pinewall-latest_uki.efi.download pinewall-latest_uki.efi

# Download template vars store
curl -fsSL -o pinewall-latest_vars.json.download "$VARS_URL"
[[ -f pinewall-latest_vars.json ]] && mv pinewall-latest_vars.json pinewall-latest_vars_prev.json
mv pinewall-latest_vars.json.download pinewall-latest_vars.json
