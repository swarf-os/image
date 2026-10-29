# 0008 — Services, os-release and lint cleanup (step 3)

Date: 2026-10-29. Status: accepted.

## Services
Disabled: `bootc-fetch-apply-updates.timer`, `systemd-homed` (+ `-activate`),
`flatpak-add-fedora-repos`, `rpm-ostree-countme.timer`, `mdmonitor`, `raid-check.timer`.
Masked: `geoclue`, `avahi-daemon` (+ socket). These were already in the step 1 preset and
`configure.sh`; step 3 only verifies them in the VM (`tests/check-config.sh`). `geoclue2` and
`avahi` stay installed (hard dependencies, step 2). `systemd-coredump.socket` is masked (0003).

## os-release
`VARIANT_ID=custom` (the value Kyanite ADR 0017 chose). `configure.sh` replaces the line
if present and appends it otherwise; `/usr/lib/os-release` belongs to
`fedora-release-identity-basic`. `ID=fedora` is unchanged. Discover's rpm-ostree backend
reads `VARIANT` (not `VARIANT_ID`) to label the booted deployment, so nothing visible changes.
The project name is not written anywhere in the image.

## `bootc container lint` warnings
The bare `fedora-bootc:44` image passes with no warning; both come from our packages.
- `nonempty-run-tmp`: `packages.sh` removes `/run/dnf`, `/run/plasmalogin`,
  `/run/selinux-policy` at the end of its layer (`plasmalogin.conf` recreates its directory at
  boot).
- `var-tmpfiles`: `system/usr/lib/tmpfiles.d/swarf-var.conf` declares the directories the
  lint lists (names, modes and owners as printed by `bootc container lint --no-truncate`).
  Regenerating caches (`libX11`, `ldconfig`, `swcatalog`) are deleted instead.
  `/var/lib/authselect/checksum` (owned by no package) is deleted too: in a container,
  `authselect check` still reports "Current configuration is valid" without it.
