# 0006 — Quiet Plasma defaults (step 3)

Date: 2026-10-29. Status: accepted. Visual check by the maintainer pending.

## Decisions (maintainer, 2026-10-29)
Defaults live in `/usr/share/swarf/xdg/`, read through `XDG_CONFIG_DIRS`; user settings in
`~/.config` still win. Fedora's own `kdeglobals` (`LookAndFeelPackage=org.fedoraproject.fedora.desktop`)
is untouched: Kyanite's breeze-dark override is dropped.

| Item | File and key | Source checked |
|---|---|---|
| No splash screen | `ksplashrc [KSplash] Engine=none, Theme=None` | `startplasma.cpp` 6.7.5 starts `ksplashqml` only for `KSplashQML` |
| Overview effect off | `kwinrc [Plugins] overviewEnabled=false` | `effectloader.cpp`: key is `<effect>Enabled` |
| System bell effect off | `kwinrc [Plugins] systembellEnabled=false` | same |
| Zoom effect off | `kwinrc [Plugins] zoomEnabled=false` | same |
| System bell (kaccess) off | `kaccessrc [Bell] SystemBell=false` | `kcmaccessibilitybell.kcfg` |

Shake-to-enlarge cursor stays on.

## Not ported from Kyanite ADR 0016
- Notification sounds off (`[Sounds] Enable`): key not found in KNotifications 6.31; no audio
  server is installed, so nothing can play.
- `kaccessrc [Keyboard] Gestures`: absent from `kcmaccessibilitykeyboard.kcfg`.
- Hot-corner `BorderActivate`: pointless once the overview effect is off.
- File search: `baloo_file` is not installed (only `kf6-baloo-libs` and `balooctl6`). No
  setting needed. Kiosk blocks of `kcm_access`/`kcm_baloofile` are skipped: they leave
  modules visible but unusable (Kyanite ADR 0014).
- No pinned applications in the task manager: it was part of the dropped branding workarounds.
- `plasma-kaccess.service` drop-in: on the SPEC drop list.
