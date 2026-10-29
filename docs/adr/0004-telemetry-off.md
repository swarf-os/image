# 0004 — Telemetry off (step 3)

Date: 2026-10-29. Status: accepted, one item deferred to step 4.

## Context
SPEC lists KUserFeedback, Discover reviews, the NetworkManager connectivity check and
`rpm-ostree-countme.timer`. Sources: kuserfeedback v6.31.0, discover v6.7.5, NetworkManager
`NetworkManager.conf` documentation (networkmanager.dev, read 2026-10-29).

## Decisions
- **KUserFeedback:** `Provider::isEnabled()` reads `QSettings("KDE", "UserFeedback")`, group
  `[UserFeedback]`, key `Enabled` (provider.cpp). `/usr/share/swarf/xdg/KDE/UserFeedback.conf`
  sets it to `false`. The library stays (Plasma and Dolphin link to it).
- **NetworkManager connectivity:** no `uri` is set in this image (no
  `NetworkManager-config-connectivity-fedora`), so the check is already inactive.
  `/usr/lib/NetworkManager/conf.d/60-swarf-no-connectivity.conf` adds `[connectivity] enabled=false`
  so that a future package cannot turn it on.
- **`rpm-ostree-countme.timer`:** disabled (preset `80-swarf.preset` and `configure.sh`, step 1).
  Verified `disabled` in the VM by `tests/check-config.sh`.
- **DrKonqi:** not installed (`plasma-drkonqi` is blacklisted).

## Deferred: Discover reviews (ODRS)
Discover 6.7.5 has no setting for this. `OdrsReviewsBackend` downloads
`https://odrs.gnome.org/1.0/reviews/api/ratings` on every start (cached one day), and on
opening an application page it POSTs `app_id`, `distro`, `version`, `locale` and a
`user_hash` (salted hash of login name and `/etc/machine-id`). The maintainer deferred the
decision to step 4, with the other Discover settings. Options noted: block `odrs.gnome.org`
(for example `/etc/hosts`), or accept and document.
