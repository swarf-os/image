# PROGRESS

Steps come from `SPEC.md` (section "Steps").

- [x] 1. Repo set up with the free licence, `SECURITY.md` and private vulnerability reporting; import and trim the Kyanite recipe (no branding code); minimal whitelist; `podman build` passes `bootc container lint`; the VM boots on Plasma with Secure Boot.
- [x] 2. Package lists: final whitelist and blacklist; decide the KDE apps and locales one by one; confirm hard dependencies in the image (`rpm -q --whatrequires`).
- [x] 3. Config: telemetry off, services, firewall, KWallet off, quiet defaults.
- [ ] 4. Update behaviour: Discover updates Flatpak and system, staged, no password, no reboot; decide the reboot reminder.
- [ ] 5. CI: daily build, manifest check, boot test, `:testing` → `:stable`, issue on failure.
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
