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

# Core dumps are off (sysctl kernel.core_pattern, docs/adr/0003). The socket is static,
# so a preset cannot turn it off.
systemctl mask systemd-coredump.socket

# Firewall: closed default zone shipped in system/ (docs/adr/0007).
firewall-offline-cmd --set-default-zone=swarf

# os-release: stay ID=fedora, mark the image as custom (docs/adr/0008).
# Owned by fedora-release-identity-basic; replace the line if it exists.
if grep -q '^VARIANT_ID=' /usr/lib/os-release; then
    sed -i 's/^VARIANT_ID=.*/VARIANT_ID=custom/' /usr/lib/os-release
else
    echo 'VARIANT_ID=custom' >>/usr/lib/os-release
fi

# Task manager with icons and text (docs/adr/0012): the default panel layout uses the
# icons-only widget. Fail the build if Plasma changes the template.
layout=/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js
grep -q 'addWidget("org.kde.plasma.icontasks")' "$layout"
sed -i 's/"org\.kde\.plasma\.icontasks"/"org.kde.plasma.taskmanager"/' "$layout"
grep -q 'addWidget("org.kde.plasma.taskmanager")' "$layout"
# No pinned launchers (maintainer request, docs/adr/0012): write an empty list over the widget default.
sed -i 's/^panel\.addWidget("org\.kde\.plasma\.taskmanager")$/var taskManager = &\ntaskManager.currentConfigGroup = ["General"]\ntaskManager.writeConfig("launchers", "")/' "$layout"
grep -q 'writeConfig("launchers", "")' "$layout"
