#!/bin/bash
# Step 6: what an ISO install looks like on real hardware, in text. Run on the installed machine,
# as the account made by Plasma Setup (not root):
#   curl -fsSLO https://raw.githubusercontent.com/swarf-os/image/main/tests/hardware-check.sh
#   bash hardware-check.sh after-login        (then again: bash hardware-check.sh after-apps)
# Asks the sudo password once, for the root-only reads (initramfs, crypttab, bootc, installer logs).
# Writes swarf-check-LABEL-DATE.tgz in ~ and copies it to the first mounted USB stick, if any.
# Each section names the open item it answers (PROGRESS.md, step 6 and 6b).
set -uo pipefail
label=${1:-run}
name=swarf-check-$label-$(date +%Y%m%d-%H%M)
W=$(mktemp -d)
D=$W/$name
mkdir -p "$D"
sec() { printf '\n### %s\n' "$*"; }
run() { printf '$ %s\n' "$*"; "$@" 2>&1; printf '(rc %s)\n' "$?"; }

{
  sec "identity"
  run date -Is
  run cat /etc/os-release
  run uname -r
  run cat /proc/cmdline                      # rhgb quiet, rd.luks.uuid
  run rpm-ostree status
  sec "secure boot"
  run mokutil --sb-state
  sec "memory (installer RAM question)"
  run free -h
  sec "disk and LUKS"
  run lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS
  run findmnt /
  run findmnt /sysroot
  sec "systemd-remount-fs (Session 6 lead: fstab / options vs composefs)"
  run cat /etc/fstab
  run systemctl status systemd-remount-fs.service --no-pager
  run journalctl -b -u systemd-remount-fs.service --no-pager
  sec "failed units"
  run systemctl --failed --no-pager
  sec "update timers (must be disabled)"
  run systemctl is-enabled bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer
  sec "Plasma Setup and account"
  run ls -l /etc/plasma-setup-done
  run id
  run systemctl is-active plasmalogin.service
  sec "language, keyboard, time zone (America/New_York question)"
  run localectl
  run timedatectl
  run cat /etc/locale.conf
  run cat /etc/vconsole.conf
  sec "Wi-Fi"
  run nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device
  run ip -br addr
  sec "battery"
  run upower -e
  bat=$(upower -e 2>/dev/null | grep -m1 battery_)
  [ -n "$bat" ] && run upower -i "$bat"
  sec "apps on demand (launchers, get-app, Flathub)"
  run ls -la "$HOME/.local/share/applications" "$HOME/.local/share/swarf"
  run flatpak remotes --show-details
  run flatpak list --columns=application,origin,installation
  run flatpak remote-ls --updates
} >"$D/report.txt" 2>&1
journalctl -b -p err --no-pager >"$D/journal-err.txt" 2>&1

echo "sudo password, for the root-only reads:"
sudo bash -s "$D" "$(id -un)" <<'ROOT'
D=$1
run() { printf '$ %s\n' "$*"; "$@" 2>&1; printf '(rc %s)\n' "$?"; }
img=/usr/lib/modules/$(uname -r)/initramfs.img
{
  printf '\n### bootc (booted digest)\n'
  run bootc status
  printf '\n### LUKS\n'
  run cat /etc/crypttab
  printf '\n### LUKS prompt keymap = the initramfs one (ADR 0022)\n'
  run lsinitrd -f etc/vconsole.conf "$img"
  echo "(no vconsole.conf in the initramfs = US keymap)"
  lsinitrd -m "$img" 2>&1 | grep -x -e crypt -e i18n -e plymouth -e systemd-cryptsetup
  printf '\n### installer logs on the target\n'
  if [ -d /var/log/anaconda ]; then run ls -la /var/log/anaconda; tar czf "$D/anaconda-logs.tgz" -C /var/log anaconda
  else echo "/var/log/anaconda ABSENT"; fi
} >"$D/root.txt" 2>&1
journalctl -b --no-pager >"$D/journal.txt" 2>&1
chown -R "$2:" "$D"
ROOT

tar czf "$HOME/$name.tgz" -C "$W" "$name" && rm -rf "$W"
echo "archive: $HOME/$name.tgz"
stick=$(find /run/media/"$(id -un)" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -n 1)
if [ -n "$stick" ]; then cp "$HOME/$name.tgz" "$stick" && sync && echo "COPIE-OK $stick"
else echo "no USB stick mounted: copy the archive yourself"; fi
