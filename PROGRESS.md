# PROGRESS

Steps come from `SPEC.md` (section "Steps").

- [x] 1. Repo set up with the free licence, `SECURITY.md` and private vulnerability reporting; import and trim the Kyanite recipe (no branding code); minimal whitelist; `podman build` passes `bootc container lint`; the VM boots on Plasma with Secure Boot.
- [x] 2. Package lists: final whitelist and blacklist; decide the KDE apps and locales one by one; confirm hard dependencies in the image (`rpm -q --whatrequires`).
- [x] 3. Config: telemetry off, services, firewall, KWallet off, quiet defaults.
- [x] 4. Update behaviour: Discover updates Flatpak and system, staged, no password, no reboot; decide the reboot reminder.
- [ ] 5. CI: daily build, manifest check, boot test, `:testing` → `:stable`, issue on failure. (in PR #6; publish path untested until the first run on `main`)
- [ ] 6. ISO: Titanoboa, Anaconda WebUI, LUKS, keymap check, Flatpaks embedded and installed offline, Plasma Setup at first boot; install from USB on the NUC and the Framework.
- [ ] 7. Cloudflare: R2 bucket, Worker, download page with the visual password, upload from CI.
- [ ] 8. Switch the real machine; rollback tested before needing it.
- [ ] 9. README: install, update behaviour, audio, rollback, and the frank Fedora-logo statement described under Identity.

## Sessions
- Session 0 : amorçage
- Session 1 : step 1 done (Fedora 44, see `docs/adr/0001-start-on-fedora-44.md`).
  - Recipe imported from the Kyanite archive, no branding code: `Containerfile`, `build/packages.sh` (no hunspell transaction), `build/configure.sh` (only `/opt`, service disable/mask), `blacklist.txt` (minus `fedora-logos`), service preset, Flathub remote, `tests/Containerfile`, `tools/rebuild-vm.sh`, `tools/vmssh`.
  - `whitelist.txt`: 43 packages, all checked with `dnf5 repoquery` in `fedora-bootc:44`. Image: 1033 packages, 4.1 GB.
  - Rootless `podman build` OK; `bootc container lint`: 12 checks passed, 1 skipped, 2 warnings (`nonempty-run-tmp`, `var-tmpfiles`: non-fatal, left for step 3).
  - VM `swarf-dev` (OVMF Secure Boot + TPM, via bcvk): `mokutil --sb-state` = enabled, `plasmalogin.service` active, `systemctl --failed` empty, screen shows Plasma Setup (Fedora look kept).
  - Not done here (later steps): `os-release` variant id, Discover update default, KDE apps/locales decision, "Fedora logos" README text. `tools/rebuild-vm.sh` needs `bcvk` in `$SWARF_WORK/bin` (default `../work`).
- Session 2 : step 2 done (see `docs/adr/0002-package-lists.md`).
  - Private vulnerability reporting is enabled on GitHub (checked by the maintainer); `PROGRESS.md` held no pending reservation about it, so nothing to remove.
  - Names checked with `dnf5 repoquery` in `fedora-bootc:44`: 43/43 whitelist names and 96/96 blacklist entries exist (including `kwalletmanager5`, `nfs-client-utils`, `nfs-common-utils`, `plasma-discover-snap`, `kde-connect`).
  - Every candidate from the archive has a decision in the ADR. Whitelist now holds the 10 KDE apps, Plasma extras, `fedora-logos`, `google-noto-emoji-fonts`, `glibc-all-langpacks` and 155 `hunspell-*` (all but `hunspell-devel`). Blacklist gains `generic-logos`, `kdeplasma-addons`, `ksshaskpass`, `pinentry-qt`, `wireguard-tools`, `alsa-sof-firmware`. Names left out for later: `docs/optional-packages.md`.
  - `qt6-qtwebengine` (291 MB) is in the image through `plasma-discover` → `qt6-qtwebview`; Discover is kept. No candidate pulls it in addition.
  - Image: 1252 packages, 5.4 GB (was 1033, 4.1 GB). `bootc container lint`: 12 passed, 1 skipped, same 2 warnings as step 1 (step 3).
  - VM `swarf-dev` rebuilt: Secure Boot enabled, `plasmalogin.service` active, `systemctl --failed` empty, screen shows Plasma Setup with the Fedora look. All ~200 whitelist names are installed (`rpm -q` reports none missing).
  - Hard dependencies confirmed in the VM (`rpm -e --test`): `geoclue2` ← `xdg-desktop-portal`; `avahi` ← `nss-mdns` ← `kf6-kdnssd`; `kf6-kwallet-libs` ← `kf6-kio-core`, `plasma-workspace-libs`, `kaccounts-integration-qt6`, `libksane`, and it pulls the `kf6-kwallet` daemon package. No `kwalletmanager5`, `pam-kwallet`, `kde-connect` or `nfs-utils` present.
  - Open for later: whether Waterfox from Flathub plays H.264 (step 6); a full rebuild plus VM takes about 30 minutes now.
- Session 3 : step 3 done (see `docs/adr/0003` to `0008`).
  - Decisions: hardening limited to core dumps off + kernel/network sysctl + random Wi-Fi MAC/GHNS off (0003); telemetry off (0004); both KWallet daemons off, packages kept (0005); quiet Plasma defaults: no splash, Overview, system bell and Zoom off (0006); firewalld zone `swarf` (dhcpv6-client + mdns, no ssh) (0007); services, `VARIANT_ID=custom`, lint cleanup (0008).
  - `bootc container lint`: 14 passed, 1 skipped, 0 warnings (the 2 old warnings are gone).
  - VM `swarf-dev` rebuilt; `tests/check-config.sh` (run with `tools/vmssh 'bash -s' < tests/check-config.sh`) prints OK: sysctl, services, firewall zone, `authselect check`, no failed unit, XDG keys read with `kreadconfig6`.
  - NOT verified: the XDG defaults (KWallet, splash, KWin effects, KUserFeedback) only act in a real logged-in Plasma session; the maintainer must check them visually after first login.
  - Deferred to step 4: Discover ODRS reviews (no setting to disable them in Discover 6.7.5, see `docs/adr/0004-telemetry-off.md`).
  - Disclosed choice: `VARIANT_ID=custom` in os-release.
- Session 4 : step 4 done (see `docs/adr/0009` to `0011`).
  - Discover unattended updates on, daily, via `/usr/share/swarf/xdg/PlasmaDiscoverUpdates` (Discover 6.7.5 defaults to off; this image has no Kinoite file). No password: polkit rule from `fedora-release-ostree-desktop` (rpm-ostree) and `pkaction` `implicit active: yes` for Flatpak app/runtime update. `bootc-fetch-apply-updates.timer` and `rpm-ostreed-automatic.timer` stay disabled (0009).
  - ODRS reviews: no setting exists, so `odrs.gnome.org` is blocked in `/etc/hosts` (`system/etc/hosts`, 0010). Discover shows no ratings.
  - Reboot reminder: none, maintainer decision (0011). Discover's notifier shows no reboot notice when unattended updates are on.
  - VM `swarf-dev` rebuilt; `tests/check-config.sh` prints OK, including the new checks (keys, timers, polkit rule, hosts block). `bootc container lint`: 14 passed, 1 skipped, 0 warnings.
  - NOT verified: a real unattended run (needs a newer image in a registry and a logged-in session; steps 5 and 8), what the panel icon shows once an update is staged, and that Discover copes quietly with the blocked ODRS host. The visual check of the step 3 XDG settings remains the maintainer's.
  - Checked afterwards in the VM: `getent ahostsv6 odrs.gnome.org` returns `::ffff:0.0.0.0`, so IPv6 lookups are blocked too (no extra hosts line needed).
  - `tests/check-config.sh` sets `XDG_CONFIG_DIRS` itself: its OK proves the file is readable, not that the real session picks it up. For the maintainer, after login: System Settings → Software Update should show automatic updates, daily. Not marked done.
  - Maintainer's visual check of the VM (2026-10-29): Software Update page OK, Overview off OK, KWallet not opening OK, system bell off OK, Orca absent OK. Two defects found and fixed: the splash screen still showed (`~/.config/kdedefaults/ksplashrc` shadowed our default; keys now immutable, ADR 0006 correction) and the task manager was icons-only (now icons and text, ADR 0012, also changes `build/configure.sh`).
  - Both fixes were tested live in the VM (`bootc usroverlay`, no rebuild): `tests/check-config.sh` OK, panel screenshot shows titles, Discover opens a Flathub app page without error with ODRS blocked ("0 note"). NOT yet rebuilt from the Containerfile: the next full build must pass `configure.sh` (its greps fail the build if the layout template changed) and `bootc container lint`. Splash absence still to be seen on a fresh login.
  - Flatpak apps (Waterfox, VLC) are absent from the VM by design: they come from the ISO in step 6. The unattended update error in the VM is expected: the VM image `localhost/swarf-os:test` has no registry.
  - Moved to step 5 (maintainer decision): (1) first full build from the Containerfile with the step 4 changes (`configure.sh` layout greps, `bootc container lint`); (2) splash screen absent and task manager with titles on a fresh login in a VM built from that image; (3) a real unattended update, once `:testing` sits on GHCR and a VM boots an older image from it. Step 4 is closed apart from these.
- Session 5 : step 5 written and PR-tested, not closed until the first run on `main` (see `docs/adr/0013` to `0018`, PR #6); several parts are untested, listed below.
  - Decisions: public GHCR image (0013); base `fedora-bootc:latest` resolved to a digest, any manifest change including `VERSION_ID` holds `:stable` and opens a PR (0014; `latest` was 44 on 2026-10-29, tag 45 exists in beta); manifest gate = packages, units, repos, VERSION_ID, no versions or digests (0015); promotion by retag, drift PR on the fixed branch `manifest-drift`, dated tags, retention (0016); `drift` issue (0017); GitHub `ubuntu-26.04` runner (0018).
  - Files: `.github/workflows/{build,promote}.yml`, `.github/dependabot.yml`, `tools/{ci-build,ci-runner-setup,manifest,manifest-check,boot-test,publish,promote,prune,drift-pr,drift-issue}.sh`, `tests/boot-checks.sh`, `manifest/` (generated from the local image with `tools/manifest.sh`, 1252 packages). Actions are pinned by commit SHA (resolved with `gh api`), bcvk by sha256.
  - Seen working: full local build from the Containerfile (item 1 of the carried-over list): `configure.sh` greps pass, `bootc container lint` 14 passed, 1 skipped, no warning (that build still had the old `FROM` line, the `BASE` change came after; the CI build uses the new one and passed). `tools/manifest-check.sh` OK locally, and rc 10 with a changed `version.txt`. `sbverify --list vmlinuz` shows `Fedora Secure Boot Signer`; `lsinitrd -m` lists `crypt`. `tools/boot-test.sh` OK locally (bcvk 0.21) and on the runner (PR #6, run 40981254330: build, checks, boot test green).
  - NOT tested (needs `main`): GHCR login and push, cosign, provenance and SBOM attestations, `promote.sh`, `drift-pr.sh`, `drift-issue.sh`, `prune.sh` (try `tools/prune.sh --dry-run` first), `promote.yml`, the `schedule` trigger. The first run on `main` is the test.
  - Maintainer actions after merge: set the GHCR package `swarf-os/image` to public (ADR 0013); "Allow GitHub Actions to create and approve pull requests" is already on (checked 2026-10-29); watch for the 60-day schedule rule: mitigated by a `gh workflow enable` step whose effect GitHub does not document (0017). The boot test checks run in an ephemeral VM without firmware Secure Boot: the kernel signature is a static check.
  - Carried over from step 4, NOT done: (2) splash absent and task manager with titles on a fresh login: the VM `swarf-dev` was rebuilt from this image (ready), but the fresh Plasma Setup login is the maintainer's. (3) real unattended update: needs `:testing` and an older dated tag on GHCR after the first run on `main`. Recipe: boot the older dated tag (`bcvk to-disk` of that tag, then `bootc switch ghcr.io/swarf-os/image:testing` or set the image reference so Discover looks at `:testing`), log in, wait idle past the 1 minute and 3 h conditions, then check Software Update and the panel icon once an update is staged.
  - Still open from step 3: the maintainer's visual check of the XDG settings (Overview, KWallet, bell, Orca seen OK; splash to revisit). Not closed here.
