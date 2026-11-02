# 0027 — No preinstalled Flatpaks: apps installed on demand (step 6b, maintainer decision)

Date: 2026-11-02. Status: accepted, not implemented (step 6b). Supersedes ADR 0021 once step 6b
removes the offline copy.

## Decision
- The ISO carries no Flatpak and the installer has no Flatpak `%post`.
- Two generic launchers, "Internet" and "Media player", pinned in the Plasma menu, start one
  small script: a step-by-step text interface in plain English that asks what to install. For now
  the only choices are Waterfox and VLC, from Flathub (system-wide).
- The script has no privilege of its own: Flatpak's polkit prompt asks for the user's password.
- The script must need no maintenance: no version numbers, no app list beyond these two.

## Why
The first real install (Packard Bell laptop, 2026-11-02) failed in the Flatpak `%post`: `rsync -X`
could not remove the `security.selinux` attribute on 43,960 files (harmless, `setfiles` relabels
right after) and exited with code 23; the `set -e` added in PR #22, never run before, then stopped
the install. The offline copy also adds several GB to the ISO and a failure point to every install.

## Consequences
- Installing an app needs a network: Wi-Fi must work on the target laptops (step 6b adds the Intel
  Wi-Fi firmware missing on that laptop).
- To decide in step 6b: the TUI tool, how the launcher opens a terminal, what happens offline.
