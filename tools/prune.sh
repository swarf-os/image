#!/bin/bash
# Retention: keep the newest KEEP (default 30) dated tags (:YYYYMMDD) of the image, delete the
# older ones. Never touches :testing, :stable, the cosign signatures (sha256-*.sig) or untagged
# versions (attestations, SBOMs): a version that carries any other tag is kept.
# Needs gh authenticated with packages:write. Usage: tools/prune.sh [--dry-run]
set -euo pipefail
ORG=${ORG:-swarf-os}
PKG=${PKG:-image}
KEEP=${KEEP:-30}
dry=${1:-}
gh api --paginate "orgs/$ORG/packages/container/$PKG/versions" |
    jq -r '.[] | select(.metadata.container.tags | length > 0)
        | select(all(.metadata.container.tags[]; test("^[0-9]{8}$")))
        | [.metadata.container.tags[0], .id] | @tsv' |
    sort -r | tail -n +$((KEEP + 1)) |
    while IFS=$'\t' read -r tag id; do
        echo "delete $tag (version $id)"
        [ "$dry" = --dry-run ] || gh api -X DELETE "orgs/$ORG/packages/container/$PKG/versions/$id"
    done
