# 0037 — The LUKS prompt uses the installer keyboard (`vconsole.keymap=` karg)

Date: 2026-11-04. Status: accepted (maintainer: "il faut corriger"). Supersedes the "always US"
consequence of ADR 0022.

## Problem
Packard Bell, ISO `20261103-1803`, installer keyboard set to French: the graphical LUKS prompt
wanted US keys (seen 2026-11-04; the maintainer needed a converter to unlock). Same as the VM
(ADR 0022). A passphrase with accents cannot be typed on a US layout at all.

## Cause (sources read 2026-11-04)
- `anaconda-core-44.30-2.fc44`, `pyanaconda/modules/payloads/payload/rpm_ostree/installation.py`:
  `ConfigureBootloader._set_kargs()` appends `vconsole.keymap=<installer keymap>` on ostree
  installs (Kinoite). `rpm_ostree.py` returns no post-install task for a bootc source ("No extra
  steps in case of the bootc install"), so a bootc install gets only the bootloader arguments
  (`rd.luks.uuid`, `rhgb quiet`). Seen on the Packard Bell: no keymap karg on `/proc/cmdline`.
- Plymouth 24.004.60, `src/libply-splash-core/ply-device-manager.c` `parse_vconsole_conf`: the XKB
  layout comes only from the initramfs `/etc/vconsole.conf`; our initramfs is built in the image,
  generic, without it. The keymap comes from `rd.vconsole.keymap=` or `vconsole.keymap=`.
- The initramfs already holds every console keymap (`usr/lib/kbd/keymaps/xkb/fr-oss.map.gz`) and the
  XKB `fr` symbols, and the `i18n` dracut module.

## Decision
The ISO kickstart gets a `%post --nochroot` that does what Anaconda does on ostree installs: read
`KEYMAP` from the deployment's `/etc/vconsole.conf` and run `ostree admin instutil set-kargs
--sysroot=/mnt/sysimage --merge vconsole.keymap=<KEYMAP>` from the live system (built from the same
image, same ostree) when it is not `us` or empty, with `/mnt/sysimage/boot` remounted read-write
for that command only (it is read-only at `%post` time). Not chrooted: the bootc flow does not bind the
physical root on the deployment's `/sysroot` (the ostree flow does, `installation.py:329`), and a
chrooted `ostree admin` failed with "No such file or directory" (seen, below). Log in `/var/log/swarf-keymap.log` (read by
`tests/hardware-check.sh`).
- Plain `vconsole.keymap=` (not `rd.`): the same karg Fedora's ostree installs get.
- No `--erroronfail`: if it fails the prompt stays US (the old behaviour) and the install goes on;
  an aborted install (ADR 0027) is worse.
- A machine already installed gets it by hand: `sudo rpm-ostree kargs --append=vconsole.keymap=fr`.
- A later keyboard change (Plasma, `localectl`) does not change the prompt: change the karg too.

## Seen / not seen
- SEEN on the Packard Bell (2026-11-04): `rpm-ostree kargs --append=vconsole.keymap=fr-oss` (its
  `vconsole.conf` says `KEYMAP=fr`), reboot, the passphrase typed in AZERTY unlocks.
- SEEN FAILING (2026-11-04, VM, PR #39 ISO with the first, chrooted `%post`): `vconsole.conf` had
  `KEYMAP="fr-oss"`, `set-kargs` failed "error: No such file or directory", no karg, US prompt.
- SEEN FAILING (2026-11-04, VM, second ISO, `--nochroot --sysroot`): `error: mkdir(boot/loader.0):
  Read-only file system`.
- SEEN in that VM (debug shell): `/boot` and `/sysroot` remounted rw, `ostree admin instutil
  set-kargs --merge vconsole.keymap=fr-oss` → "Bootloader updated", karg in the entry; after reboot
  `asdfgh` typed at AZERTY positions unlocks.
- NOT seen yet: the `%post` with the remount on a built ISO (VM install with the French keyboard chosen in the
  WebUI); the karg kept after a Discover update (new deployment).
