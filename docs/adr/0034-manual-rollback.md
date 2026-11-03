# 0034 — Rollback is manual: boot menu, `tools/switch.sh rollback`, stay back with a digest

Date: 2026-11-03. Status: accepted (maintainer: "Corriger la SPEC"). Rehearsed on a Kinoite 44 VM
(step 8, PROGRESS Session 8); still to be seen on the Packard Bell.

## Decision
- No automatic rollback. The SPEC said "rollback to the previous image if a boot fails"; with the
  ostree backend bootc only detects a failed *finalization* (the staged deployment is dropped, the
  old one boots) and does not count boots. Boot counting stays an open question, not a promise.
- To go back, one of:
  1. the boot menu: GRUB lists every deployment, `(ostree:0)` is the default; Kinoite is the one
     titled `(Kinoite)`. One boot only, the default does not change;
  2. `tools/switch.sh rollback`: swaps the next boot with the previous deployment. It calls
     `bootc rollback`, or `rpm-ostree rollback` when the target is not a container image (bootc
     refuses it: "Rollback is not container image based", seen in the VM);
  3. `tools/switch.sh default INDEX` (`ostree admin set-default`): any deployment, for example the
     pinned Kinoite when it is no longer `[1]`.
- To *stay* back: `tools/switch.sh pin-to sha256:…` (`bootc switch ghcr.io/swarf-os/image@DIGEST`).
  A digest never moves; a dated tag is overwritten within the day and is pushed before the boot test.
  Back to normal: `tools/switch.sh switch` (`:stable`).

## Why a plain rollback does not last
The rolled-back deployment still follows `:stable`. Discover's unattended update (ADR 0009, daily)
stages `:stable` again; the timers are disabled, so Discover is the only agent. bootc-rollback(8)
and ostree-admin-set-default(1) both warn that an update agent can revert the change. Seen in the
VM after a rollback from a newer to an older `:stable` image: `rpm-ostree upgrade --check` (the
daemon Discover's rpm-ostree backend talks to) printed `AvailableUpdate` (the newer image), while
`bootc upgrade --check` printed `No changes`. On a digest origin both found nothing. Discover
itself was not run.

## Sources (read 2026-11-03, host versions bootc 1.17.1, rpm-ostree 2026.3, ostree 2026.4)
- `bootc-rollback(8)`, `bootc-boot-failure-detection(7)`, `bootc-switch(8)`.
- `rpm-ostree(1)` "rollback"; `ostree-admin-set-default(1)`; `ostree-admin-pin(1)`.

## Consequences
- After every reboot, check with `tools/switch.sh status`. A failed finalization is silent: the old
  deployment boots and the staged one is gone (seen in the VM, caused by its `/boot` layout);
  `journalctl -b -1 -u ostree-finalize-staged` tells why.
- `/etc` is per deployment: a rollback brings back that deployment's `/etc` (SPEC, by design).
