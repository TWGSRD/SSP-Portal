#!/usr/bin/env bash
# Daily 焦點消息 refresh (Windows Task Scheduler -> run_pmm_sync.cmd -> this script).
#
# 1. Pull the PMM portal's 焦點消息 into pmm_news.js (sync_pmm_news.py).
# 2. If the list changed since the last auto-deploy, deploy to Cloudflare Pages.
#
# The deploy is built from the last COMMITTED version of the site (a temporary
# git worktree of main) plus the fresh pmm_news.js, so unreviewed local edits in
# this folder are never published by the scheduled job.
set -euo pipefail
cd "$(dirname "$0")"
export PYTHONIOENCODING=utf-8

STATE="reports/pmm_sync.last"
mkdir -p reports
echo "==== $(date '+%Y-%m-%d %H:%M:%S') PMM 焦點消息 sync ===="

python sync_pmm_news.py

NEW_HASH=$(sha256sum pmm_news.js | cut -d' ' -f1)
if [ -f "$STATE" ] && [ "$(cat "$STATE")" = "$NEW_HASH" ]; then
  echo "No change in 焦點消息 - nothing to deploy."
  exit 0
fi

WT="$(mktemp -d)/ssp-deploy"
cleanup() { git worktree remove --force "$WT" >/dev/null 2>&1 || true; }
trap cleanup EXIT

git worktree add --detach "$WT" main >/dev/null
cp pmm_news.js "$WT"/
[ -f .cf.env ] && cp .cf.env "$WT"/
# deploy_cloudflare.sh re-runs the sync if the script is present; it is gitignored,
# so the worktree simply deploys the pmm_news.js we just copied in.
if [ "${DRY_RUN:-}" = "1" ]; then
  echo "DRY_RUN: would deploy worktree $(git -C "$WT" log --oneline -1) + fresh pmm_news.js"
  exit 0
fi
(cd "$WT" && bash deploy_cloudflare.sh)

echo "$NEW_HASH" > "$STATE"
echo "Deployed updated 焦點消息."
