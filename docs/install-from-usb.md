# Installing from a USB stick (NUC and Framework)

Status: the installer was seen working only in a VM (3 installs, the tested ISO was built locally from the `localhost/swarf-os:dev` image). Nothing here was run on real hardware yet. For the stick, prefer an ISO built by CI from `main`.

## Before

- **First promote `:stable` (merge the "Manifest drift" PR).** The installed system follows `ghcr.io/swarf-os/image:stable`; until that tag has Plymouth, the fonts and `rhgb`, the first update would remove them.
- Download the ISO and `SHA256SUMS` from the `iso` workflow run (artifact `swarf-os-iso`) or, once published, from the download page. Check it: `sha256sum -c SHA256SUMS`. The signature check (cosign) only exists for ISOs built on `main` and was not tested.
- Write the stick with Fedora Media Writer (SPEC.md). Everything on the stick is erased.
- Secure Boot can stay on (the ISO boots with shim in the VM with Secure Boot).

## Installer choices

- Keep English and the US keyboard (the defaults). The LUKS prompt at boot always uses the US keymap, whatever you pick here (ADR 0022).
- Choose a LUKS passphrase you can type on a US layout.
- Time zone and language are asked again by Plasma Setup on first boot; the installer does not guess them from the network (ADR 0026).

## NUC: only the SATA SSD

The NUC has two disks. Install **only on the Samsung MZ7LN128 (about 128 GB; it was `sdb`, but letters can change when booting from USB: go by model and size)**. **Never on the M.2 disk: it holds Kinoite**, the machine in use.

- In the installer's storage step, tick only that disk and untick the other one. Check the model name and size on screen before clicking Install.
- The boot menu (the boot-menu key shown at power-on) may show a "Fedora" entry from Kinoite. The new system will also be called "Fedora" in the firmware list: after install, check which disk each entry points to before choosing a default.

## Framework

- Boot the stick from the one-time boot menu (the key shown at power-on).
- Single disk: erase it only if nothing on it is needed.

## If the install fails

Do not reboot. Switch to a console (Ctrl+Alt+F3, user `liveuser`, empty password) and read `/tmp/swarf-flatpaks.log` and the other `/tmp/*.log` files, then report them (an earlier VM failure of the `%post` step was never explained).
