# swarf-os

A personal, minimal Fedora bootc image with KDE Plasma (Wayland), built from
`quay.io/fedora/fedora-bootc` with a whitelist of official Fedora packages, tested in CI and
published as `ghcr.io/swarf-os/image:stable`. [SPEC.md](SPEC.md) is the source of truth;
[PROGRESS.md](PROGRESS.md) says what has been seen working and what has not.

No support, no roadmap, personal use.

## The Fedora logos: read this first

- **This image keeps the Fedora logos, against Fedora's request.** Fedora asks anyone who
  combines Fedora with other software (a "Remix") to remove `fedora-logos`, `fedora-release`
  and `fedora-release-notes` and replace them, and it puts trademark requirements on the word
  "Fedora" and the Fedora logo ([Fedora Remix page](https://fedoraproject.org/wiki/Remix)).
  This image ships `fedora-logos`, the Fedora look and feel, wallpapers and Plasma Setup
  exactly as Fedora ships them, and `os-release` still says `ID=fedora` (with
  `VARIANT_ID=custom`).
- **Strictly personal use.** This is not a Fedora-approved Remix and must not be treated as
  one. If you are not me, act as if you had not seen this repository.
- **If you fork it, re-theme it properly:** logos, release identity and branding. The Fedora
  logos must not travel with your copy.
- **Why the logos stay:** the replacement Fedora provides, `generic-logos`, puts its own
  picture ("the sausage") where people look: the menu button (`start-here.svg`), the system
  logo (`fedora-logo-icon.svg`) and the installer artwork. That picture is the reason: rather
  than ship it, or spend time on artwork for a personal image, the Fedora logos stay. If Fedora objects, the fallback is ready (SPEC, "Identity"): `generic-logos`
  with the KDE logo as the menu icon.
- The licence below covers my files only. It grants nothing on Fedora's trademarks.

## Install

Two ways: a fresh install from the ISO, or switching a machine that already runs Fedora
Kinoite. Either way the machine then follows `ghcr.io/swarf-os/image:stable`.

### From a USB stick (wipes the disk)

Status: the current ISO is installed in a VM only; real-hardware installs are still open
(PROGRESS.md, step 6).

1. **Download** from <https://get.swarf-os.workers.dev>. The page asks for a word. It is not
   a secret, just a filter: anyone curious enough to read the page source will find it.
   Get the ISO, `SHA256SUMS` and `SHA256SUMS.bundle`.
2. **Check** it:
   ```sh
   sha256sum -c SHA256SUMS
   cosign verify-blob --bundle SHA256SUMS.bundle \
     --certificate-identity https://github.com/swarf-os/image/.github/workflows/iso.yml@refs/heads/main \
     --certificate-oidc-issuer https://token.actions.githubusercontent.com SHA256SUMS
   ```
3. **Write the stick** with Fedora Media Writer. Secure Boot can stay on.
4. **Install.** The installer (Anaconda WebUI) only handles the disk and full-disk encryption
   (LUKS passphrase). The passphrase prompt at boot uses the keyboard layout chosen in the
   installer (docs/adr/0037).
5. **First boot:** Plasma Setup asks for language, time zone and the account. It proposes
   `America/New_York` as time zone (the installer does not guess from the network): change it.
6. **Apps:** the menu shows "Internet" and "Media player" at the top of the favourites. Click
   one, answer `y` in the terminal that opens, and Waterfox or VLC is installed from Flathub
   (a network is needed). The launcher then becomes the app.

Details, choosing the disk and what to do if the install fails:
[docs/install-from-usb.md](docs/install-from-usb.md).

### Switch an existing Fedora Kinoite (keeps the account, `/home` and Flatpak apps)

```sh
git clone https://github.com/swarf-os/image && cd image
sudo tools/switch.sh inventory   # must say "layered packages: none"
sudo tools/switch.sh switch      # pins Kinoite, stages ghcr.io/swarf-os/image:stable
systemctl reboot
sudo tools/switch.sh status      # booted = ghcr.io/swarf-os/image:stable, "digest check: MATCH"
```

Kinoite stays in the boot menu (pinned) to go back to. Settings that depend on a package the
image leaves out break after the switch: Kinoite's "Picture of the Day" wallpaper, for
example, leaves the desktop on a missing plugin. Suggested fix, not yet confirmed on a switched
machine: `plasma-apply-wallpaperimage /usr/share/wallpapers/F44` (Fedora's wallpaper package;
the tool accepts an installed wallpaper package). Full procedure:
[docs/switch-and-rollback.md](docs/switch-and-rollback.md).

## Updates

- **Discover updates the system and the Flatpak apps on its own, once a day**, without a
  password (unattended updates, on by default). A new system image is only **staged**: it is
  applied at the next reboot you choose. Nothing ever reboots the machine.
- Limits, inherited from Kinoite: nothing happens without an open Plasma session; there is no
  "on AC power" check; Discover shows no "restart to update" notice once unattended updates
  are on, so a staged image waits silently for your next reboot.
- The system image only ever comes from `:stable`, which is the exact image CI built, checked
  (packages, services, Secure Boot signature) and booted in a VM. A new Fedora release reaches
  `:stable` only after I merge a pull request.
- `bootc-fetch-apply-updates.timer` (it reboots without asking) and `rpm-ostreed-automatic.timer`
  are disabled. Do not use `dnf` on the machine. Firmware updates come through Discover (fwupd).
- Seen in a VM installed from the ISO (2026-11-08): Discover staged the update, by hand and
  unattended, and the machine booted it. Not seen yet on real hardware (PROGRESS.md).
- Every published build has its own version, `<Fedora version>.<build number>` (for example
  `45.20261108.0.63`), so Discover offers our fixes too, not only a new Fedora version
  ([ADR 0043](docs/adr/0043-discover-sees-version-not-digest.md)).

## Login screen theme

The theme chosen in Plasma Setup (dark, for example) only applies to your session: the login screen
stays light, as on Fedora. To bring your theme, keyboard layout and language to it: System Settings
→ Login Screen → « Appliquer la configuration de Plasma... » → « Appliquer » (button name from
the KDE translation, not yet tried on a machine)
([ADR 0042](docs/adr/0042-login-screen-theme.md)).

## Audio

There is **no sound by default**: the image has no audio server. To add it on one machine:

```sh
sudo rpm-ostree install pipewire wireplumber pipewire-pulseaudio pipewire-alsa plasma-pa alsa-sof-firmware
systemctl reboot
```

`alsa-sof-firmware` is the firmware many recent Intel laptops need for their sound card.
Undo with `sudo rpm-ostree uninstall` and the same names (or `sudo rpm-ostree reset` to drop
every layered package), then reboot (from `rpm-ostree(1)`; not run here).

What layering changes (ADR 0035):
- **These packages are not tested by CI.** They come from Fedora's repositories and are
  resolved again on every update, so that machine no longer runs only the tested image. A
  Fedora major upgrade can fail on them; remove them first if it does.
- Discover should keep updating: it goes through rpm-ostree, which keeps layered packages on
  upgrade. Expected, not seen. `bootc upgrade` refuses a layered system (seen).
- **`tools/switch.sh switch` and `pin-to` refuse a layered system.** Do not use `bootc switch`
  by hand there: it does not refuse, it **removes the layered packages without a word** (seen in
  a VM). Use `rpm-ostree rebase` instead (see Rollback).
- Seen in a VM (2026-11-05): the install and reboot, the PipeWire units enabled, `bootc upgrade`
  refusing, `bootc switch` staging a deployment without the layer and `rpm-ostree rebase`
  staging one with it (that boot not observed). Not seen: actual sound, on any machine.

## Rollback

There is **no automatic rollback**: if a new image misbehaves, you go back by hand.

- **Once, from the boot menu:** every deployment is listed; `(ostree:0)` is the default,
  `(ostree:1)` the previous image (all swarf-os entries are titled `Fedora Linux 44 (Forty Four)`,
  only the number differs; a switched Kinoite is the entry titled `(Kinoite)`). The menu may show
  for one second only: press an arrow key as soon as it appears.
- **Until further notice:** `sudo tools/switch.sh rollback`, then `systemctl reboot`, then
  `sudo tools/switch.sh status`. Run it again to come back. Without the script, `sudo bootc
  rollback` does the same between two swarf-os images (bootc refuses a Kinoite target; the
  script then uses `rpm-ostree rollback`).
- **A plain rollback does not last.** The previous deployment still follows `:stable`, so
  Discover's next daily update stages the newer image again. To stay on an older image, pin its
  digest (`sha256:…`, from `status` or GHCR):
  ```sh
  sudo tools/switch.sh pin-to sha256:<digest>   # never updated
  sudo tools/switch.sh switch                   # later: back to :stable and daily updates
  ```
  The first time, the script also pins the booted deployment so it stays in the boot menu
  (`sudo tools/switch.sh unpin INDEX` frees it). Without the script:
  `sudo bootc switch ghcr.io/swarf-os/image@sha256:<digest>`, and back with
  `sudo bootc switch ghcr.io/swarf-os/image:stable`.
  With audio layered, use rpm-ostree, which keeps the layer:
  ```sh
  sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/swarf-os/image@sha256:<digest>
  sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/swarf-os/image:stable   # back
  ```
  (The first command was seen staging in a VM; the return to `:stable` was not run.)
- `/etc` belongs to each deployment: a rollback brings back that deployment's `/etc`.
- **After every reboot, check `status`.** If the booted image did not change, the new
  deployment failed to install at shutdown and the old one booted:
  `journalctl -b -1 -u ostree-finalize-staged` says why.

`tools/switch.sh` needs a clone of this repository; `git` and `jq` are in the image. More:
[docs/switch-and-rollback.md](docs/switch-and-rollback.md), ADR 0034.

## Licence

[MIT](LICENSE), for the files of this repository only. It grants no right on Fedora's
trademarks, logos or name, nor on any package the image installs (each keeps its own licence).

## Contact

No support, no contact. Open an issue if it is a bug. Security reports: see
[SECURITY.md](SECURITY.md).
