# 0028 — Intel Wi-Fi firmware and UPower in the image (step 6b)

Date: 2026-11-02. Status: accepted; on the hardware NOT seen yet.

## Context
On the Packard Bell laptop (first real install, 2026-11-02, live session): no Wi-Fi, the kernel
asked for `iwlwifi-so-a0-hr-b0-89.ucode` (Intel Wi-Fi 6 AX101, PCI 54f0/0244, "no suitable
firmware found"); no battery in the panel although `/sys/class/power_supply` had `BAT0` and
`ADP1`. The image had no `iwlwifi-*` file and only `upower-libs`: with `install_weak_deps=False`
nothing pulls `upower`, and `linux-firmware` does not even recommend the Intel Wi-Fi packages
(its Recommends: amd, atheros, brcmfmac, cirrus, intel-audio, intel-gpu, mt7xxx, nvidia,
nxpwireless, qcom-wwan, realtek, tiwilink).

## Decision
- `iwlwifi-mvm-firmware`: `dnf provides` in `fedora-bootc:44` (2026-11-02) gives it as the only
  provider of `/usr/lib/firmware/iwlwifi-so-a0-hr-b0-89.ucode.xz`. It requires
  `iwlwifi-mld-firmware` (newer Intel cards, Wi-Fi 7) and `iwlbluetooth-firmware` (firmware files
  only; there is still no Bluetooth stack). About 105 MB installed in total.
- `upower` (0.3 MB): the daemon behind Powerdevil's battery. D-Bus activated, nothing to enable.
- `pciutils` (`lspci`): not added (maintainer, 2026-11-02); the diagnostic reads
  `/sys/class/net/*/device/uevent`.

## Consequences
The Wi-Fi chips of the NUC and the Framework 13 Pro are not checked against these packages; if
one is not Intel, its firmware may still be missing. Battery and Wi-Fi are seen only on the
hardware, never in the VM.
