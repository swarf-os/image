# 0027 — No preinstalled Flatpaks: apps installed on demand (step 6b, maintainer decision)

Date: 2026-11-02. Status: implemented in step 6b (see "Seen / not seen"). Supersedes ADR 0021:
the offline copy is removed.

## Decision
- The ISO carries no Flatpak and the installer has no `%post` at all (`iso/flatpaks` deleted,
  no `flatpak install`, no `rsync`, no `/proc/sys` remount in `iso/build.sh`).
- Two launchers, "Internet" (icon `applications-internet`) and "Media player"
  (`applications-multimedia`), both Breeze category icons, no brand logo. They are pinned first in
  the Plasma menu favourites (`/usr/share/swarf/xdg/kicker-extra-favoritesrc`, read by the
  kicker plugin that Kickoff uses: `kicker-extra-favoritesrc`, `Prepend`, `IgnoreDefaults` found
  in `libkickerplugin.so` of plasma-workspace 6.7.5). It replaces Fedora's list (kde-settings,
  later in `XDG_CONFIG_DIRS`): same entries minus `preferred://browser` and Kontact.
- Both start one script, `~/.local/share/swarf/get-app <app id>`, in Konsole: plain English, no
  menu (maintainer, 2026-11-02): it says what the app is, warns on the live system (the app
  goes to RAM and is lost at restart; detected by `rd.live.image` on the kernel command line;
  a fixed text, not computed: "about 3 GB of free memory" to install, more to use it, risky.
  Rounded up from `flatpak list --system` in the VM, 2026-11-02: Waterfox 515 MB +
  freedesktop Platform 671 MB + GL 462 MB (+ 462 MB extra) + codecs 43 MB; VLC 150 MB + KDE
  Platform 974 MB + the same GL; both apps together 2.8 GB on disk),
  checks that the Flathub URL from `flatpak remotes` answers (otherwise a clear message and
  exit), asks `Install Waterfox (web browser)? yes or no [y/n]`, runs
  `flatpak install --system -y flathub <id>` with its progress, then starts the app.
- Everything lives in the user's home, copied from `/etc/skel` at account creation (Plasma
  Setup's helper calls `useradd`). Each launcher is named after its app's own desktop file
  (`net.waterfox.waterfox.desktop`, `org.videolan.VLC.desktop`), so it hides the app until the
  app is installed. After the install the launcher is deleted and the same favourite now starts
  the real app. Once both apps are installed the script deletes itself and its directory
  (the program sits in a function called on the last line, so bash has read the whole file
  before the `rm`). A launcher clicked when its app is already installed (Discover, another
  user) deletes itself and starts the app, without a window.
- The live ISO keeps the launchers (maintainer: live and installed system identical).
- No uninstall in the script: Discover does it.
- No privilege in the script. Flatpak's own polkit rule (`org.freedesktop.Flatpak.rules`) lets a
  local active `wheel` user install without a password, so the admin account made by Plasma
  Setup gets no prompt; any other user gets polkit's admin password prompt. Kept as Flatpak
  ships it (maintainer, 2026-11-02).
- Zero maintenance: no version numbers; the app ids and their plain names are listed in the
  script; the ids also appear in the launcher file names and the favourites file (needed for
  the favourite to survive the install, maintainer choice).

## Why
The first real install (Packard Bell laptop, 2026-11-02) failed in the Flatpak `%post`: `rsync -X`
could not remove the `security.selinux` attribute on 43,960 files (harmless, `setfiles` relabels
right after) and exited with code 23; the `set -e` added in PR #22, never run before, then stopped
the install. The offline copy also added several GB to the ISO and a failure point to every install.

## Consequences
- Installing an app needs a network (Wi-Fi firmware: ADR 0028).
- Only accounts created from this image get the launchers (`/etc/skel`); older accounts do not.
- The copy in a home is never updated by an image update: a bug fixed later reaches new accounts
  only; existing ones need a manual fix (or Discover instead). Accepted by the maintainer
  (2026-11-02) to keep the self-deletion: `/usr` is read-only and shared by all accounts, `/var`
  and `/etc` belong to root and `/var` is never updated by bootc either. Hence a thorough VM test
  before the first real install.
- The favourites apply to a new user's first menu; a user who edits them keeps their own list.

## Seen / not seen
Seen (VM only, 2026-11-02; details in PROGRESS.md, session 6b): install from the local step 6b
ISO without `%post`; launchers and script in the new account; Waterfox and VLC installed from
the launchers with no password (admin account); launcher replaced by the app in the favourites;
self-deletion once both apps are installed; offline, refusal and live-warning messages.
Not seen: the CI ISO from `main` after the drift PR; any real hardware install.
