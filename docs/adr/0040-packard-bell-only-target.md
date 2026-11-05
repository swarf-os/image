# 0040 — The Packard Bell is the only hardware target

Date: 2026-11-05. Status: accepted (maintainer: "On abandonne sur le framework et le nuc. On utilise le packerdbell.").

## Context
SPEC step 6 asked for USB installs on the Intel NUC and the Framework 13 Pro. The NUC's spare SSD
holds the maintainer's Steam library (no install there, 2026-11-04) and the Framework install was
put off. The Packard Bell laptop was installed from the USB stick on 2026-11-04 (PROGRESS, session 6).

## Decision
NUC and Framework are dropped as targets. The Packard Bell is the hardware target; step 6 is ticked
on its install plus the VM checks of the LUKS keymap fix (ADR 0037). `docs/install-from-usb.md`
loses its NUC and Framework sections (generic disk advice instead). The NUC stays the build host.

## Not seen
The F45 ISO (ADR 0038).
