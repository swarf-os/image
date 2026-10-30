#!/bin/bash
# Make :stable point at a tested digest, without rebuilding: tools/promote.sh sha256:...
# Same repository, so only the manifest tag is written; the digest must come out identical.
set -euo pipefail
REPO=${REPO:-ghcr.io/swarf-os/image}
digest=$1
skopeo copy --all --preserve-digests "docker://$REPO@$digest" "docker://$REPO:stable"
got=$(skopeo inspect --format '{{.Digest}}' "docker://$REPO:stable")
[ "$got" = "$digest" ] || { echo "ERROR: :stable is $got, expected $digest" >&2; exit 1; }
echo "OK :stable = $digest"
