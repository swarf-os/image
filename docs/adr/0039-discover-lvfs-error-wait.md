# 0039 — Discover's LVFS error dialog: wait for the upstream fix

Date: 2026-11-05. Status: accepted (maintainer: "Option 1 pour discover, on attendra").

## Problem
F45 VM, Discover at start: "Failed to download metadata for lvfs: attempted previous download of
https://cdn.fwupd.org/downloads/firmware.xml.zst.jcat from process just 856ms ago".

## Cause (sources read 2026-11-05)
- fwupd `libfwupd/fwupd-client.c` (main): one `FwupdClient` refuses the same URI again within
  `FWUPD_CLIENT_DOWNLOAD_URI_DELTA` (1500 ms), added 2026-06-17 (commit `072c4a6b5`).
- KDE bug 523258 (confirmed; Discover 6.7.3–6.8.2, Fedora 44/45 Kinoite) and Red Hat bug 2502629:
  Discover itself asks twice — the rpm-ostree check at start ends a transaction, which refreshes the
  remotes again. The first download succeeds; the dialog is a false alarm.
- Fix written, not merged yet: Discover MR 1464 (master) and 1465 (Plasma/6.8), "fwupd: Do not
  refresh remotes when a transaction finishes".

## Decision
No change to the image. The fix comes with a Fedora Discover update. Rejected: disabling the LVFS
remote (no firmware updates, SPEC says firmware through Discover/fwupd); patching Discover.

## Not seen yet
The Discover release with the fix in Fedora, and the dialog gone.
