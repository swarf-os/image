#!/bin/bash
# Boot an image in a throwaway VM and run the checks: tools/boot-test.sh IMAGE
# IMAGE is a local name or a registry reference (best: ghcr.io/swarf-os/image@sha256:...).
# Builds tests/Containerfile on top of it (adds sshd), boots it with bcvk and runs
# tests/check-config.sh and tests/boot-checks.sh over ssh. bcvk comes from $BCVK or the PATH.
# The ephemeral VM has no firmware Secure Boot: the kernel signature is checked by
# tools/manifest-check.sh instead. Log in $WORK/boot-test.log.
set -euo pipefail
image=$1
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work/ci}
BCVK=${BCVK:-bcvk}
mkdir -p "$WORK"
log=$WORK/boot-test.log
: >"$log"

podman build --build-arg "BASE=$image" -t localhost/swarf-os:test "$R/tests" >>"$log" 2>&1
payload=$(
    echo "export EXPECTED_UNITS=$(base64 -w0 "$R/manifest/units.txt")"
    echo 'export LANG=C.UTF-8'
    echo 'rc=0'
    cat "$R/tests/check-config.sh" | sed 's/^exit "\$fail"$/[ "$fail" = 0 ] || rc=1/'
    sed 's/^exit "\$fail"$/[ "$fail" = 0 ] || rc=1/' "$R/tests/boot-checks.sh"
    echo 'exit $rc'
)
if "$BCVK" ephemeral run-ssh localhost/swarf-os:test -- \
    "echo $(printf '%s' "$payload" | base64 -w0) | base64 -d | bash" >>"$log" 2>&1; then
    echo "OK boot test"
else
    echo "FAILED boot test, last lines of $log:" >&2
    tail -30 "$log" >&2
    exit 1
fi
