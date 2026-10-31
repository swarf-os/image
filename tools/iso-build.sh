#!/bin/bash
# Build the installer ISO: tools/iso-build.sh BASE [PAYLOAD_SOURCE]
#   BASE            the swarf-os image to start from and to install, best a digest
#                   (ghcr.io/swarf-os/image@sha256:...), or a local name (localhost/swarf-os:dev)
#   PAYLOAD_SOURCE  skopeo source of that same image (default: docker://BASE, or
#                   containers-storage:BASE for a localhost/ name)
# Rootless, no sudo. Result in $WORK/iso/out: swarf-os-<VERSION_ID>-x86_64.iso and SHA256SUMS
# (signing is the workflow's job). Work files and logs in $WORK/iso (default ../work/iso).
# Titanoboa's build_iso.sh is fetched at a pinned commit and checked by sha256 (Apache-2.0, ADR 0019).
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work}/iso
base=$1
case $base in localhost/*) src=containers-storage:$base ;; *) src=docker://$base ;; esac
src=${2:-$src}
TITANOBOA_SHA=5c457c3d0518bd17e754be0fd98a60d29d26abb4
BUILD_ISO_SHA256=a73e0a11731880bc6272650371427564aaf565d5dc0d9e51dd793d79b351dcba
log=$WORK/iso-build.log
rm -rf "$WORK/payload" "$WORK/out" "$WORK/work"
mkdir -p "$WORK/out" "$WORK/work"
: >"$log"
step() { echo "== $* ($(date +%H:%M:%S))" | tee -a "$log"; }

version_id=$(podman run --rm --entrypoint sh "$base" -c '. /usr/lib/os-release; echo "$VERSION_ID"')
label=SWARF-OS-$version_id    # ISO volume labels hold 32 characters at most
iso=swarf-os-$version_id-x86_64.iso

step "payload: $src -> $WORK/payload"
skopeo copy "$src" "oci:$WORK/payload" >>"$log" 2>&1

step "live image (Anaconda, Flatpaks, payload)"
podman build --cap-add sys_admin --security-opt label=disable --ulimit core=0 \
    --build-context "payload=$WORK/payload" --build-arg "BASE=$base" --build-arg "ISO_LABEL=$label" \
    -f "$R/iso/Containerfile" -t localhost/swarf-os-live:iso "$R" >>"$log" 2>&1 || {
    echo "FAILED live image build, last lines of $log:" >&2; tail -40 "$log" >&2; exit 1; }

step "Titanoboa build_iso.sh @ ${TITANOBOA_SHA:0:12}"
curl -fsSL -o "$WORK/build_iso.sh" \
    "https://raw.githubusercontent.com/ublue-os/titanoboa/$TITANOBOA_SHA/build_iso.sh"
echo "$BUILD_ISO_SHA256  $WORK/build_iso.sh" | sha256sum -c - >>"$log"
chmod +x "$WORK/build_iso.sh"
podman run --rm --cap-add sys_admin --security-opt label=disable \
    -v "$WORK/build_iso.sh:/src/build_iso.sh:ro" \
    --mount "type=image,source=localhost/swarf-os-live:iso,dst=/rootfs" \
    -v "$WORK/work:/work" -v "$WORK/out:/output" \
    quay.io/fedora/fedora:latest /src/build_iso.sh >>"$log" 2>&1 || {
    echo "FAILED Titanoboa, last lines of $log:" >&2; tail -40 "$log" >&2; exit 1; }

mv "$WORK/out/$label.iso" "$WORK/out/$iso"
(cd "$WORK/out" && sha256sum "$iso" >SHA256SUMS)
rm -rf "$WORK/work"
ls -l "$WORK/out"
echo "OK $WORK/out/$iso"
