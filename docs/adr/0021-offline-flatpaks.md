# 0021 — Flatpaks are installed in the live image and copied to the target (step 6)

Date: 2026-10-30. Status: accepted (Waterfox and VLC installed from the ISO and start in the VM).

## Decision
- `iso/build.sh` installs the applications of `iso/flatpaks` system-wide from Flathub when the
  live image is built.
- `%post --nochroot` in `iso/installer.ks` copies `/var/lib/flatpak` with
  `rsync -aAXUHK` to `/mnt/sysroot/var/lib` (the target's `/var` is bound there after the bootc
  deployment, the script checks it is a mountpoint) and relabels it with `setfiles` from the
  installed policy.
- The remote stays `flathub`: updates come from the network afterwards.

## Why
Neither Anaconda nor bootc has an offline Flatpak mechanism; this is Bazzite's approach.

## Consequences
The ISO grows by the size of the applications and their runtime. The labels were
`container_file_t:s0:c1022,c1023` (the build ran in a container) on the first VM install, which
`restorecon -n` showed; the `setfiles` fix is checked on the second install.

First attempt at the relabel failed the install: `setfiles` got `/mnt/sysroot/...` and `/mnt` is a
symlink to `/var/mnt` in the live session ("open(...) failed: Not a directory"). The script now
passes `realpath /mnt/sysroot`; checked by hand with `setfiles -n` on the failed target, which
lists the expected `container_file_t` to `var_lib_t` relabels.
