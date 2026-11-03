#!/bin/bash
# Publish one ISO release to the R2 bucket and delete the previous one (ADR 0029):
#   tools/r2-upload.sh DIR     DIR holds one *.iso, SHA256SUMS and SHA256SUMS.bundle
# Environment: CLOUDFLARE_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY (an R2 token with
# "Object Read & Write" on the bucket only). If none is set, the upload is skipped with a warning
# (repository without Cloudflare secrets); if only some are, it fails.
# Optional: R2_BUCKET (swarf-os-iso), R2_JURISDICTION (eu: the bucket's jurisdiction, empty for
# none), R2_ENDPOINT (tests), R2_MAX_BYTES (8000000000).
#
# Order: upload into a new folder YYYYMMDD-HHMM/ (ISO, SHA256SUMS, then the bundle, which marks
# the release complete for the Worker), read them back and compare, then delete every other release
# folder, whatever its file names (a Fedora 45 ISO name does not leave the 44 one behind). If any
# step fails before the deletion, the previous release stays online. Finally the bucket size is
# checked against R2_MAX_BYTES: R2 is free up to 10 GB-month and has no spending cap.
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work}
RCLONE_VERSION=1.75.2
RCLONE_SHA256=349ac8fba6ff65d6247043f1750cdcb518ec5d500ef91463a10d37c0ccdf3702
BUCKET=${R2_BUCKET:-swarf-os-iso}
JURISDICTION=${R2_JURISDICTION-eu}
MAX_BYTES=${R2_MAX_BYTES:-8000000000}
dir=$1

set_count=0
for v in CLOUDFLARE_ACCOUNT_ID R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY; do [ -n "${!v:-}" ] && set_count=$((set_count + 1)); done
if [ $set_count = 0 ]; then
    echo "::warning::R2 secrets are not set: the ISO is not published (ADR 0029)."
    exit 0
fi
[ $set_count = 3 ] || { echo "ERROR: CLOUDFLARE_ACCOUNT_ID, R2_ACCESS_KEY_ID and R2_SECRET_ACCESS_KEY must all be set" >&2; exit 1; }

cd "$dir"
isos=(*.iso)
[ ${#isos[@]} = 1 ] && [ -f "${isos[0]}" ] || { echo "ERROR: expected exactly one .iso in $dir" >&2; exit 1; }
iso=${isos[0]}
[ -s SHA256SUMS ] && [ -s SHA256SUMS.bundle ] || { echo "ERROR: SHA256SUMS or SHA256SUMS.bundle missing in $dir" >&2; exit 1; }
sha256sum -c --quiet SHA256SUMS

# rclone, pinned (Cloudflare documents rclone for R2; v1.59 or later)
rclone=$WORK/bin/rclone
if ! "$rclone" version 2>/dev/null | grep -q "^rclone v$RCLONE_VERSION\$"; then
    mkdir -p "$WORK/bin"
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/rclone.zip" "https://downloads.rclone.org/v$RCLONE_VERSION/rclone-v$RCLONE_VERSION-linux-amd64.zip"
    echo "$RCLONE_SHA256  $tmp/rclone.zip" | sha256sum -c --quiet -
    python3 -m zipfile -e "$tmp/rclone.zip" "$tmp"    # unzip is not on every runner image
    install -m 0755 "$tmp/rclone-v$RCLONE_VERSION-linux-amd64/rclone" "$rclone"
    rm -rf "$tmp"
fi

# Remote "r2:" from the environment, no config file (rclone docs, "Config file" / environment).
export RCLONE_CONFIG=/dev/null
export RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare RCLONE_CONFIG_R2_ACL=private
# A bucket in a jurisdiction is reached only through that jurisdiction's endpoint (R2 docs, data location).
export RCLONE_CONFIG_R2_ENDPOINT=${R2_ENDPOINT:-https://$CLOUDFLARE_ACCOUNT_ID.${JURISDICTION:+$JURISDICTION.}r2.cloudflarestorage.com}
export RCLONE_CONFIG_R2_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID RCLONE_CONFIG_R2_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true    # token scoped to objects (Cloudflare rclone page)
# Multipart above 64 MiB: the ISO (~5 GB) is ~75 parts of the same size (R2: 5 MiB minimum,
# 10,000 parts at most, one request at most 5 GiB).
export RCLONE_S3_CHUNK_SIZE=${RCLONE_S3_CHUNK_SIZE:-64M} RCLONE_S3_UPLOAD_CUTOFF=${RCLONE_S3_UPLOAD_CUTOFF:-64M}
export RCLONE_RETRIES=3 RCLONE_LOW_LEVEL_RETRIES=10 RCLONE_STATS_LOG_LEVEL=NOTICE RCLONE_STATS=2m RCLONE_STATS_ONE_LINE=true
rc() { "$rclone" "$@"; }

release=$(date -u +%Y%m%d-%H%M)
dest=r2:$BUCKET/$release
echo "== upload $iso to $BUCKET/$release ($(date -u +%H:%M:%S))"
for f in "$iso" SHA256SUMS SHA256SUMS.bundle; do
    rc copyto "$f" "$dest/$f"
done
# Read the files back and compare the bytes: a multipart object's ETag is not an MD5, and the
# previous release is deleted right after (R2 egress is free; ~5 GB, a few minutes).
echo "== read back and compare ($(date -u +%H:%M:%S))"
rc check --one-way --download . "$dest" --include "$iso" --include SHA256SUMS --include SHA256SUMS.bundle

echo "== delete the previous releases"
while read -r d; do
    d=${d%/}
    if [[ $d =~ ^[0-9]{8}-[0-9]{4}$ ]] && [ "$d" != "$release" ]; then
        echo "delete $d/"
        rc delete "r2:$BUCKET/$d"
    fi
done < <(rc lsf --dirs-only "r2:$BUCKET")

others=$(rc lsf "r2:$BUCKET" --exclude '/[0-9]*-[0-9]*/**')
[ -z "$others" ] || echo "::warning::objects outside a release folder (left alone, they cost storage): $others"
bytes=$(rc size --json "r2:$BUCKET" | grep -o '"bytes":[0-9]*' | cut -d: -f2)
echo "bucket $BUCKET holds $bytes bytes"
if [ "$bytes" -gt "$MAX_BYTES" ]; then
    echo "::error::bucket $BUCKET holds $bytes bytes, above $MAX_BYTES: R2 storage beyond 10 GB-month is billed."
    exit 1
fi
echo "OK $BUCKET/$release/$iso"
