#!/bin/bash
# System configuration that cannot be expressed as plain files in system/.
set -euo pipefail

# /opt is read-only in the image; software installed there needs it writable.
rmdir /opt
ln -s -T var/opt /opt

# Services: apply the presets to units that are already enabled
# (presets only act when a unit is installed, and the base image is built before them).
systemctl disable \
    bootc-fetch-apply-updates.timer \
    systemd-homed.service \
    systemd-homed-activate.service \
    flatpak-add-fedora-repos.service \
    rpm-ostree-countme.timer \
    mdmonitor.service \
    raid-check.timer

# Services pulled by mandatory dependencies but unwanted: geoclue2 (required by
# xdg-desktop-portal, started on demand) and avahi (required through
# kio-extras -> kf6-kdnssd -> nss-mdns). Masked rather than force-removed.
systemctl disable avahi-daemon.service avahi-daemon.socket
systemctl mask geoclue.service avahi-daemon.service avahi-daemon.socket
