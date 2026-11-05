# Installing from a USB stick

Status: **do not use an ISO built before step 6b.** Those ISOs copy Flatpaks in a `%post` that stops the install on real hardware (first real install, Packard Bell laptop, 2026-11-02, ADR 0027). Use a CI ISO from `main` built after step 6b and after the "Manifest drift" PR that follows it is merged (so `:stable` has the Wi-Fi firmware and `upower`). Not an ISO from a pull request run: on a pull request `iso.yml` builds from the published `:stable`, without the pull request's image changes. The step 6b ISO is seen in a VM only (see PROGRESS.md).

## Before

- **First promote `:stable` (merge the "Manifest drift" PR).** The installed system follows `ghcr.io/swarf-os/image:stable`; until that tag has Plymouth, the fonts and `rhgb`, the first update would remove them.
- Download the ISO and `SHA256SUMS` from the `iso` workflow run (artifact `swarf-os-iso`) or from the download page (`https://get.swarf-os.workers.dev`, word `fraws`, ADR 0029/0030; once the Cloudflare secrets are set). Check it: `sha256sum -c SHA256SUMS`. ISOs built on `main` also carry `SHA256SUMS.bundle`; seen working (2026-11-02): `cosign verify-blob --bundle SHA256SUMS.bundle --certificate-identity https://github.com/swarf-os/image/.github/workflows/iso.yml@refs/heads/main --certificate-oidc-issuer https://token.actions.githubusercontent.com SHA256SUMS`.
- Write the stick with Fedora Media Writer (SPEC.md). Everything on the stick is erased.
- Secure Boot can stay on (the ISO boots with shim in the VM with Secure Boot).

## Installer choices

- Pick your language and keyboard layout: the LUKS prompt at boot uses that layout (ADR 0037).
- Time zone and language are asked again by Plasma Setup on first boot; the installer does not guess them from the network (ADR 0026).

## Boot and disk

- Boot the stick from the one-time boot menu (the key shown at power-on).
- In the installer's storage step, tick only the target disk (go by model and size, not by `sda`/`sdb`: letters can change when booting from USB) and untick every other disk. Everything on the target disk is erased.
- Another installed Fedora shows up as "Fedora" in the firmware boot list, like the new system: after install, check which disk each entry points to before choosing a default.

## After install: Waterfox and VLC

The system has no apps from Flathub at first. The menu shows "Internet" and "Media player" at the top of the favourites: click one, a terminal window opens, answer `y`, and the app is downloaded from Flathub (a network is needed; Wi-Fi from the network icon). The launcher then becomes the app itself. An admin account is not asked for a password. The same works in the live session, but the app lives in RAM until the restart.

## After install: record what you see

On the installed system, as the Plasma Setup account, with a second USB stick mounted (optional):
`curl -fsSLO https://raw.githubusercontent.com/swarf-os/image/main/tests/hardware-check.sh && bash hardware-check.sh after-login`.
It asks the sudo password once and writes `~/swarf-check-*.tgz` (copied to the stick if one is mounted). Run it again with the label `after-apps` once both launchers have been clicked.

## If the install fails

Do not reboot: the logs live in memory. In the live session, plug a second USB stick (never the ISO stick, never the target disk), open it once in Dolphin so it mounts, then run this in Konsole (the logs under `/tmp` are readable by root only). It prints `COPIE-OK` when the archive `swarf-diag.tgz` is on the stick:

```
sudo bash -c 'W=/tmp/diag; rm -rf $W; mkdir -p $W; { date; cat /proc/cmdline; lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS; findmnt; free -h; df -h; ip -br addr; nmcli device; cat /sys/class/net/*/device/uevent; ls -la /sys/class/power_supply; systemctl list-units --failed --no-pager; ls -la /tmp; } > $W/etat.txt 2>&1; dmesg > $W/dmesg.txt 2>&1; journalctl -b --no-pager > $W/journal.txt 2>&1; cp -r /tmp/*.log /tmp/anaconda* /tmp/ks-script* /tmp/syslog $W/ 2>/dev/null; tar czf /tmp/swarf-diag.tgz -C /tmp diag; D=$(ls -d /run/media/liveuser/*/ 2>/dev/null | head -n 1); if [ -z "$D" ]; then echo "NO STICK MOUNTED: archive in /tmp/swarf-diag.tgz"; else cp /tmp/swarf-diag.tgz "$D" && sync && echo COPIE-OK; fi'
```

An earlier VM failure of the old Flatpak `%post` ("No space left on device") was never explained; that `%post` is gone since step 6b.
