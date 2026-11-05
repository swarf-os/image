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
rpm -q anaconda-core ostree
cat /mnt/sysroot/etc/vconsole.conf
grep -h '^options' /mnt/sysimage/boot/loader/entries/*.conf
km=$(sed -n 's/^KEYMAP="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /mnt/sysroot/etc/vconsole.conf)
if [ -n "$km" ] && [ "$km" != us ]; then
  # /boot is read-only here ("mkdir(boot/loader.0): Read-only file system", seen in the VM):
  # writable only for this command, then back to the state findmnt reads now.
  boot=$(findmnt -no OPTIONS /mnt/sysimage/boot)
  echo "/boot at %post: ${boot:-not a separate mount}"
  [ -n "$boot" ] && mount -o remount,rw /mnt/sysimage/boot
  # --replace, not a plain argument: a plain argument is appended even when the key is already
  # there (ostree ot-admin-instutil-builtin-set-kargs.c), --replace keeps a single vconsole.keymap.
  ostree admin instutil set-kargs --sysroot=/mnt/sysimage --merge "--replace=vconsole.keymap=$km"
  case ",$boot," in *,ro,*) mount -o remount,ro /mnt/sysimage/boot ;; esac
  findmnt -no OPTIONS /mnt/sysimage/boot
fi
grep -h '^options' /mnt/sysimage/boot/loader/entries/*.conf
%end
