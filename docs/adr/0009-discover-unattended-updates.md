# 0009 — Discover unattended updates, staged (step 4)

Date: 2026-10-29. Status: accepted.

## Context
Sources read 2026-10-29: Discover v6.7.5 (`notifier/DiscoverNotifier.cpp`,
`notifier/UnattendedUpdates.cpp`, `kcm/updatessettings.kcfg`,
`RpmOstreeBackend.cpp`), `fedora-release-ostree-desktop` in the image (polkit rule), and
Kyanite ADR 0008 (reread, not trusted blindly).

- `UseUnattendedUpdates` defaults to `false` in Discover. Fedora Kinoite ships a file for it
  in `/etc/xdg`; this image has none (`grep -r UseUnattended /usr/share /etc` is empty).
  `RequiredNotificationInterval` defaults to 86400 (one day).
- Conditions for an unattended run (`UnattendedUpdates.cpp`, `DiscoverNotifier.cpp`): open
  session, connection not metered and not behind a captive portal, 1 minute idle, Discover
  not running, at most once every 3 h and once per interval. The notifier then runs
  `plasma-discover --headless-update`: Flatpak and system (rpm-ostree backend) together.
  It never reboots.
- No password: `/usr/share/polkit-1/rules.d/org.projectatomic.rpmostree1.rules`
  (from `fedora-release-ostree-desktop`) answers YES to `repo-refresh` and `upgrade` for an
  active local session, no group needed. Flatpak system updates: `pkaction` in the VM shows `implicit active: yes` for
  `org.freedesktop.Flatpak.app-update` and `runtime-update`.

## Decision
- `/usr/share/swarf/xdg/PlasmaDiscoverUpdates`: `[Global] UseUnattendedUpdates=true`,
  `RequiredNotificationInterval=86400`. Users can change it in System Settings → Software
  Update.
- `bootc-fetch-apply-updates.timer` stays disabled (it reboots without asking);
  `rpm-ostreed-automatic.timer` is disabled too (checked in the VM).
- `tests/check-config.sh` checks the keys, the timers and the polkit rule.

## Not verified
A real unattended run needs an image newer than the booted one in a registry (the VM boots
from a local image) and a logged-in session. It is left for step 5 (CI publishes the
registry image) and step 8.
