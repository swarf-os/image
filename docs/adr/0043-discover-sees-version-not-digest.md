# 0043 — Discover only sees a new Fedora version, not our rebuilds

Date: 2026-11-05. Status: accepted (maintainer, 2026-11-08: option 1).

## Problem
After #50 was merged, `:stable` moved to `sha256:03e5b64e…` (21:35 UTC). In the VM `swarf-iso`
(booted on `:stable` `sha256:eef13a11…`), `sudo bootc upgrade --check` says "Update available …
Version: 45.20261105.0, Digest: sha256:03e5b64e…", but Discover → Updates says "À jour", also
after "Rafraîchir". Discover is the only update path (ADR 0009), so a swarf-only fix reaches
installed machines only when Fedora publishes a new base version.

## Cause (source read 2026-11-05)
plasma-discover 6.8.2 (the F45 version), `libdiscover/backends/RpmOstreeBackend/
RpmOstreeTransaction.cpp`, `CheckForUpdate` for an OCI deployment: `skopeo inspect --no-tags`,
then the `org.opencontainers.image.version` label is compared with `QVersionNumber`; only a
strictly greater version is offered. The digest is not looked at. Our image inherits the label
from `fedora-bootc` (`45.20261105.0` on both digests). `quay.io/fedora/fedora-bootc:45` gets a new
version about once a day (`45.20261105.0` created 11:06 UTC), so the delay is usually up to a day,
longer if Fedora stops publishing for a while.

## Options
1. (Recommended) Set our own label at build time: `<base version>.<github.run_number>`, e.g.
   `45.20261105.0.57`. `QVersionNumber` then sees every published build as newer, and the next
   base (`45.20261106.0`) is still newer than `45.20261105.0.57`. `run_number` stays small (no int
   overflow, unlike `run_id`). `:stable` is a retag of the tested image, so it keeps the label.
   Nothing in `tools/` reads this label.
   Edge case: re-running a workflow run keeps its `run_number`, so a re-run that publishes a new
   digest gets the same label and Discover misses it; accepted (a new push or the daily run fixes it).
2. Keep things as they are and write in the README that fixes arrive with the next Fedora version.

## Decision
Option 1, in `tools/ci-build.sh` (CI only: a local build keeps the base label).

Consequence: every push to `main` rebuilds and publishes, docs-only merges too, so each one becomes
an update offered to every machine. Accepted by the maintainer (2026-11-08).

## Seen
`journalctl --user -b` in `swarf-iso`: `DiscoverNotifier[3379]: No new version found` (21:59 UTC+1),
`plasma-discover[5107]: No new version found` (22:49, 22:50, the two checks above).

- 2026-11-08, option 1: PR #54 build log `version 45.20261108.0.135`; `:stable` `sha256:525f40a5…`
  labelled `45.20261108.0.138`. VM `swarf-iso` booted on `45.20261108.0` (same Fedora base),
  Discover journal: `Found new version: "45.20261108.0.138"`, then `started unattended update`
  (18:23:17 UTC), without anyone clicking Update.
  At 19:10 UTC `rpm-ostree status` listed `sha256:525f40a5…` `45.20261108.0.138` as the staged
  deployment (booted still `fa9a3228…`), and Discover showed the restart-to-install page.

## Not seen
The Packard Bell.
