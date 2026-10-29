# 0002 — Package lists (step 2)

Date: 2026-10-29. Status: accepted.

## Context
Step 1 left a 43-package whitelist and a blacklist imported from Kyanite whose
names had never been checked. Names verified on 2026-10-29 with `dnf5 repoquery`
in `fedora-bootc:44`: all 43 whitelist names and all 96 blacklist entries exist.
Sizes below come from `dnf5 install --assumeno --setopt=install_weak_deps=False`
on top of the step 1 image.

## Decisions (maintainer, 2026-10-29)
- **Kept, KDE apps:** ark, gwenview, kwrite, kcalc, spectacle (83 MiB, pulls opencv),
  kolourpaint, kde-partitionmanager, kinfocenter, khelpcenter, kmenuedit.
- **Kept, Plasma and system:** plasma-systemmonitor, plasma-disks, plasma-thunderbolt
  (bolt is LGPL, nothing proprietary), flatpak-kcm, kio-admin, kdialog, kde-inotify-survey,
  thermald, kdegraphics-thumbnailers, ffmpegthumbs.
- **Dropped:** kdeplasma-addons (its colour picker is a plasmoid, not the one used
  by applications), ksshaskpass (needs KWallet), pinentry-qt (`pinentry-gnome3` is already
  there through gnupg2), wireguard-tools, alsa-sof-firmware (audio is out of the base),
  ffmpeg-free, gstreamer1-plugins-good, gstreamer1-plugin-openh264. The first five are
  blacklisted and listed in `docs/optional-packages.md`.
- **Not touched:** openh264 stays as the base ships it. Flatpak apps (Waterfox, VLC)
  use their own runtime, so host codecs do not matter to them; whether Waterfox plays H.264
  from Flathub is checked in step 6.
- **Languages:** `glibc-all-langpacks` (227 MiB) and the 155 `hunspell-*` dictionaries
  (all except `hunspell-devel`). Simpler than choosing languages. No translation package
  to choose: KDE `.mo` files ship inside each package.
- **Fonts:** only `default-fonts-core` and `google-noto-emoji-fonts`.
- **Already installed, qt6-qtwebengine (291 MB):** comes from `plasma-discover` →
  `qt6-qtwebview` → `qt6-qtwebengine`. Discover is kept, so it stays.
- **Logos:** `fedora-logos` named in the whitelist, `generic-logos` blacklisted.
