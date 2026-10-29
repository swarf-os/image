# Packages left out on purpose, possibly useful later

Names checked with `dnf5 repoquery` in `fedora-bootc:44` on 2026-10-29.
Not in `whitelist.txt`. To use one, add it to the whitelist (and remove it from
`blacklist.txt` if it is listed there), or layer it with `rpm-ostree` on one machine.

## Audio (no audio server by default, see SPEC)
- `pipewire`, `wireplumber`, `pipewire-pulseaudio`, `pipewire-alsa`, `plasma-pa`: the audio stack (all in `blacklist.txt`).
- `alsa-sof-firmware` (10 MiB): Sound Open Firmware. Probably needed for the sound card of recent Intel machines, even with the audio stack layered (to verify on the Framework 13).
- `ffmpeg-free` (18 MiB, 21 packages, including `jack-audio-connection-kit` and `openal-soft`), `gstreamer1-plugins-good` (9 MiB), `gstreamer1-plugin-openh264`: media playback.

## Passphrase and key dialogs
- `pinentry-qt` (0.2 MiB): Qt dialog for GnuPG. `pinentry` and `pinentry-gnome3` are already in the image through `gnupg2`.
- `ksshaskpass` (0.2 MiB): ssh-add helper that uses KWallet. Contradicts "no KWallet".

## Network
- `wireguard-tools` (0.3 MiB): `wg` and `wg-quick` command line tools (NetworkManager handles WireGuard without them).

## Plasma extras
- `kdeplasma-addons` (15 MiB, +`hidapi`): additional plasmoids, including the colour picker widget (`org.kde.plasma.colorpicker`) and a KRunner colours plugin.

## Fonts (declined; the image keeps `default-fonts-core` and `google-noto-emoji-fonts`)
- `default-fonts-cjk` (116 MiB), `default-fonts-other` (16 MiB, 114 packages), `google-noto-serif-fonts` (52 MiB), `urw-base35-fonts` (11 MiB), `google-droid-sans-fonts` (6 MiB), `gdouros-symbola-fonts` (4 MiB), `open-sans-fonts` (2 MiB), `liberation-sans-fonts` (2 MiB), `liberation-mono-fonts` and `liberation-serif-fonts` (1 MiB each), `abattis-cantarell-fonts` (0.5 MiB).
- All locales are installed but only these two font packages, so CJK and other non-Latin scripts will likely show boxes until the fonts above are added.
