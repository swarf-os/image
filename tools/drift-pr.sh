#!/bin/bash
# The tested image differs from manifest/ (packages, units, repos or VERSION_ID): publish the
# new manifest on the fixed branch "manifest-drift" and open or update one pull request.
# Merging it means "I looked": .github/workflows/promote.yml then makes :stable point at the
# digest recorded in manifest/tested-digest. Usage: tools/drift-pr.sh sha256:DIGEST
# Needs git push and gh pr rights, and WORK from tools/manifest-check.sh.
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work/ci}
digest=$1
branch=manifest-drift
cd "$R"
git config user.name "swarf-os CI"
git config user.email "noreply@github.com"
git fetch -q origin main
# Runs are queued: this one may have built a commit that main has already moved past. A
# newer run is queued behind it and will detect the drift again, so open nothing here.
if [ -n "${GITHUB_SHA:-}" ] && [ "$(git rev-parse origin/main)" != "$GITHUB_SHA" ]; then
    echo "main moved since this run started: no drift pull request (a newer run decides)"
    exit 0
fi
git checkout -B "$branch" origin/main 2>/dev/null || git checkout -B "$branch"
cp "$WORK"/manifest-new/{packages,units,repos,version}.txt manifest/
cp "$WORK/manifest-new/info.txt" manifest/info.txt
echo "$digest" >manifest/tested-digest
git add manifest
git commit -qm "Manifest: update to tested image $digest"
git push -f origin "$branch"
{
    echo "The daily image passed every check, but it differs from \`manifest/\`, so \`:testing\` is published and \`:stable\` is held."
    echo
    echo "Tested digest: \`$digest\` (\`ghcr.io/swarf-os/image:testing\`)."
    echo
    echo "**Merging this pull request promotes exactly that digest to \`:stable\` (retag, no rebuild).** Before merging, boot it in a VM and look at: splash screen absent, task manager with titles, KWallet does not open, Overview off, System Settings → Software Update shows daily automatic updates."
    echo
    echo '<details><summary>Diff</summary>'
    echo
    echo '```diff'
    head -c 55000 "$WORK/manifest-diff.txt"
    echo '```'
    echo '</details>'
} >"$WORK/pr-body.md"
if gh pr view "$branch" --json state --jq .state 2>/dev/null | grep -q OPEN; then
    gh pr edit "$branch" --body-file "$WORK/pr-body.md"
else
    gh pr create --head "$branch" --base main --title "Manifest drift: review before promoting to :stable" --body-file "$WORK/pr-body.md"
fi
