# PROGRESS

Steps come from `SPEC.md` (section "Steps").

- [x] 1. Repo set up with the free licence, `SECURITY.md` and private vulnerability reporting; import and trim the Kyanite recipe (no branding code); minimal whitelist; `podman build` passes `bootc container lint`; the VM boots on Plasma with Secure Boot.
- [ ] 2. Package lists: final whitelist and blacklist; decide the KDE apps and locales one by one; confirm hard dependencies in the image (`rpm -q --whatrequires`).
- [ ] 3. Config: telemetry off, services, firewall, KWallet off, quiet defaults.
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
