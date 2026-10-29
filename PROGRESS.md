# PROGRESS

Steps come from `SPEC.md` (section "Steps").

- [ ] 1. Repo set up with the free licence, `SECURITY.md` and private vulnerability reporting; import and trim the Kyanite recipe (no branding code); minimal whitelist; `podman build` passes `bootc container lint`; the VM boots on Plasma with Secure Boot.
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
