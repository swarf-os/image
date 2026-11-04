# Kickstart defaults for the interactive install (Anaconda reads interactive-defaults.ks).
# Installs the embedded image; the machine then follows the registry (Discover).
# No Flatpak %post: the ISO carries no Flatpak, apps are installed on demand (docs/adr/0027).
bootc --source-imgref=oci:@PAYLOAD_DIR@ --target-imgref=@TARGET_REF@ --stateroot=default

# LUKS prompt keymap (docs/adr/0037): on ostree installs Anaconda 44.30 adds
# vconsole.keymap=<installer keymap> (ConfigureBootloader._set_kargs); on bootc installs it does
# not, and our generic initramfs has no vconsole.conf, so the prompt stays US. Do the same here.
# --nochroot: in a chrooted %post ostree admin fails with "No such file or directory" (seen in
# the VM, 2026-11-04): the bootc flow does not bind the physical root on the deployment's
# /sysroot. So ostree runs from the live system (built from the same image) on the physical
# root. Deployment = /mnt/sysroot, physical root = /mnt/sysimage (anaconda.conf).
# No --erroronfail: if this fails the prompt stays US, the install goes on.
%post --nochroot --log=/mnt/sysroot/var/log/swarf-keymap.log
set -x
cat /mnt/sysroot/etc/vconsole.conf
km=$(sed -n 's/^KEYMAP="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /mnt/sysroot/etc/vconsole.conf)
if [ -n "$km" ] && [ "$km" != us ]; then
  ostree admin instutil set-kargs --sysroot=/mnt/sysimage --merge "vconsole.keymap=$km"
fi
grep -h '^options' /mnt/sysimage/boot/loader/entries/*.conf
%end
