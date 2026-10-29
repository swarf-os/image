# 0007 — Firewall: closed `swarf` zone (step 3)

Date: 2026-10-29. Status: accepted.

## Context
`firewalld` and `plasma-firewall` (+ `-firewalld`) are in the whitelist; `firewall-config` is
blacklisted. `firewalld.service` is enabled by Fedora's preset. Fedora's default zone `public`
(checked in the image) opens `ssh`, `mdns` and `dhcpv6-client`. The production image has no
`sshd`.

## Decision (maintainer, 2026-10-29)
A zone `swarf` shipped in `/usr/lib/firewalld/zones/swarf.xml`, set as default at build time
(`firewall-offline-cmd --set-default-zone=swarf` in `configure.sh`). It opens only
`dhcpv6-client` (udp 546, DHCPv6 networks) and `mdns` (udp 5353, `.local` names resolved by
`systemd-resolved`). No `ssh`. `tests/Containerfile` adds `ssh` to the zone for the test
VM, so the published image never has port 22 open.

## Consequences
- Dropping `mdns` would only break multicast `.local` resolution; dropping `dhcpv6-client`
  only affects networks that hand out addresses by DHCPv6. Both are kept deliberately.
- The `public` zone's `<forward/>` is not copied: the image runs no containers by default.
