#!/bin/bash
# Apply whitelist.txt and blacklist.txt to the base image.
# Usage: packages.sh WHITELIST BLACKLIST
set -euo pipefail

wl=$1
bl=$2
dnf=(dnf -y --setopt=keepcache=True --setopt=max_parallel_downloads=10)

# Print the entries of one [section] of the blacklist.
section() {
    awk -v s="[$1]" '/^\[/ { on = ($0 == s); next } on && !/^#/ && NF { print $1 }' "$bl"
}

# Print the installed packages whose name matches one of the globs read on stdin.
installed() {
    local globs
    globs=$(cat)
    rpm -qa --qf '%{NAME}\n' | while read -r pkg; do
        for glob in $globs; do
            # shellcheck disable=SC2254
            case $pkg in $glob) echo "$pkg"; break ;; esac
        done
    done
}

# 1. Remove unwanted packages from the base image, respecting dependencies.
mapfile -t clean < <(section remove | installed)
if ((${#clean[@]})); then
    echo "Removing ${#clean[@]} packages: ${clean[*]}"
    "${dnf[@]}" remove "${clean[@]}"
fi

# 2. Install the whitelist, without weak dependencies.
mapfile -t wanted < <(grep -vE '^#|^$' "$wl")
"${dnf[@]}" --setopt=install_weak_deps=False install "${wanted[@]}"

# 3. Fail if anything blacklisted is still there.
mapfile -t left < <(section remove | installed)
repos=()
for glob in $(section repos); do
    for file in /etc/yum.repos.d/*.repo; do
        name=$(basename "$file" .repo)
        # shellcheck disable=SC2254
        case $name in $glob) repos+=("$file") ;; esac
    done
done
if ((${#left[@]} + ${#repos[@]})); then
    echo "ERROR: blacklisted packages or repositories present: ${left[*]} ${repos[*]}" >&2
    exit 1
fi

# Keep /var clean: logs, dnf state and cache are not part of the image
# (the cache stays only when it is a volume mounted by a local build).
rm -rf /var/log/dnf5.log* /var/lib/dnf
mountpoint -q /var/cache/libdnf5 || dnf clean all
