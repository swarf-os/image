# 0015 — What the manifest gate compares (step 5)

Date: 2026-10-29. Status: accepted.

## Context
SPEC.md lists the base digest in `manifest/`. The base digest and every package version change
almost daily; if they gated promotion, `:stable` would never move.

## Decision
`tools/manifest.sh` writes, and `tools/manifest-check.sh` compares with `manifest/`:
- `packages.txt`: `name.arch` of every installed package, no versions;
- `units.txt`: unit files enabled, masked or linked (`systemctl list-unit-files`);
- `repos.txt`: names of `/etc/yum.repos.d/*.repo`;
- `version.txt`: `VERSION_ID`.
`manifest/info.txt` (base digest, kernel, package count) and `manifest/tested-digest` are
recorded but never compared. Blocking checks that are not manifest comparisons: blacklist
(packages and repositories), exactly one kernel in `/usr/lib/modules`, `sbverify --list` on its
`vmlinuz` showing the Fedora Secure Boot signer and CA, and `crypt` in `lsinitrd -m` of the
initramfs (read 2026-10-29 on the step 4 image: signer `OU=Fedora Secure Boot Signer`,
issuer `OU=Fedora Secure Boot CA 20200709`, `crypt` listed).

## Consequences
A blocking failure stops everything and opens the issue (ADR 0017). A manifest difference alone
publishes `:testing` and holds `:stable` (ADR 0016). `manifest/` is never edited by hand: only
`tools/drift-pr.sh` rewrites it, in the drift pull request.

The boot test (`tools/boot-test.sh`) compares the booted VM's units with the static listing of
the same image, not with `manifest/`: it proves runtime matches what was built, while the
manifest gate alone compares with the committed manifest. Otherwise a unit change would fail the
boot test and the drift pull request would never be opened.
