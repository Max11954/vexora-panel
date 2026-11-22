#!/usr/bin/env bash
# Creates your own panel repo: upstream FeatherPanel + vexora-panel.patch, then pushes it to GitHub.
#
# 1) Create an EMPTY public repo on GitHub (no README), e.g. MaxEH/vexora-panel
# 2) Run:  ./setup-fork.sh MaxEH/vexora-panel
#
# Needs: git, and push access to that repo (SSH key, `gh auth login`, or a credential helper).
set -euo pipefail

SLUG="${1:-}"
if [[ ! "$SLUG" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "Usage: $0 <github-owner>/<repo>   e.g. $0 MaxEH/vexora-panel" >&2
    exit 1
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
PATCH="${HERE}/vexora-panel.patch"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/MythicalLTD/FeatherPanel.git}"
REPO_URL="${REPO_URL:-https://github.com/${SLUG}.git}"
WORKDIR="${HERE}/${2:-vexora-panel}"

[ -f "$PATCH" ] || { echo "vexora-panel.patch must be next to this script." >&2; exit 1; }
[ ! -e "$WORKDIR" ] || { echo "$WORKDIR already exists." >&2; exit 1; }

git clone --depth 1 "$UPSTREAM_URL" "$WORKDIR"
cd "$WORKDIR"
UPSTREAM_SHA="$(git rev-parse --short HEAD)"
rm -rf .git

git apply "$PATCH"
grep -rIl "OWNER/REPO" . --exclude-dir=node_modules | xargs sed -i "s|OWNER/REPO|${SLUG}|g"
# Upstream CI would try to publish to MythicalLTD registries; keep only our release workflow.
find .github/workflows -type f ! -name 'vexora-release.yml' -delete

cat > VEXORA.md <<DOC
# Panel (based on FeatherPanel ${UPSTREAM_SHA})

Install (Debian 11+/Ubuntu 22.04+):

    curl -fsSL https://raw.githubusercontent.com/${SLUG}/main/install.sh | sudo bash

Update: use the update button in the admin panel, or run \`sudo vexora-update\`.

Every push to \`main\` creates a new GitHub release automatically.
Licensed under AGPL-3.0 (see LICENSE); based on FeatherPanel by Mythical Systems.
DOC

git init -q -b main
git add -A
git commit -q -m "Initial import: FeatherPanel ${UPSTREAM_SHA} + panel patches"
git remote add origin "$REPO_URL"
git push -u origin main

echo
echo "Done: https://github.com/${SLUG}"
echo "In ~1-2 minutes the 'Vexora release' action publishes the first release; after that the install command works."
echo "Make sure: repo is public, Actions are enabled, and Settings > Actions > General > Workflow permissions = Read and write."
