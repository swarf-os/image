#!/bin/bash
# Boot-test checks, run as root inside the booted test image (tools/boot-test.sh sends them over
# ssh together with tests/check-config.sh). EXPECTED_UNITS is the base64 of manifest/units.txt.
# The test image only adds sshd (tests/Containerfile), which is left out of the comparison.
fail=0
systemctl is-system-running --wait >/dev/null 2>&1 || true
check() { [ "$2" = "$3" ] || { echo "FAIL $1: expected '$2', got '$3'"; fail=1; }; }

check "plasmalogin.service" active "$(systemctl is-active plasmalogin.service 2>&1)"
check "graphical.target" active "$(systemctl is-active graphical.target 2>&1)"
check "failed units" "" "$(systemctl --failed --no-legend 2>&1)"
bootc status >/dev/null 2>&1 || { echo "FAIL bootc status"; fail=1; }

# Offline listing (--root=/): through the bus it times out in the ephemeral VM.
raw=$(systemctl --root=/ list-unit-files --no-legend --state=enabled,enabled-runtime,masked,masked-runtime,linked 2>/dev/null)
# Units the boot itself masks or enables in /run (state *-runtime) are not part of the image:
# leave them out of both sides.
runtime=$(echo "$raw" | awk '$2 ~ /-runtime$/ { print $1 }')
filter() { grep -v '^sshd' | awk -v r="$runtime" 'BEGIN { n = split(r, a, "\n"); for (i = 1; i <= n; i++) skip[a[i]] = 1 } !($1 in skip)'; }
got=$(echo "$raw" | awk '{ print $1, $2 }' | LC_ALL=C sort | filter || true)
want=$(echo "$EXPECTED_UNITS" | base64 -d | filter || true)
[ "$got" = "$want" ] || { echo "FAIL enabled units differ from manifest:"; diff <(echo "$want") <(echo "$got"); fail=1; }

[ "$fail" = 0 ] && echo "BOOT CHECKS OK" || echo "BOOT CHECKS FAILED"
exit "$fail"
