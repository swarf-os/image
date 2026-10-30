#!/bin/bash
# Build the image from the current base: tools/ci-build.sh [TAG]   (default localhost/swarf-os:ci)
# Resolves quay.io/fedora/fedora-bootc:latest to a digest first, builds FROM that digest, and
# writes it to $WORK/base-digest (recorded in manifest/info.txt). Log in $WORK/build.log.
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work/ci}
tag=${1:-localhost/swarf-os:ci}
mkdir -p "$WORK"
digest=$(skopeo inspect --format '{{.Digest}}' docker://quay.io/fedora/fedora-bootc:latest)
echo "$digest" >"$WORK/base-digest"
if podman build --ulimit core=0 --build-arg "BASE=quay.io/fedora/fedora-bootc@$digest" -t "$tag" "$R" >"$WORK/build.log" 2>&1; then
    grep -E '^Checks|^Warnings' "$WORK/build.log" || true
    echo "OK build $tag (base $digest)"
else
    echo "FAILED build, last lines of $WORK/build.log:" >&2
    tail -40 "$WORK/build.log" >&2
    exit 1
fi
