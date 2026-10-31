# 0019 — The ISO is built in CI, rootless, with a pinned Titanoboa script (step 6)

Date: 2026-10-30. Status: accepted (maintainer: build in GitHub CI; local build checked).

## Decision
- `.github/workflows/iso.yml` builds the ISO weekly (cron, Sunday), on `workflow_dispatch`, and
  on pull requests that touch the ISO files. It resolves `ghcr.io/swarf-os/image:stable` to a
  digest and installs exactly that digest. The ISO is kept as a workflow artifact (14 days).
  Release assets are limited to 2 GiB and the ISO is 5.6 GB, so the permanent home is the R2
  bucket of step 7.
- `tools/iso-build.sh BASE` does the work and runs the same on a workstation: no `sudo`.
  1. `skopeo copy` of the image to an OCI directory (the payload to install).
  2. `podman build` of `iso/Containerfile`: `FROM` the image, plus Anaconda WebUI, the live
     bits (dracut `dmsquash-live`, `livesys-scripts`, a GRUB EFI), the Flatpaks and the payload.
     It needs `--cap-add sys_admin --security-opt label=disable` (rootless `flatpak install`
     and dracut).
  3. Titanoboa's `build_iso.sh` (ublue-os/titanoboa, Apache-2.0), downloaded at commit
     `5c457c3d0518bd17e754be0fd98a60d29d26abb4` and checked against its sha256, run in a
     `quay.io/fedora/fedora` container with the live image mounted by `--mount type=image`.
     It makes the squashfs (zstd 19), the EFI tree and the ISO from
     `/usr/lib/bootc-image-builder/iso.yaml` (label, GRUB entries) in the image.
- Titanoboa's `main.sh` (which needs `sudo podman`) is not used: only `build_iso.sh`, the part
  that does the work.

## Consequences
- Only the pinned script and `fedora:latest` (the tool container, at run time) are not
  digest-pinned. A change of Titanoboa is a one-line bump of two constants.
- The ISO boots on UEFI only: the BIOS code of `build_iso.sh` tests a directory with `-f` and
  never runs. Both machines are UEFI.
- Measured locally: 19 min for the live image, 9 min for Titanoboa, 5.57 GB. The CI duration is
  not known before the first run on `main` (`workflow_dispatch` only works from `main`).
