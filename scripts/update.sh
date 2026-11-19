#!/usr/bin/env bash
set -euo pipefail

# Check for pre-reqs
command -v curl >/dev/null || exit 10

# Download latest UKI image
EFI_URL=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "https://api.github.com/repos/alexhaydock/pinewall-image/releases/latest" |
  grep -Po '"browser_download_url":\s*"\K[^"]+\.efi' | head -n1)
curl -o "pinewall-latest_uki.efi" -L "${EFI_URL}"

# Download latest template vars store with Pinewall Secure Boot keys baked in
VARS_URL=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2026-03-10" \
  "https://api.github.com/repos/alexhaydock/pinewall-image/releases/latest" |
  grep -Po '"browser_download_url":\s*"\K[^"]+\.json' | head -n1)
curl -o "pinewall-latest_vars.json" -sL "${VARS_URL}"
