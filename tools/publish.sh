#!/bin/bash
# Push a local image as :testing and :YYYYMMDD: tools/publish.sh LOCAL_IMAGE
# Needs a registry login (podman login). Writes the pushed digest to $WORK/digest and prints it.
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work/ci}
REPO=${REPO:-ghcr.io/swarf-os/image}
local_image=$1
mkdir -p "$WORK"
podman push --digestfile "$WORK/digest" "$local_image" "docker://$REPO:testing"
digest=$(cat "$WORK/digest")
skopeo copy --all --preserve-digests "docker://$REPO@$digest" "docker://$REPO:$(date -u +%Y%m%d)"
echo "$digest"
