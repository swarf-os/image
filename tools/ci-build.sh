#!/bin/bash
# Build the image from the current base: tools/ci-build.sh [TAG]   (default localhost/swarf-os:ci)
# Resolves quay.io/fedora/fedora-bootc:latest to a digest first, builds FROM that digest, and
# writes it to $WORK/base-digest (recorded in manifest/info.txt). Log in $WORK/build.log.
# In CI the version label becomes <base version>.<run number>, so Discover offers every published
# build, not only a new Fedora version (docs/adr/0043).
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work/ci}
tag=${1:-localhost/swarf-os:ci}
mkdir -p "$WORK"
digest=$(skopeo inspect --format '{{.Digest}}' docker://quay.io/fedora/fedora-bootc:latest)
echo "$digest" >"$WORK/base-digest"
label=()
if [ -n "${GITHUB_RUN_NUMBER:-}" ]; then
    base_version=$(skopeo inspect --format '{{index .Labels "org.opencontainers.image.version"}}' \
        "docker://quay.io/fedora/fedora-bootc@$digest")
    [ -n "$base_version" ] || { echo "FAILED: the base image has no version label" >&2; exit 1; }
    label=(--label "org.opencontainers.image.version=$base_version.$GITHUB_RUN_NUMBER")
fi
if podman build --ulimit core=0 --build-arg "BASE=quay.io/fedora/fedora-bootc@$digest" "${label[@]}" -t "$tag" "$R" >"$WORK/build.log" 2>&1; then
    grep -E '^Checks|^Warnings' "$WORK/build.log" || true
    echo "OK build $tag (base $digest, version $(podman image inspect --format '{{index .Labels "org.opencontainers.image.version"}}' "$tag"))"
else
    echo "FAILED build, last lines of $WORK/build.log:" >&2
    tail -40 "$WORK/build.log" >&2
    exit 1
fi
