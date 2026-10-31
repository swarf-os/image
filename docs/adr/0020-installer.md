# 0020 — Anaconda installs the image with a bootc kickstart, on a single btrfs root (step 6)

Date: 2026-10-30. Status: accepted (seen in the VM, not yet on the NUC or the Framework).

## Context
The ISO is a live session with the Anaconda WebUI. Anaconda 44's `bootc` kickstart command
installs a container image and needs no network when the source is local.

## Decision
- `iso/installer.ks`: `bootc --source-imgref=oci:<dir> --target-imgref=ghcr.io/swarf-os/image:stable
  --stateroot=default`. The source is an OCI directory of the same digest the ISO was built from,
  so the installed system then follows `:stable` (Discover, `bootc upgrade`).
- Anaconda profile `swarf-os` (`iso/swarf-os.conf`, based on `fedora-kde`): the account pages are
  hidden (Plasma Setup creates the user) and the storage is one btrfs root, no separate `/var` or
  `/home`. ostree already keeps `/var` and `/home` (`/var/home`) inside it.

## Why no separate /var or /home
Anaconda's bootc payload empties the physical root (`DeployBootcTask._clean_physroot`) and binds
the stateroot's `var` onto `/mnt/sysroot/var` itself. With a separate `/var` the installer failed
("mount --bind /mnt/sysimage/var ... does not exist"). Anaconda 44 also has no multi-disk or
arbitrary mount points for bootc.

## Consequences
The user's data and the system share one filesystem and one LUKS volume. A separate `/home` is
possible only after Anaconda learns it.
