# 0022 — Language and keyboard keep Fedora's defaults (step 6, maintainer decision)

Date: 2026-10-30. Status: accepted.

## Decision
The kickstart sets no `lang` or `keyboard`. The installer starts in English with a US keyboard
and the user changes them in the WebUI if needed (the LUKS passphrase field has its own keyboard
selector). Plasma Setup asks for the language again at first boot.

## Why
Less to maintain, no layout of ours to keep in sync. The first VM install forced `fr` through a
test kickstart: `vconsole.conf` of the installed system then said `KEYMAP=fr` and the
passphrase typed with a US layout failed once at the LUKS prompt. That test is not a reference.

## Consequences
Checked on the second VM install (2026-10-31), the SPEC sentence "the layout chosen in the
installer applies at the LUKS prompt" is **false**. The WebUI layout was changed to `fr`, the
installed system asked for the passphrase with a **US** keymap (the passphrase `asdfgh` only
worked with US key codes). The prompt follows the initramfs keymap, not the installer choice.
The SPEC sentence is replaced by: the LUKS prompt is US/English by default; choose a passphrase
that types the same on the layouts you use, or type it with the US layout.
Not decided: forcing the installer layout into `vconsole.conf` (a kickstart `keyboard` line would
do it, but then the default is no longer Fedora's); to settle with the maintainer after the
hardware install.
