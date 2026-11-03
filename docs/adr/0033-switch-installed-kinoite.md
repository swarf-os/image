# 0033 — Switch an installed Kinoite with `bootc switch`, unverified, and check the digest

Date: 2026-11-03. Status: accepted (maintainer, step 8: the Packard Bell runs Fedora Kinoite 44
with no layered package, only Flatpak apps and a home directory to keep).

## Decision
`tools/switch.sh switch` (run as root on the machine):
1. refuses if the booted deployment has layered packages (bootc refuses them, see below);
2. if nothing is pinned yet, pins the booted deployment (`ostree admin pin booted`): Kinoite,
   whatever its origin, stays in the boot menu and is never garbage-collected;
3. creates `/etc/plasma-setup-done` if it is missing and an account exists, so that Plasma Setup
   (`ConditionPathExists=!/etc/plasma-setup-done`) does not take the screen of a machine already set
   up (seen in the VM rehearsal before this rule);
4. runs `bootc switch ghcr.io/swarf-os/image:stable` and checks that a deployment is staged.
After the reboot, `tools/switch.sh status` compares the booted image digest with the digest the tag
points to now (`skopeo inspect`) and prints MATCH or DIFFERENT.

No signature check on the switch: the trust is the same as an ISO install (TLS to ghcr.io). The
image is signed keyless by GitHub Actions (ADR 0014), but `containers-policy.json` `sigstoreSigned`
`fulcio` identity takes only `subjectEmail` + `oidcIssuer`; the GitHub workflow identity is a URI
SAN, so it cannot be expressed. The maintainer chose not to work around it ("la voie standard,
c'est l'ISO").

## Sources (read 2026-11-03, versions installed on the host)
- `bootc-switch(8)`, bootc 1.17.1: `bootc switch [--apply] [--retain] [--enforce-container-sigpolicy] TARGET`.
- `bootc-relationships(7)`: client-side layering with rpm-ostree makes `bootc upgrade/switch` fail.
- `ostree-admin-pin(1)`, ostree 2026.4: `ostree admin pin INDEX|booted|pending|rollback`, `--unpin`.
- `containers-policy.json(5)`, containers-common 0.67.2: `fulcio` keys `caPath`/`caData`,
  `oidcIssuer`, `subjectEmail`.

## Consequences
- The user account, `/var/home` and the system Flatpak installation are kept (`/var` is not
  touched). `/etc` is a 3-way merge: files the user changed locally keep their local version, so
  swarf-os defaults for those files do not apply; `inventory` counts them (`ostree admin config-diff`).
- The pinned Kinoite deployment costs disk space until `tools/switch.sh unpin INDEX`.
