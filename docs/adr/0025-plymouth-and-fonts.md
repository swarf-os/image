# 0025 — Plymouth and all default fonts (step 6)

Date: 2026-10-31. Status: accepted (to be confirmed on the next VM install).

## Context
On the installed VM the LUKS prompt was a plain text console and there was no boot screen:
`plymouth` is not in the image (`rpm -q plymouth` says so). Plasma Setup also logged
`OpenType support missing for "", script 14` and showed boxes in its language list, which
prints each language in its own script. Step 2 (ADR 0002) had kept only `default-fonts-core`.

## Decision
- Whitelist: `plymouth`, `plymouth-system-theme`, `plymouth-theme-spinner` (names read with
  `dnf repoquery` on the image). The base initramfs is built without them, so the Containerfile
  rebuilds it with `dracut --force --no-hostonly --reproducible` after the packages are in.
- Whitelist: `default-fonts-other` and `default-fonts-cjk` next to `default-fonts-core`
  (the three requirements of `default-fonts`). Supersedes the fonts line of ADR 0002.
- Not done: the LUKS prompt keyboard still follows the initramfs keymap, not the installer layout
  (ADR 0022).

## Correction (same day): `rhgb`
With the packages and the rebuilt initramfs, the VM still showed the text LUKS prompt: the
initramfs had Plymouth and the DRM modules, but the command line had `quiet` only. Adding
`rhgb` by hand in GRUB gave the graphical prompt (Fedora logo, passphrase field, keyboard
selector). `system/usr/lib/bootc/kargs.d/10-quiet.toml` now holds `["rhgb", "quiet"]`, as Fedora
ships it. Seen on the VM with the manual argument; the image with the file itself is not
yet seen.

## Live ISO

The live installer's GRUB entries (`iso/build.sh`) had `quiet` but no `rhgb`, so
the live boot showed console text instead of Plymouth. `rhgb` is added to both
entries. The live initramfs already carries Plymouth (`plymouth-switch-root`
seen at boot). Not yet seen on a rebuilt ISO.
