# Kickstart defaults for the interactive install (Anaconda reads interactive-defaults.ks).
# Installs the embedded image; the machine then follows the registry (Discover).
# No Flatpak %post: the ISO carries no Flatpak, apps are installed on demand (docs/adr/0027).
bootc --source-imgref=oci:@PAYLOAD_DIR@ --target-imgref=@TARGET_REF@ --stateroot=default

# LUKS prompt keymap (docs/adr/0037): on ostree installs Anaconda 44.30 adds
# vconsole.keymap=<installer keymap> (ConfigureBootloader._set_kargs); on bootc installs it does
# not, and our generic initramfs has no vconsole.conf, so the prompt stays US. Do the same here.
# --nochroot: the bootc flow does not bind the physical root on the deployment's /sysroot
# (the ostree flow does, installation.py PrepareOSTreeMountTargetsTask), so ostree admin in a
# plain %post finds no sysroot. Deployment = /mnt/sysroot, physical root = /mnt/sysimage
# (anaconda.conf). No --erroronfail: if this fails the prompt stays US, the install goes on.
%post --nochroot --log=/mnt/sysroot/var/log/swarf-keymap.log
set -x
findmnt -R /mnt/sysimage
cat /mnt/sysroot/etc/vconsole.conf
km=$(sed -n 's/^KEYMAP="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /mnt/sysroot/etc/vconsole.conf)
if [ -n "$km" ] && [ "$km" != us ]; then
  # rslave: the live system's mounts are shared; without it the umount -R below would also
  # unmount /mnt/sysimage/boot under Anaconda (core/path.py set_system_root does make-rprivate).
  mount --rbind /mnt/sysimage /mnt/sysroot/sysroot && mount --make-rslave /mnt/sysroot/sysroot &&
    chroot /mnt/sysroot ostree admin instutil set-kargs --merge "vconsole.keymap=$km"
  umount -R /mnt/sysroot/sysroot
fi
grep -h '^options' /mnt/sysimage/boot/loader/entries/*.conf
%end
