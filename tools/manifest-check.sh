#!/bin/bash
# Static checks on an image: tools/manifest-check.sh IMAGE
# Exit 0: all good and manifest/ matches. Exit 10: all good but manifest/ differs (drift: the
# diff is in $WORK/manifest-diff.txt and the new manifest in $WORK/manifest-new/).
# Exit 1: a blocking check failed (blacklist, Secure Boot signature, initramfs crypt module).
# Needs podman and sbverify (package sbsigntool on Debian/Ubuntu, sbsigntools on Fedora).
set -euo pipefail
image=$1
R=$(cd "$(dirname "$0")/.." && pwd)
WORK=${WORK:-$R/../work/ci}
mkdir -p "$WORK"
fail=0
bad() { echo "FAIL $*"; fail=1; }

# 1. Manifest of the image.
rm -rf "$WORK/manifest-new"
"$R/tools/manifest.sh" "$image" "$WORK/manifest-new"

# 2. Blacklist (also checked at build time; here against the final image).
section() { awk -v s="[$1]" '/^\[/ { on = ($0 == s); next } on && !/^#/ && NF { print $1 }' "$R/blacklist.txt"; }
for glob in $(section remove); do
    # shellcheck disable=SC2254
    while read -r pkg; do case ${pkg%.*} in $glob) bad "blacklisted package $pkg" ;; esac; done <"$WORK/manifest-new/packages.txt"
done
for glob in $(section repos); do
    # shellcheck disable=SC2254
    while read -r repo; do case ${repo%.repo} in $glob) bad "forbidden repository $repo" ;; esac; done <"$WORK/manifest-new/repos.txt"
done

# 3. Kernel: exactly one, signed by Fedora (Secure Boot chain, no MOK).
cid=$(podman create "$image")
trap 'podman rm -f "$cid" >/dev/null 2>&1 || true' EXIT
rm -rf "$WORK/kernel"
mkdir -p "$WORK/kernel"
podman cp "$cid:/usr/lib/modules/." "$WORK/kernel"
mapfile -t kdirs < <(find "$WORK/kernel" -mindepth 1 -maxdepth 1 -type d)
if ((${#kdirs[@]} != 1)); then
    bad "expected one kernel in /usr/lib/modules, found ${#kdirs[@]}"
else
    sigs=$(sbverify --list "${kdirs[0]}/vmlinuz" 2>&1 || true)
    grep -q 'OU=Fedora Secure Boot Signer' <<<"$sigs" && grep -q 'OU=Fedora Secure Boot CA' <<<"$sigs" ||
        bad "vmlinuz is not signed by the Fedora Secure Boot chain: $sigs"
    # 4. Initramfs keeps the crypt module (LUKS passphrase prompt). Run inside the image: lsinitrd
    # is part of dracut.
    kver=$(basename "${kdirs[0]}")
    # lsinitrd exits non-zero on the early microcode cpio ("zstd: unsupported format"), so read
    # its output first and look for the line in the "dracut modules" list.
    mods=$(podman run --rm --net=none "$image" lsinitrd -m "/usr/lib/modules/$kver/initramfs.img" 2>/dev/null || true)
    grep -qx 'crypt' <<<"$mods" || bad "initramfs has no crypt module"
fi

# 5. Compare the gating files with the committed manifest.
: >"$WORK/manifest-diff.txt"
for f in packages.txt units.txt repos.txt version.txt; do
    diff -u "$R/manifest/$f" "$WORK/manifest-new/$f" >>"$WORK/manifest-diff.txt" 2>&1 || true
done

if ((fail)); then exit 1; fi
if [ -s "$WORK/manifest-diff.txt" ]; then echo "DRIFT: manifest differs, see $WORK/manifest-diff.txt"; exit 10; fi
echo "OK"
