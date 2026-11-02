# Installing from a USB stick (NUC and Framework)

Status: **do not use an ISO built before step 6b.** Those ISOs copy Flatpaks in a `%post` that stops the install on real hardware (first real install, Packard Bell laptop, 2026-11-02, ADR 0027). Seen working only in a VM (3 installs). Use the CI ISO from `main` once step 6b is merged.

## Before

- **First promote `:stable` (merge the "Manifest drift" PR).** The installed system follows `ghcr.io/swarf-os/image:stable`; until that tag has Plymouth, the fonts and `rhgb`, the first update would remove them.
- Download the ISO and `SHA256SUMS` from the `iso` workflow run (artifact `swarf-os-iso`) or, once published, from the download page. Check it: `sha256sum -c SHA256SUMS`. ISOs built on `main` also carry `SHA256SUMS.bundle`; seen working (2026-11-02): `cosign verify-blob --bundle SHA256SUMS.bundle --certificate-identity https://github.com/swarf-os/image/.github/workflows/iso.yml@refs/heads/main --certificate-oidc-issuer https://token.actions.githubusercontent.com SHA256SUMS`.
- Write the stick with Fedora Media Writer (SPEC.md). Everything on the stick is erased.
- Secure Boot can stay on (the ISO boots with shim in the VM with Secure Boot).

## Installer choices

- Keep English and the US keyboard (the defaults). The LUKS prompt at boot always uses the US keymap, whatever you pick here (ADR 0022).
- Choose a LUKS passphrase you can type on a US layout.
- Time zone and language are asked again by Plasma Setup on first boot; the installer does not guess them from the network (ADR 0026).

## NUC: only the SATA SSD

The NUC has two disks. Install **only on the Samsung MZ7LN128 (about 128 GB; it was `sdb`, but letters can change when booting from USB: go by model and size)**. **Never on the M.2 disk: it holds Kinoite**, the machine in use.

- In the installer's storage step, tick only that disk and untick the other one. Check the model name and size on screen before clicking Install.
- The boot menu (the boot-menu key shown at power-on) may show a "Fedora" entry from Kinoite. The new system will also be called "Fedora" in the firmware list: after install, check which disk each entry points to before choosing a default.

## Framework

- Boot the stick from the one-time boot menu (the key shown at power-on).
- Single disk: erase it only if nothing on it is needed.

## If the install fails

Do not reboot: the logs live in memory. In the live session, plug a second USB stick (never the ISO stick, never the target disk), open it once in Dolphin so it mounts, then run this in Konsole (the logs under `/tmp` are readable by root only). It prints `COPIE-OK` when the archive `swarf-diag.tgz` is on the stick:

```
sudo bash -c 'W=/tmp/diag; rm -rf $W; mkdir -p $W; { date; cat /proc/cmdline; lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS; findmnt; free -h; df -h; ip -br addr; nmcli device; cat /sys/class/net/*/device/uevent; ls -la /sys/class/power_supply; systemctl list-units --failed --no-pager; ls -la /tmp; } > $W/etat.txt 2>&1; dmesg > $W/dmesg.txt 2>&1; journalctl -b --no-pager > $W/journal.txt 2>&1; cp -r /tmp/*.log /tmp/anaconda* /tmp/ks-script* /tmp/syslog $W/ 2>/dev/null; tar czf /tmp/swarf-diag.tgz -C /tmp diag; D=$(ls -d /run/media/liveuser/*/ 2>/dev/null | head -n 1); if [ -z "$D" ]; then echo "NO STICK MOUNTED: archive in /tmp/swarf-diag.tgz"; else cp /tmp/swarf-diag.tgz "$D" && sync && echo COPIE-OK; fi'
```

An earlier VM failure of the `%post` step ("No space left on device") was never explained.
