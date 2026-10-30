#!/bin/bash
# Describe an image: tools/manifest.sh IMAGE OUTDIR
# Gating files (compared with manifest/ by tools/manifest-check.sh):
#   packages.txt  name.arch of every installed package
#   units.txt     unit files that are enabled, masked or linked
#   repos.txt     names of /etc/yum.repos.d/*.repo
#   version.txt   VERSION_ID
# Informative file, never compared (it changes every day): info.txt (kernel, base digest).
# BASE_DIGEST in the environment is recorded as the base image digest.
set -euo pipefail
image=$1
out=$2
mkdir -p "$out"
podman run --rm --net=none "$image" bash -c '
    echo "### packages"; rpm -qa --qf "%{NAME}.%{ARCH}\n" | LC_ALL=C sort
    echo "### units"; systemctl list-unit-files --no-legend --state=enabled,enabled-runtime,masked,masked-runtime,linked | awk "{ print \$1, \$2 }" | LC_ALL=C sort
    echo "### repos"; for f in /etc/yum.repos.d/*.repo; do [ -e "$f" ] && basename "$f"; done | LC_ALL=C sort
    echo "### version"; . /usr/lib/os-release; echo "$VERSION_ID"
    echo "### kernel"; ls /usr/lib/modules
' >"$out/.raw"
section() { awk -v s="### $1" '/^### / { on = ($0 == s); next } on' "$out/.raw"; }
section packages >"$out/packages.txt"
section units >"$out/units.txt"
section repos >"$out/repos.txt"
section version >"$out/version.txt"
{ echo "base: ${BASE_DIGEST:-unknown}"; echo "kernel: $(section kernel)"; echo "packages: $(wc -l <"$out/packages.txt")"; } >"$out/info.txt"
rm "$out/.raw"
