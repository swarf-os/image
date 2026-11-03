# 0035 — Audio is six layered packages, and layering changes how to stay back (step 9)

Date: 2026-11-05. Status: accepted (maintainer chose the 6-package set, 2026-11-05).

## Decision
- The image stays without an audio server (SPEC). The README gives one command for a machine
  that wants sound:
  `rpm-ostree install pipewire wireplumber pipewire-pulseaudio pipewire-alsa plasma-pa alsa-sof-firmware`.
  Six names: the SPEC's four, plus `pipewire-alsa` (ALSA applications; it is in the blacklist's
  audio group) and `alsa-sof-firmware` (Sound Open Firmware, likely needed by recent Intel
  laptops such as the Framework 13; `docs/optional-packages.md`), 10 MiB more, one command.
- The SPEC's "after removing them from the blacklist for that machine" is dropped: the blacklist
  is a build-time check only; on a machine nothing needs to change.
- Machines with that layer stay on an older image with
  `rpm-ostree rebase ostree-unverified-registry:ghcr.io/swarf-os/image@sha256:…` (transport from
  `rpm-ostree(1)`, "rebase"), not with `bootc switch` or `tools/switch.sh pin-to`.

## Checked (2026-11-05)
- `dnf5 repoquery` in `localhost/swarf-os:dev`: the six exist (`pipewire` 1.6.11 updates,
  `wireplumber` 0.5.19, `plasma-pa` 6.8.2, `alsa-sof-firmware` 2025.12.2 fedora); the image
  has `fedora`, `updates`, `updates-archive`, `fedora-cisco-openh264` enabled.
- VM `swarf-dev` (`localhost/swarf-os:test`, Secure Boot): `rpm-ostree install --dry-run` resolves
  16 packages; the real install and reboot give `LayeredPackages` with the six, `pipewire.socket`,
  `pipewire-pulse.socket`, `wireplumber.service` enabled globally (user units).
- Same VM, layered: `bootc upgrade --check` fails "Deployment contains local rpm-ostree
  modifications; cannot upgrade via bootc" (as `bootc-relationships(7)` says). `bootc rollback`
  works (swaps to the unlayered deployment). **`bootc switch ghcr.io/swarf-os/image@sha256:faa5f33d…`
  does not refuse**: it staged a deployment with "17 removed" and no `LayeredPackages`.
  `rpm-ostree rebase ostree-unverified-registry:ghcr.io/swarf-os/image@sha256:faa5f33d…`
  staged one with the six layered. That boot was not observed over ssh: the real `:stable`
  has no sshd. Also seen: a second `bootc rollback` without a reboot in between printed
  "Next boot: rollback deployment" but did not swap back; `rpm-ostree rollback` did.
- Sources: `bootc-relationships(7)` (bootc 1.17.1, "Client side changes"), `rpm-ostree(1)`
  (2026.3, "install", "rebase"), both read on the host 2026-11-05.

## Consequences
- A machine with audio runs packages CI never tested, resolved again from Fedora's
  repositories on every Discover update (rpm-ostree keeps the layer). A Fedora major upgrade
  may fail on the layer: remove it first.
- `tools/switch.sh switch` and `pin-to` already refuse a layered system (good, since bare
  `bootc switch` would silently drop the layer); the script's message says "bootc refuses",
  which is not exactly what happens. Not changed here (docs-only step).
- Not seen: sound itself (no session in the VM, no hardware test); a boot of the rebased
  deployment.

## Fixtures (VM `swarf-dev`)
`/etc/systemd/system/boot.automount` → `/dev/null` (bcvk `/boot` layout, PROGRESS Session 8);
the audio layer; the VM was left booted on the staged ghcr `:stable` deployment (no sshd) and
shut down. Rebuild it before the next VM test: `tools/rebuild-vm.sh` runs two `podman build` (30 GB free
needed, 26 GB on 2026-11-05), or run only its `bcvk to-disk` and `virt-install` lines from the
existing `localhost/swarf-os:test`.
