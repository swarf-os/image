#!/bin/bash
# Runs inside the live image build (iso/Containerfile). Everything here exists only in the ISO's
# live system, never in the installed machine (which gets the unmodified payload image).
set -euxo pipefail
S=/tmp/swarf-iso

# /root is a link to a directory that does not exist in the image; dnf and flatpak want it.
mkdir -p "$(realpath /root)"
# bwrap writes /proc/sys/user/max_user_namespaces, which is read-only in a build container.
mount -o remount,rw /proc/sys

# Installer, live session, initramfs and bootloader pieces (names checked with dnf5 repoquery
# in fedora-bootc:44, 2026-10-30). slitherer is the WebUI browser engine of the fedora profile.
dnf -y --setopt=install_weak_deps=False install \
    anaconda-live anaconda-webui anaconda-install-env-deps slitherer \
    dracut-live livesys-scripts grub2-efi-x64-cdboot \
    libblockdev-crypto libblockdev-btrfs libblockdev-lvm libblockdev-dm \
    rsync
mkdir -p /var/lib/rpm-state    # the WebUI wants it

# Flatpaks, installed system-wide in the live system; the kickstart copies them to the disk.
flatpak remote-add --system --if-not-exists flathub /usr/share/flatpak/remotes.d/flathub.flatpakrepo
grep -v '^#' "$S/flatpaks" | xargs flatpak install --system -y --noninteractive flathub
flatpak list --system --columns=application,origin,size

# Live initramfs (dmsquash-live), same kernel, Fedora's signature untouched.
kernel=$(ls /usr/lib/modules)
[ "$(echo "$kernel" | wc -w)" = 1 ]
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/$kernel/initramfs.img" "$kernel"

# Live session: autologin as liveuser into Plasma (livesys-kde handles plasmalogin).
sed -i 's/^livesys_session=.*/livesys_session=kde/' /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

# Anaconda: profile and defaults.
cp "$S/swarf-os.conf" /etc/anaconda/profile.d/swarf-os.conf
sed -e 's|@PAYLOAD_DIR@|/usr/lib/swarf-iso/payload|' -e 's|@TARGET_REF@|ghcr.io/swarf-os/image:stable|' \
    "$S/installer.ks" >>/usr/share/anaconda/interactive-defaults.ks

# Titanoboa expects shim and grub under /boot/efi, and the cdboot grub as gcdx64.efi.
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/
cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi

# / is an overlay on /run in the live system; ostree needs room in /var/tmp (Titanoboa examples).
rm -rf /var/tmp
mkdir -p /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'UNIT'
[Unit]
Description=Larger tmpfs for /var/tmp on the live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%%,nr_inodes=1m

[Install]
WantedBy=local-fs.target
UNIT
systemctl enable var-tmp.mount

# bootupd has no /boot or /sysroot block device to update in the live session, so the unit failed
# at every boot of the ISO. The installed system keeps it.
systemctl mask bootloader-update.service

# Boot menu: ISO_LABEL is also the volume label, root=live:CDLABEL must match it exactly.
mkdir -p /usr/lib/bootc-image-builder
cat >/usr/lib/bootc-image-builder/iso.yaml <<YAML
label: "$ISO_LABEL"
grub2:
  timeout: 10
  entries:
    - name: "swarf-os live installer"
      linux: "/images/pxeboot/vmlinuz quiet root=live:CDLABEL=$ISO_LABEL enforcing=0 rd.live.image"
      initrd: "/images/pxeboot/initrd.img"
    - name: "swarf-os live installer (basic graphics)"
      linux: "/images/pxeboot/vmlinuz quiet root=live:CDLABEL=$ISO_LABEL enforcing=0 rd.live.image nomodeset"
      initrd: "/images/pxeboot/initrd.img"
YAML

dnf clean all
