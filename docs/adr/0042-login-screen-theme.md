# 0042 — Light login screen after choosing the dark theme

Date: 2026-11-05. Status: proposed (no image change until the maintainer agrees).

## Problem
Packard Bell, 2026-11-04: dark theme chosen in Plasma Setup, Plasma is dark, the login screen stays
light. The maintainer says Fedora does the same.

## Cause (sources read 2026-11-05, tag `v6.8.2` of both, the F45 version)
- plasma-setup `modules/prepareutil/prepareutil.cpp` applies `org.kde.breezedark.desktop` with
  `plasma-apply-lookandfeel` in the setup session; `src/auth/authhelper.cpp`
  `setnewuserglobaltheme` copies that `kdeglobals` into the new user's `~/.config` only.
- plasma-login-manager: the greeter runs as the `plasmalogin` user (home `/var/lib/plasmalogin`,
  `services/plasmalogin-sysuser.conf.in`) and reads its own config, so it keeps the system default
  (light). Only the System Settings module copies the user's settings there:
  `src/frontend/kcm/kcm.cpp` `synchronizeSettings()` (`kdeglobals`, `plasmarc`, `kxkbrc`,
  `plasma-localerc`, `kcminputrc`, fonts, screen layout), button "Apply Plasma Settings…"
  (French: « Appliquer la configuration de Plasma... », `po/fr/kcm_plasmalogin.po`).
- No KDE bug for plasma-setup on this (searched bugs.kde.org 2026-11-05); related: 515174.

## Options
1. (Recommended) No image change. The README says: System Settings → Login Screen → « Appliquer
   la configuration de Plasma... » → « Appliquer ». It also brings the keyboard layout and language
   to the login screen. Report the gap to KDE (plasma-setup), maintainer's call.
2. Image: run the same sync automatically when Plasma Setup ends (our own code calling the
   `org.kde.kcontrol.kcmplasmalogin.sync` KAuth action). Fixes it for everyone, but we own code
   that KDE should own.
3. Ship a dark greeter by default. Wrong for users who pick the light theme.

## Not seen
The button's effect in the VM; the exact French name of the System Settings module.
