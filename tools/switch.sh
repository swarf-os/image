#!/bin/bash
# Switch an installed Fedora Kinoite (or any ostree/bootc system) to swarf-os, and test the
# rollback before needing it (step 8, ADR 0033, 0034). Run as root on the machine itself:
#   sudo tools/switch.sh inventory        what is there now (read only)
#   sudo tools/switch.sh switch [IMAGE]   stage IMAGE (default :stable); the first time, pin the booted OS
#   sudo tools/switch.sh status           booted / staged / rollback, image digests, pins (read only)
#   sudo tools/switch.sh rollback         next boot = the rollback deployment (bootc/rpm-ostree rollback)
#   sudo tools/switch.sh pin-to DIGEST    stage ghcr.io/swarf-os/image@DIGEST (stay on an older image)
#   sudo tools/switch.sh default INDEX    next boot = deployment INDEX (from "status")
#   sudo tools/switch.sh unpin INDEX      ostree admin pin --unpin INDEX (from "status")
# Nothing reboots: reboot yourself. The full log goes to ../work/switch-<cmd>-<time>.log next to
# the repository; only OK or the useful lines are printed.
set -uo pipefail
IMAGE_DEFAULT=ghcr.io/swarf-os/image:stable
REPO=ghcr.io/swarf-os/image
R=$(cd "$(dirname "$0")/.." && pwd)
W=${SWARF_WORK:-$(cd "$R/.." && pwd)/work}
cmd=${1:-}
[ "$(id -u)" = 0 ] || { echo "run as root: sudo $0 $*"; exit 2; }
mkdir -p "$W"
log=$W/switch-${cmd:-none}-$(date +%Y%m%d-%H%M%S).log
[ -n "${SUDO_UID:-}" ] && chown "$SUDO_UID:${SUDO_GID:-$SUDO_UID}" "$W" 2>/dev/null
exec 3>&1 >"$log" 2>&1
say() { echo "$*" >&3; echo "== $*"; }
die() { say "FAILED: $*"; say "log: $log"; exit 1; }
own() { [ -n "${SUDO_UID:-}" ] && chown "$SUDO_UID:${SUDO_GID:-$SUDO_UID}" "$log"; }
trap own EXIT

# One line per deployment, read from rpm-ostree (works on ostree-remote and container origins).
deployments() {
    rpm-ostree status --json | jq -r '.deployments | to_entries[] | .value as $d |
        "  [\(.key)] \(if $d.booted then "booted  " elif $d.staged then "staged  " else "        " end)\(if $d.pinned then "pinned " else "       " end)\($d["container-image-reference"] // $d.origin // "?") \($d["container-image-reference-digest"] // $d.version // "")"'
}
layered() {
    rpm-ostree status --json | jq -r '.deployments[] | select(.booted) |
        ((.["requested-packages"] // []) + (.["requested-local-packages"] // [])
         + (.["requested-base-removals"] // []) + (.["requested-base-local-replacements"] // []))
        | join(" ")'
}

case $cmd in
inventory)
    rpm-ostree status -v; bootc status; ostree admin config-diff
    flatpak remotes --system --columns=name,url,filter; flatpak list --system --columns=application,origin
    systemctl list-unit-files 'bootc-fetch-apply-updates.timer' 'rpm-ostreed-automatic.timer' --no-legend
    cat /etc/xdg/PlasmaDiscoverUpdates /etc/rpm-ostreed.conf 2>&1
    getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1}'
    df -h / /boot /var; mokutil --sb-state; findmnt /boot /boot/efi
    grep -E "timeout|menu_auto_hide" /boot/grub2/grub.cfg; grub2-editenv list
    say "deployments:"; deployments >&3
    l=$(layered); say "layered packages: ${l:-none}"
    say "/etc files changed locally: $(ostree admin config-diff | wc -l) (list in the log)"
    say "Flatpak remotes: $(flatpak remotes --system --columns=name | tr '\n' ' ')"
    # Without this file, Plasma Setup starts again on swarf-os (ConditionPathExists=!/etc/plasma-setup-done).
    if [ -e /etc/plasma-setup-done ]; then say "Plasma Setup done: yes"
    else say "Plasma Setup done: NO (switch creates the file if an account exists)"; fi
    say "log: $log"; say OK ;;
switch|pin-to)
    if [ "$cmd" = switch ]; then target=${2:-$IMAGE_DEFAULT}
    else [[ ${2:-} =~ ^sha256:[0-9a-f]{64}$ ]] || die "usage: pin-to sha256:<64 hex>"; target=$REPO@$2; fi
    l=$(layered); [ -z "$l" ] || die "layered packages ($l): bootc refuses to switch (bootc-relationships(7)); remove them with rpm-ostree first"
    # Pin the booted deployment once, on the first switch (no pin yet): the original OS
    # (Kinoite, whatever its origin) stays in the boot menu.
    if ! rpm-ostree status --json | jq -e 'any(.deployments[]; .pinned)' >/dev/null; then
        ostree admin pin booted || die "ostree admin pin booted"
        say "booted deployment pinned (kept in the boot menu)"
    fi
    # Plasma Setup starts when /etc/plasma-setup-done is missing; an existing account means the
    # machine is set up already. /etc is merged into the new deployment, so the file carries over.
    if [ ! -e /etc/plasma-setup-done ] && getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {f=1} END {exit !f}'; then
        touch /etc/plasma-setup-done && say "created /etc/plasma-setup-done (an account exists: no setup wizard)"
    fi
    bootc switch "$target" || die "bootc switch $target"
    say "deployments:"; deployments >&3
    rpm-ostree status --json | jq -e '.deployments[0].staged' >/dev/null || die "nothing staged"
    say "reboot to boot $target"; say OK ;;
status)
    bootc status --format=json; rpm-ostree status -v
    systemctl is-enabled bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer
    say "deployments:"; deployments >&3
    booted=$(bootc status --format=json | jq -r '.status.booted.image.imageDigest // empty')
    ref=$(bootc status --format=json | jq -r '.status.booted.image.image.image // empty')
    if [ -n "$booted" ]; then
        say "booted image: $ref"
        say "booted digest:   $booted"
        remote=$(skopeo inspect --no-tags "docker://$ref" | jq -r .Digest)
        say "registry digest: ${remote:-unreadable} (what $ref points to now)"
        if [ "$booted" = "$remote" ]; then say "digest check: MATCH"
        else say "digest check: DIFFERENT (normal if the tag moved since: a newer promote; check the date)"; fi
    else say "booted: not a container image"; fi
    say "auto-update timers: $(systemctl is-enabled bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer 2>/dev/null | tr '\n' ' ')"
    say OK ;;
rollback)
    # bootc refuses a rollback target that is not a container image (the pinned Kinoite one, with
    # an ostree-remote origin): rpm-ostree rollback does the same bootloader swap for any origin.
    if rpm-ostree status --json | jq -e '[.deployments[] | select(.staged | not)][1]["container-image-reference"]' >/dev/null; then
        bootc rollback || die "bootc rollback"
    else
        rpm-ostree rollback || die "rpm-ostree rollback"
    fi
    say "deployments (next boot = [0]):"; deployments >&3
    say "reboot to boot it"; say OK ;;
default)
    # Any deployment, not only [1]: e.g. back to the pinned Kinoite when it is [2] (ostree-admin-set-default(1)).
    [[ ${2:-} =~ ^[0-9]+$ ]] || die "usage: default INDEX"
    ostree admin set-default "$2" || die "ostree admin set-default $2"
    say "deployments (next boot = [0]):"; deployments >&3
    say "reboot to boot it"; say OK ;;
unpin)
    [[ ${2:-} =~ ^[0-9]+$ ]] || die "usage: unpin INDEX"
    ostree admin pin --unpin "$2" || die "ostree admin pin --unpin $2"
    say "deployments:"; deployments >&3; say OK ;;
*)
    sed -n '2,13p' "$0" >&3; exit 2 ;;
esac
