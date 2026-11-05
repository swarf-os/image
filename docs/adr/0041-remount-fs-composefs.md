# 0041 — `systemd-remount-fs` fails on the composefs root

Date: 2026-11-05. Status: proposed (no image change until the maintainer agrees).

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
1. (Recommended) Image drop-in `/usr/lib/systemd/system/systemd-remount-fs.service.d/` with
   `Environment=LIBMOUNT_FORCE_MOUNT2=always` (`mount.8`: forces the classic `mount(2)`): overlayfs
   then ignores the options as it always did. Reaches every installed machine at its next update,
   the Packard Bell included; only this unit is affected; no fstab edit. Workaround given in
   systemd #39558, confirmed there by a second user.
2. ISO `%post` removes the `/` line from fstab (bootc's advice). New installs only; the Packard Bell
   needs a hand edit. Does not lose compression (already not applied).
3. Wait for upstream (open for almost two years).

## Not seen
None of the options tested yet. Test for option 1 in the VM, before any image change:
`sudo env LIBMOUNT_FORCE_MOUNT2=always mount / -o remount; echo $?` (expect 0), then a runtime
drop-in and `systemctl restart systemd-remount-fs`.
