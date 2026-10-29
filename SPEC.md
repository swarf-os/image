# SPEC — swarf-os, a personal Fedora bootc image (Plasma, minimal)

Draft 10 · 2026-10-29 · names decided (`swarf-os`). Fedora bootc path; the Arch version is kept as `claude/SPEC-arch-backup.md` in the planning project (fallback if this path becomes too hard). Kyanite archive (read for draft 8): `fbmguerin/archive-kyanite-os-fedora-custom`.
Sources: the Kyanite ADRs, Containerfile, lists and roadmap (read 2026-10-29), plus two Arch/distro comparison reports. Items marked (to verify) were not checked against a primary source in this draft.
Draft 10 (2026-10-29, step 2): KDE apps, locales and fonts decided (ADR 0002); the 155 `hunspell-*` and all glibc locales are kept after all.
Draft 9 changes: project, organization, repository, image and ISO names fixed; contact and security section added; name availability check still pending.
Draft 8 changes: Fedora logos kept knowingly, free licence, README wording decided, fallback if Fedora objects.

## Why bootc
- Zero intervention, updates without effort. A machine only ever receives an image my CI tested.
- Atomic updates, and rollback to the previous image if a boot fails.
- Fedora's Secure Boot chain works as is (shim signed by Microsoft → GRUB → Fedora kernel). No key enrollment, no setup mode.
- A minimal image made this way is reusable for other projects.
- Expected failures come from my own configuration and CI, not from Fedora.

## Goal
- A minimal Fedora bootc image with KDE Plasma (Wayland), installed from my own ISO. Nothing more.
- A simple remix for personal use, public only to simplify deployment and let others reuse the code. No support, no roadmap, no branding work. Code under a free licence.
- The image is clean by construction: the CI builds it from the whitelist, checks it, and only then publishes. Users clean nothing after install.
- Least possible to maintain: official Fedora packages, Fedora's signed kernel, unmodified.
- Not wanted by default: Bluetooth, printing, modems, audio server, remote access (ssh server, RDP, VNC), X11 session, telemetry, apps imposed by the distribution.

## Principles carried over from Kyanite (still valid)
- Additive base: start from the bare `quay.io/fedora/fedora-bootc:N` and name every package (ADR 0001/0002). Subtractive images silently build whatever Fedora adds.
- Never force a removal (`rpm --nodeps`): mask or disable the service instead (ADR 0002).
- Fedora's signed kernel, never rebuilt, no out-of-tree modules (Secure Boot without MOK, ADR 0005).
- System updates come only from my registry (tested, signed image), never `dnf upgrade` on the machine.
- KDE defaults go in `/usr/share/<name>/xdg/` read through `XDG_CONFIG_DIRS`; `/etc` stays untouched except my named files (ADR 0014).
- Test in a VM, rootless. Never `sudo`/`run0` on the host from the agent's shell (broke systemd on the build host).

## Identity, naming, branding and licence
- **Names (decided 2026-10-29)**:
  - project and ISO prefix: `swarf-os` (swarf: the chips and filings cut away from a machined part, which is what the blacklist removes);
  - GitHub organization: `swarf-os`; repository: `swarf-os/image`;
  - registry image: `ghcr.io/swarf-os/image`;
  - ISO file: `swarf-os-<fedora major>-x86_64.iso` (for example `swarf-os-44-x86_64.iso`), with a signed `SHA256SUMS` carrying the same prefix. No date in the name; add `-YYYYMMDD` only if several ISOs are kept side by side.
  - Availability of `swarf-os` (GHCR package, search engines, trademarks) is not yet checked.
- The name is for the project, repo and ISO only. It is not the image identity: nothing in the image carries it.
- **Plain Fedora branding, kept knowingly**: `fedora-logos`, Fedora look and feel, wallpapers and Plasma Setup exactly as Fedora ships them. Every Kyanite branding workaround goes away. No name or logo of my own in the image.
- This goes against Fedora's request that a remix replace `fedora-logos` (Fedora Remix guidelines, as cited in Kyanite ADR 0003; not reread in this draft). Decision: accepted for strictly personal use.
- **README says so plainly**:
  - the Fedora logos are kept in violation of Fedora's requests;
  - strictly personal use: do not treat this as a Fedora-approved remix, and act as if you had not seen this repo;
  - anyone who forks it must re-theme it properly (logos, release identity, branding);
  - a short critique of the `generic-logos` package, whose picture (the "sausage") is the reason the logos are kept.
- **Fallback if Fedora objects**: swap `fedora-logos` for `generic-logos`, and keep its picture off screen by setting the launcher icon to the KDE logo in the default Plasma panel layout, a file the project owns (to verify in the image). If that is not clean, use Kyanite's proven way: delete the files of the Fedora look and feel (`plasma-lookandfeel-fedora`, keep the packages), which restores the KDE logo as menu icon, with the Plasma Setup compatibility workaround (`docs/troubleshooting.md`).
- `os-release`: keep `ID=fedora`, add `VARIANT_ID` to mark the image as custom.
- **Licence**: free licence for the code (MIT or Apache-2.0, to choose). It covers my files only and grants nothing on Fedora's trademarks; the README states that.
- Registry: GHCR. Forgejo later.

## Contact and security
- No public e-mail address. No support: the README says "no support, no contact; open an issue if it is a bug".
- Commits use the GitHub noreply address. The organization's billing e-mail is a forwarding alias, never shown in the profile.
- Security reports: GitHub "Private vulnerability reporting" enabled on the repository, referenced from `SECURITY.md`.
- Signing: cosign keyless (GitHub OIDC), so the identity is the workflow of this repository, not an e-mail. `SHA256SUMS` signing identity to decide in step 5/6 (keyless or a dedicated key).
- A project domain (for the Cloudflare download page, step 7) would add `security@` as a forwarding alias; not needed before step 7.

## Build model
```
ARG FEDORA_MAJOR=N
FROM quay.io/fedora/fedora-bootc:${FEDORA_MAJOR}
```
1. In one layer: remove blacklisted base packages, install the whitelist with `install_weak_deps=False`, fail if anything blacklisted (packages or repos) is still present. The image keeps no trace of what was removed.
2. Copy `system/` (config files owned by the project).
3. `configure.sh` for what files cannot express (service disable/mask, `/opt` link, `os-release`).
4. `bootc container lint`.
- Dev variant: same build plus ssh, in `tests/Containerfile`. Never published.
- Build scripts are reused from the archive (`packages.sh`, `configure.sh`), reviewed and stripped of all branding code (see Reuse).

## Package lists
- `whitelist.txt`: packages I ask for, commented by group. Only file to edit to add software.
- `blacklist.txt`: `[remove]` (packages, globs allowed) and `[repos]` (forbidden repositories). No RPM Fusion, negativo17, COPR.
- `manifest/`: generated by CI (packages with arch, enabled services, `*.repo`, `VERSION_ID`, base digest). Never edited by hand.
- Starting point: the Kyanite whitelist (1,427 packages, 4.05 GB installed at the last trial) trimmed to the minimal set below. Plasma critical-path packages stay (`plasma-desktop`, `plasma-workspace`, `kwin`, …); `kwayland-integration` stays out (pulls Qt5/KF5).
- Kept as Fedora ships them: `plasma-setup`, `fedora-logos` (no `generic-logos`).
- Minimal desktop: Plasma, Discover, Dolphin, Filelight, Konsole, System Settings. Other KDE apps (Ark, Gwenview, KWrite, KCalc, Spectacle, KolourPaint, Partition Manager, KInfoCenter, Help Center, KMenuEdit): all kept (decided in step 2, ADR 0002; KDE apps stay RPM, never Flatpak, as decided on 2026-10-28).
- Dropped from the Kyanite list: `just`, `usbguard`, `generic-logos` and the all-language font list (only `default-fonts-core` and `google-noto-emoji-fonts` are kept, so CJK and other non-Latin scripts may show boxes). Kept after all (step 2, ADR 0002): all glibc locales (`glibc-all-langpacks`) and the 155 `hunspell-*` dictionaries.
- Blacklist: reuse the Kyanite one (Bluetooth, printing, modems, audio server, NM plugins, PackageKit, X11 session, Qt5, KWallet front-ends, excluded apps, server/enterprise parts, out-of-scope firmware, forbidden repos), minus `fedora-logos`. Keep `fedora-third-party` and `fedora-flathub-remote` out (full Flathub instead).
- Hard dependencies that stay installed: `geoclue2`, `avahi` (via kio-extras/nss-mdns), `kwallet` library. Services masked/disabled, packages kept so RPM dependencies stay intact.

## Settings
- No hardening beyond what is free to keep. Level 1 hardening (ADR 0006): reread, decide if any of it stays.
- Telemetry: off everywhere (ADR 0015 plan: KUserFeedback, Discover reviews, NM connectivity check, `rpm-ostree-countme.timer` disabled; DrKonqi not installed).
- KWallet: not wanted at all (service disabled, no PAM unlock, no manager).
- Firewall: `firewalld` + `plasma-firewall`, no `firewall-config` GUI.
- `sudo` (not `run0`), to keep the Fedora default and maintain less.
- Services disabled: `bootc-fetch-apply-updates.timer`, `systemd-homed`, `flatpak-add-fedora-repos`, `rpm-ostree-countme.timer`, `mdmonitor`, `raid-check.timer`. Masked: `geoclue`, `avahi-daemon`.
- Quiet, minimal Plasma defaults (ADR 0016): reread, port what is still wanted. Visual check by the maintainer was pending.

## Flatpak
- Flathub only (static remote in `/usr/share/flatpak/remotes.d/`), system-wide. No Fedora Flatpak repo.
- User apps in Flatpak: Waterfox, VLC.
- **Preinstalled and embedded in the ISO**: the ISO carries the Flatpaks (Waterfox, VLC, their runtimes) and the install puts them on the system offline (Flatpak sideload, from a kickstart `%post` or a first-boot unit). The bootc image itself does not carry them (`/var` is not part of the image, and they would be re-downloaded on every update). Mechanism to verify in step 6; installed apps then update from Flathub (to verify).
- No audio server by default. Audio is a documented command (layering `pipewire wireplumber pipewire-pulseaudio plasma-pa` with `rpm-ostree`, after removing them from the blacklist for that machine). No `ujust`.

## Updates (transparent, no automatic reboot)
- System and Flatpak: Discover unattended updates, on by default, daily (ADR 0008: `PlasmaDiscoverUpdates` with `UseUnattendedUpdates=true`, plus `fedora-release-ostree-desktop` for the polkit rule). It stages the new image; it never reboots.
- A new image applies at the next reboot. User sees a notification, not a forced reboot. `bootc-fetch-apply-updates.timer` stays disabled (it reboots without asking).
- Accepted limits (inherited from Kinoite): nothing happens without an open session; no "on AC power" check; Discover shows no reboot notification once unattended updates are on. Check in step 4 whether a small reboot reminder is needed.
- Rollback: `bootc rollback` / boot menu; `bootc switch` to a previous digest. `/etc` is not carried over by a rollback (by design). Do not leave an auto-update timer that undoes a rollback.
- Fedora major version: follows the latest Fedora, never skipping one. Mechanism: see Open questions.
- Firmware: through Discover/fwupd.

## Secure Boot, disk, encryption
- Secure Boot with Fedora's chain, no MOK. CI blocks if `sbverify --list` on `vmlinuz` does not show Fedora's signature.
- Full-disk LUKS through the installer (passphrase). The initramfs must keep the `crypt` module (checked in CI).
- No GRUB password. Keymap must apply to the LUKS prompt (check AZERTY at install and at the prompt).
- Targets: Intel NUC and Framework 13 Pro; Secure Boot on in the test VM.

## ISO and installer
- ISO with the image embedded (offline, fast install), rebuilt weekly from `:stable`.
- Installer: **Anaconda WebUI** (never the old full-screen GTK interface); text mode as fallback. Titanoboa builds the ISO, pinned to a commit; bootc-image-builder only for test VM disks.
- **Accounts: Plasma Setup**, as Fedora ships it, at first boot. Anaconda handles disk and LUKS only, so there are two passwords (LUKS passphrase, account); they can be the same by choice.
- Check before step 6: the Titanoboa live kernel boots with Secure Boot on (known failure when it is signed by a third-party key; not expected with Fedora's kernel).
- Signed SHA256SUMS next to the ISO; Fedora Media Writer recommended for the USB stick.

### Hosting and download page (Cloudflare)
- The ISO file lives in **Cloudflare R2** (a Worker or Pages static asset is limited to a small file size, far below an ISO; to verify exact limits). A **Worker** serves the download page and the download link. Keep the last two ISOs. Upload from CI (multipart upload for multi-GB files).
- The download page asks for a password. **Visual only**: it keeps casual visitors out, it is not security. The ISO URL itself must not be treated as secret; nothing sensitive may ever be in the image.
- Consequence: the ISO is effectively public. Fedora trademark exposure is accepted (see Identity); the fallback there is ready if Fedora objects.
- The image on GHCR stays the update source for machines (read-only token or public, to decide).

## CI (daily, gated)
1. Build one image a day, tag `:testing`.
2. manifest-check: packages, services, repos, `VERSION_ID`, base digest vs `manifest/`; blacklist check; blocking `sbverify`.
3. Push `:testing` with cosign signature, provenance attestation and SBOM.
4. **Boot test in a VM is a promotion rule, not an option**: reach the Plasma login (`plasmalogin.service` active), `systemctl --failed` empty, `bootc status`, `crypt` in the initramfs, no blacklisted package, no unexpected service. Danathar's `boot-test.yml` with `bcvk` is the model.
5. Everything passes → `:stable` is the same digest as the tested `:testing` (retag, never rebuild).
6. A failure keeps `:stable` on the previous image and opens/updates a GitHub issue (`drift`) readable by the agent.
7. Packages or services added/removed → `:testing` is published, `:stable` waits for an automatic pull request with the diff.
8. Fedora version bump: scheduled job, pull request when `fedora-bootc:N+1` is a final release.
9. Retention of old tags; actions pinned by SHA + Dependabot.
- Logic lives in `tools/` scripts; CI YAML only calls them (Forgejo later).
- GitHub runners and KVM: Kyanite's design assumed `bcvk` runs on GitHub Actions; confirm it does in step 5 (to verify). If not, boot the test on a self-hosted runner or the NUC.

## Reuse from the Kyanite archive
- Keep (adapt): `Containerfile`, `build/packages.sh`, `whitelist.txt`/`blacklist.txt` (trimmed), `tools/rebuild-vm.sh`, `tools/vmssh`, `tests/Containerfile`, `system/usr/share/flatpak/remotes.d/flathub.flatpakrepo`, the Discover update default, systemd preset (reviewed), ADRs 0001, 0002, 0005, 0008, 0010, 0012, 0014, 0015, 0016 as references.
- Drop: Kyanite name, logo and icons, `kyanite-*` scripts and paths, and all Plasma Setup compatibility hacks (look-and-feel copies, wallpaper symlinks, `kcm-about-distrorc` rewrite, `no-launchers.js`, `kyanite-plasma-setup` tmpfiles) now that Fedora branding is kept; `ujust`, `usbguard`, the `plasma-kaccess` override, ADR 0011 (name/registry/signing). Keep them in the archive: they are the fallback if Fedora objects.
- Check: `docs/environment.md` and `docs/troubleshooting.md` (CI pitfalls) before step 5.

## Machines
- Build/test host: Intel NUC (i5-8259U, 16 GB), Fedora Kinoite. Rootless `podman build`.
- Targets: Intel NUC, Framework 13 Pro. PackardBell dropped (given away).
- Test VM: Fedora Cloud / bootc VM with OVMF Secure Boot and TPM.

## Agent rules (→ AGENTS.md, < 100 lines)
- Never run `sudo`/`run0` on the host. Use rootless paths or give me a script to run.
- Long outputs: scripts write the log to a file and print only OK or the useful error lines.
- Read the upstream docs (Fedora, bootc, KDE, systemd) for the version in use before writing; never guess a package name, unit name or key. Check it with `dnf repoquery -l` or in the image. Source and date in the ADR.
- Check the visible result before saying "fixed". Test in the VM before handing over.
- One step per session: read SPEC.md + PROGRESS.md, do the step, update PROGRESS.md, commit, stop.
- One short ADR per decision, written when decided.
- Code and docs in English.

## Steps (→ PROGRESS.md)
1. Repo set up with the free licence, `SECURITY.md` and private vulnerability reporting; import and trim the Kyanite recipe (no branding code); minimal whitelist; `podman build` passes `bootc container lint`; the VM boots on Plasma with Secure Boot.
2. Package lists: final whitelist and blacklist; decide the KDE apps and locales one by one; confirm hard dependencies in the image (`rpm -q --whatrequires`).
3. Config: telemetry off, services, firewall, KWallet off, quiet defaults.
4. Update behaviour: Discover updates Flatpak and system, staged, no password, no reboot; decide the reboot reminder.
5. CI: daily build, manifest check, boot test, `:testing` → `:stable`, issue on failure.
6. ISO: Titanoboa, Anaconda WebUI, LUKS, keymap check, Flatpaks embedded and installed offline, Plasma Setup at first boot; install from USB on the NUC and the Framework.
7. Cloudflare: R2 bucket, Worker, download page with the visual password, upload from CI.
8. Switch the real machine; rollback tested before needing it.
9. README: install, update behaviour, audio, rollback, and the frank Fedora-logo statement described under Identity.

## Open questions
- Availability of `swarf-os` (GHCR package, search engines, trademark registers). If it fails, only the ISO prefix and the image name change; the organization can be renamed.
- Fedora version policy: pinned `FEDORA_MAJOR` + automatic bump pull request (Kyanite ADR 0001), or `:latest`. Also check whether F45 is final (it was NO-GO on 2026-10-15, target 2026-10-27, fallback 2026-11-03) before choosing the start version.
- Licence: MIT or Apache-2.0.
- Reboot reminder after a staged update (Discover shows none with unattended updates on).
- GHCR image public or private with a read-only token on machines.
- Actions minutes and KVM on the chosen CI.
- `SHA256SUMS` signing identity: keyless or dedicated key.
