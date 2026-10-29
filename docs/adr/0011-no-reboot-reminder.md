# 0011 — No reboot reminder (step 4)

Date: 2026-10-29. Status: accepted (maintainer decision).

## Context
`DiscoverNotifier.cpp` shows the reboot notification only when unattended updates are off,
so a staged image waits silently for the next reboot (accepted in SPEC).

## Decision
No reminder, no timer, no script. The maintainer relies on the Discover icon in the Plasma
panel. Reboot is never forced.

## Consequences
The icon appears when updates are available; whether it still shows something once the
image is staged is not verified (needs a real update, see 0009). A machine that is never
rebooted stays on an old image. Revisit in step 8 if that happens.
