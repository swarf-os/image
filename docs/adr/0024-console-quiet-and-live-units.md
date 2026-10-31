# 0024 — `quiet` kernel argument, and no bootloader update in the live (step 6)

Date: 2026-10-30. Status: accepted (to be confirmed on the second VM install).

## Context
After Plasma Setup the screen showed a black text console. The journal shows no reboot: the
`plasma-setup` session ended, `plasmalogin` took over, and the VT switch exposed the console,
which prints the kernel messages at level 7 (`kernel.printk = 7 4 1 7`) because the command line
has no `quiet`: `audit: type=1106 ... PAM:session_close` lines (no `auditd` runs) and
`Lockdown: systemd-logind: hibernation is restricted`. They are information, not errors.

## Decision
- `system/usr/lib/bootc/kargs.d/10-quiet.toml`: `kargs = ["quiet"]`.
- The live image masks `bootloader-update.service` (`iso/build.sh`): `bootupd` finds no `/boot` or
  `/sysroot` block device there and the unit showed "Failed" at every boot of the ISO. The
  installed system keeps it.
