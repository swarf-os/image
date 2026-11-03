# 0036 — What the README says (step 9)

Date: 2026-11-05. Status: accepted (maintainer, 2026-11-05).

## Decision
- **Install** has two paths: the USB ISO, and a short switch of an existing Kinoite with
  `tools/switch.sh` (inventory, switch, reboot, status); details stay in
  `docs/install-from-usb.md` and `docs/switch-and-rollback.md` (maintainer choice).
- **The download page word is not printed.** The README only says that anyone reading the page
  source will find it (maintainer). The word stays in ADR 0030 and the Worker code.
- **Fedora logos** (SPEC, "Identity"): kept against Fedora's request, strictly personal use,
  "act as if you had not seen this repo", forks must re-theme, a short critique of
  `generic-logos`, the licence grants nothing on Fedora's trademarks. The Fedora request is
  quoted from the Fedora wiki page "Remix" (https://fedoraproject.org/wiki/Remix, read
  2026-11-05, oldid 549811): remove `fedora-logos`, `fedora-release`, `fedora-release-notes`
  and replace them; `generic-logos` is provided for that; trademark requirements on the word
  and the logo. `docs.fedoraproject.org/en-US/remix-building/remix-guidelines/` answered
  "Access Denied" (Anubis) and was not read.
- The `generic-logos` files named in the critique come from `dnf5 repoquery -l generic-logos`
  in `localhost/swarf-os:dev` (2026-11-05): `start-here.svg`, `fedora-logo-icon.svg`, Anaconda
  pixmaps.
- **Updates and audio** are described as configured, with what is not yet seen stated
  (real Discover update, sound, real-hardware ISO install). **Licence**: the README says MIT,
  the `LICENSE` file since step 1; the SPEC question "MIT or Apache-2.0" stays open for the
  maintainer to confirm.
