# 0003 — Hardening kept from Kyanite level 1 (step 3)

Date: 2026-10-29. Status: accepted.

## Context
SPEC: "No hardening beyond what is free to keep. Level 1 hardening (Kyanite ADR 0006):
reread, decide if any of it stays." Every key below was checked to exist on the host
kernel (7.2.11, same family as the image) and re-read in the VM after the build.

## Decisions (maintainer, 2026-10-29)
- **Kept: kernel and network sysctl**, in `/usr/lib/sysctl.d/60-swarf-hardening.conf`.
  The `60-` prefix sorts after Fedora's `10-default-yama-scope.conf` (`ptrace_scope=0`)
  and `50-coredump.conf` (`core_pattern`, `suid_dumpable=2`), so ours win.
  Rejected by Kyanite and still rejected: `io_uring_disabled`, `arp_*`, `binfmt_misc`,
  `tcp_timestamps`.
- **Omitted on purpose: `kernel.oops_limit` and `kernel.warn_limit`** (Kyanite: 100). Past
  the limit the kernel panics; a noisy driver on the Framework could reboot the machine.
  Maintainer agreed to leave them out.
- **Kept: core dumps off.** `kernel.core_pattern=|/bin/false`, `fs.suid_dumpable=0`.
  `systemd-coredump.socket` is static, so `build/configure.sh` masks it (a preset cannot
  turn it off). DrKonqi is not installed.
- **Kept: random Wi-Fi MAC per network, nothing to write.** Fedora's NetworkManager already
  ships `/usr/lib/NetworkManager/conf.d/22-wifi-mac-addr.conf` with
  `wifi.cloned-mac-address=stable-ssid` (a generated MAC, stable for each SSID). A fully
  random MAC on every connection would break DHCP leases and captive-portal sessions.
- **Kept: KDE "Get New Stuff" off.** `kdeglobals` `[KDE Action Restrictions] ghns=false` in
  `/usr/share/swarf/xdg/`. Checked: `KAuthorized::GHNS` lower-cased is `ghns`
  (kconfig 6.31 `kauthorized.cpp`), and KNewStuff widgets/QtQuick call it.
- **Not kept (reported, not step 3):** chrony NTS, faillock/pwquality, signature
  `policy.json`, kernel module blacklist and kernel arguments, level 2 and 3.

## Consequences
- `ptrace_scope=1` blocks `gdb -p` and `strace -p` on unrelated processes (use sudo or run
  the program under the tool).
- Firewall: see 0007.
