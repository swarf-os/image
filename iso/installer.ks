# Kickstart defaults for the interactive install (Anaconda reads interactive-defaults.ks).
# Installs the embedded image; the machine then follows the registry (Discover).
# No Flatpak %post: the ISO carries no Flatpak, apps are installed on demand (docs/adr/0027).
bootc --source-imgref=oci:@PAYLOAD_DIR@ --target-imgref=@TARGET_REF@ --stateroot=default

# LUKS prompt keymap (docs/adr/0037): on ostree installs Anaconda 44.30 adds
# vconsole.keymap=<installer keymap> (ConfigureBootloader._set_kargs); on bootc installs it does
# not, and our generic initramfs has no vconsole.conf, so the prompt stays US. Do the same here.
# No --erroronfail: if this fails the prompt stays US (the old behaviour), the install goes on.
%post --log=/var/log/swarf-keymap.log
set -x
cat /etc/vconsole.conf
grep -h '^options' /boot/loader/entries/*.conf
km=$(sed -n 's/^KEYMAP="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /etc/vconsole.conf)
if [ -n "$km" ] && [ "$km" != us ]; then
  ostree admin instutil set-kargs --merge "vconsole.keymap=$km"
  grep -h '^options' /boot/loader/entries/*.conf
fi
%end
