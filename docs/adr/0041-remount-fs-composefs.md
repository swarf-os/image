# 0041 — `systemd-remount-fs` fails on the composefs root

Date: 2026-11-05. Status: accepted (maintainer, 2026-11-05: option 1).

## Problem
On every installed machine `systemd-remount-fs.service` fails: "mount: /: fsconfig() failed:
overlay: No changes allowed in reconfigure" (Packard Bell record `after-karg-20261104-0226`, the VM).
It is the only failed unit. Nothing else breaks, but a red unit at each boot hides real failures.

## Cause (sources read 2026-11-05)
- Anaconda writes `/` in `/etc/fstab` (`btrfs subvol=root,compress=zstd:1,...`). bootc 1.17.3
  (`crates/lib/src/generator.rs`, `deploy.rs` `fixup_etc_fstab`, F45 version) only appends `ro` to
  that line through `bootc-fstab-edit.service`. Seen on the Packard Bell:
  `/ btrfs subvol=root,compress=zstd:1,x-systemd.device-timeout=0,ro`.
- systemd 262 `src/remount-fs/remount-fs.c`: for `/` in fstab it runs `mount / -o remount`, so
  libmount applies the fstab options to `/`, which is the composefs overlay, not btrfs.
- util-linux 2.42.4 `libmount/src/hook_mount.c`: by default the new mount API (`fsconfig`).
  Linux `fs/overlayfs/params.c` `ovl_parse_param`: on reconfigure overlayfs ignores every option
  with the old `mount(2)` (`fc->oldapi`) and refuses any with the new API — the message above.
- Known upstream, open: bootc #971 (2024-12), fedora-silverblue issue-tracker #605 (Kinoite and
  Silverblue fail the same way), systemd #39558. bootc's advice: `/` should not be in fstab.
- Side note: `compress=zstd:1` is not applied today either; `/sysroot` is mounted from
  `rootflags=subvol=/root` only (`findmnt /sysroot` on the Packard Bell shows no `compress`).

## Options
1. (Chosen) Image drop-in `/usr/lib/systemd/system/systemd-remount-fs.service.d/` with
   `Environment=LIBMOUNT_FORCE_MOUNT2=always` (`mount.8`: forces the classic `mount(2)`): overlayfs
   then ignores the options as it always did. Reaches every installed machine at its next update,
   the Packard Bell included; only this unit is affected; no fstab edit. Workaround given in
   systemd #39558, confirmed there by a second user.
2. ISO `%post` removes the `/` line from fstab (bootc's advice). New installs only; the Packard Bell
   needs a hand edit. Does not lose compression (already not applied).
3. Wait for upstream (open for almost two years).

## Seen
- 2026-11-05, VM `swarf-iso45` (F45 ISO from PR #48, util-linux 2.42.4): `systemctl is-failed
  systemd-remount-fs` says `failed`; `sudo mount / -o remount` fails with `fsconfig() failed:
  overlay: No changes allowed in reconfigure`; `sudo env LIBMOUNT_FORCE_MOUNT2=always mount / -o
  remount` succeeds and `/` stays `ro` (composefs options unchanged).

- 2026-11-05, same VM: the option 1 file as an `/etc/systemd/system/systemd-remount-fs.service.d/`
  drop-in, `systemctl daemon-reload` and `restart`: `is-failed` says `active`, `/` stays `ro`. After a
  reboot (LUKS unlocked in AZERTY): `active`, `Environment=LIBMOUNT_FORCE_MOUNT2=always`, journal
  "Finished systemd-remount-fs.service", `/` `ro`, `vconsole.keymap=fr-oss` still on `/proc/cmdline`.

## Decision
Option 1: `system/usr/lib/systemd/system/systemd-remount-fs.service.d/50-swarf-composefs.conf`.
Remove it once util-linux or overlayfs accept the remount upstream (systemd #39558, bootc #971).

## Not seen
The image file itself on an installed machine (VM after an update, then the Packard Bell).
