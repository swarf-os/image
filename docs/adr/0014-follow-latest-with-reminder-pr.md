# 0014 — Follow `fedora-bootc:latest`, a pull request on a version change (step 5)

Date: 2026-10-29. Status: accepted (maintainer decision). Replaces the version policy left open
in ADR 0001 (the start on Fedora 44 stands).

## Context
Checked 2026-10-29 with `skopeo`: `quay.io/fedora/fedora-bootc:latest` is 44.20261029.0, the
latest final release; tag `45` already exists while `releases.json` lists "45 Beta". So `latest`
does not point at a beta; it will move to 45 when Fedora decides, without any action here.

## Decision
- `Containerfile`: `ARG BASE=quay.io/fedora/fedora-bootc:latest`. CI resolves it to a digest
  first and builds `FROM …@sha256:…` (`tools/ci-build.sh`), so the base is the one recorded.
- `VERSION_ID` is part of the gated manifest (ADR 0015). When `latest` moves to 45 the daily
  build still publishes `:testing`, but `:stable` waits for the drift pull request (ADR 0016).
  Its body lists the visual checks to make in a VM before merging.
- No separate "bump" job: the same mechanism covers packages, units and Fedora versions.

## Consequences
Nothing in the image is pinned to a major version, so a Fedora jump never reaches the machines
without a merge. The tag could point at a major release that Fedora has not announced; the pull
request is where that is noticed.
