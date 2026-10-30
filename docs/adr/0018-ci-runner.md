# 0018 — CI runs on GitHub's `ubuntu-26.04` with bcvk (step 5)

Date: 2026-10-30. Status: accepted (maintainer: GitHub runner, to be tested).

## What the first runs showed (pull request #6)
- `/dev/kvm` is present on `ubuntu-24.04` and `ubuntu-26.04` for this public repository; the
  udev rule `99-kvm4all.rules` (Kyanite `docs/troubleshooting.md`) is applied anyway.
- bcvk 0.22.0 (release binary, pinned by sha256) runs the VM from a container that mounts the
  host's `/usr` for QEMU and virtiofsd (bcvk `docs/src/installation.md`). `ubuntu-24.04` with
  the distribution's `virtiofsd` failed ("virtiofsd failed to start", exit 2); `ubuntu-26.04`,
  which bcvk's own CI uses, works with `apt install virtiofsd qemu-system-x86`.
- Container storage is moved to `/mnt` and `/usr/share/dotnet` & co. are removed: the build
  and boot test fit. First full green run: build, static checks and boot test in one job
  (PR run 40981254330).
- The release tarball holds one file named `bcvk-x86_64-unknown-linux-gnu`; the setup script
  renames it to `bcvk`.

## Decision
Keep the GitHub-hosted `ubuntu-26.04` runner. No self-hosted runner, so the NUC takes no
inbound job. Pull requests from this repository run build, checks and boot test but never
publish; fork pull requests do not run (no KVM, no secrets).

## Not tested before merge
`workflow_dispatch` and `schedule` only run from the default branch, and pull request runs
skip every publishing step. So login to GHCR, push, cosign, attestations, SBOM, promotion,
the drift pull request, the issue and the retention script have not been exercised in CI.
The same goes for the `gh workflow enable` step (ADR 0017), which runs on `schedule` only.
The first run on `main` is that test; a failure opens the `drift` issue.

## SBOM size (first run on `main`, 2026-10-30)
`actions/attest` refuses an SBOM above 16 MiB. The syft SPDX output of the image was 79 MB
(93k files, 6.6k packages, 122k relationships). A `jq` step keeps the rpm packages and the
relationships between them and drops the file list: 3.4 MB on the local image. The SBOM
therefore lists packages, not files. Measured locally on `dir:` scan, not yet on the registry
scan used in CI.
