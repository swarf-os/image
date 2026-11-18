#!/bin/bash
# Step 10 point 5 (ADR 0041): is systemd-remount-fs fixed on this installed machine? Read-only, no sudo.
#   curl -fsSLO https://raw.githubusercontent.com/swarf-os/image/loose-ends-packard-bell/tests/remount-check.sh
#   bash remount-check.sh
# Writes the full report to ~/swarf-remount-DATE.txt and prints a five-line summary.
set -uo pipefail
f=$HOME/swarf-remount-$(date +%Y%m%d-%H%M).txt
run() { printf '\n$ %s\n' "$*"; "$@" 2>&1; printf '(rc %s)\n' "$?"; }
{
  run date -Is
  run rpm-ostree status
  run cat /proc/cmdline
  run cat /etc/fstab
  run findmnt -o TARGET,SOURCE,FSTYPE,OPTIONS /
  run ls -la /etc/systemd/system/systemd-remount-fs.service.d
  run systemd-delta --type=extended --no-pager
  run systemctl show -p ActiveState,SubState,Result,Environment,DropInPaths systemd-remount-fs.service
  run journalctl -b -u systemd-remount-fs.service --no-pager
  run systemctl --failed --no-pager
} >"$f" 2>&1
echo "version:  $(rpm-ostree status --booted 2>/dev/null | awk '/Version:/{print $2; exit}')"
echo "unit:     $(systemctl is-failed systemd-remount-fs.service)"
echo "root:     $(findmnt -no FSTYPE,OPTIONS / | cut -d, -f1)"
echo "drop-in:  $(systemd-delta --type=extended --no-pager 2>/dev/null | grep -o '/usr/lib/systemd/system/systemd-remount-fs.service.d/[^ ]*' || echo NONE)"
echo "failed:   $(systemctl --failed --no-legend --plain 2>/dev/null | wc -l) unit(s)"
echo "report:   $f"
