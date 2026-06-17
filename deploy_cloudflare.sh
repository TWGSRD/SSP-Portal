#!/usr/bin/env bash
# Deploy the SSP Portal to Cloudflare Pages (EXTERNAL site).
#
# Builds a clean dist/ containing ONLY the files the website needs, so that
# credentials (ssp-portal-*.json), source scripts (*.py), and internal data
# (*.pptx, *.xlsx, cn_spn_list.csv, spn_providers.*) are NEVER uploaded to the
# public site.
#
# Usage:
#   npx wrangler login          # one-time, opens browser OAuth
#   bash deploy_cloudflare.sh    # build dist/ and deploy
#
# After the first deploy, re-running this script re-uploads the latest build.
set -euo pipefail
cd "$(dirname "$0")"

# Load Cloudflare credentials (token + account id) from gitignored .cf.env
if [ -f .cf.env ]; then
  set -a; . ./.cf.env; set +a
fi

PROJECT="ssp-portal"          # Cloudflare Pages project name
DIST="dist"

echo "==> Building clean dist/ ..."
rm -rf "$DIST"
mkdir -p "$DIST"

# --- Files the site actually references ---
cp index.html          "$DIST"/
cp contact.html        "$DIST"/
cp prov_data.js        "$DIST"/
cp spn-logo.png        "$DIST"/
cp "Tier 1 service image.png" "$DIST"/

# --- Asset folders ---
cp -r Banner  "$DIST"/
cp -r Logos   "$DIST"/
cp -r QRcode  "$DIST"/
cp -r flags   "$DIST"/

# Safety: make sure no credential / internal file slipped in
find "$DIST" \( -name "*.json" -a ! -name "image_mapping.json" \) -name "ssp-portal-*" -delete 2>/dev/null || true

echo "==> dist/ contents:"
du -sh "$DIST" 2>/dev/null || true
find "$DIST" -maxdepth 1 -type f | sort

echo "==> Deploying to Cloudflare Pages project '$PROJECT' ..."
npx --yes wrangler pages deploy "$DIST" --project-name "$PROJECT" --commit-dirty=true

echo "==> Done."
