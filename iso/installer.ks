# Kickstart defaults for the interactive install (Anaconda reads interactive-defaults.ks).
# Installs the embedded image; the machine then follows the registry (Discover).
bootc --source-imgref=oci:@PAYLOAD_DIR@ --target-imgref=@TARGET_REF@ --stateroot=default

# Flatpaks: copy the ones installed in the live system into the new /var (offline, ADR 0021).
%post --nochroot --erroronfail --log=/tmp/swarf-flatpaks.log
set -x
# Anaconda binds the stateroot's var (physical root /ostree/deploy/default/var) onto /mnt/sysroot/var
# after the bootc deployment; the stateroot path itself is not under /mnt/sysroot.
var=/mnt/sysroot/var
test -d "$var" && mountpoint -q "$var"
mkdir -p "$var/lib"
rsync -aAXUHK --info=stats1 /var/lib/flatpak "$var/lib/"
# The build ran in a container: the copied labels are container_file_t with an MCS pair. Relabel
# from the installed policy (restorecon -n on the first VM install listed the whole tree).
# setfiles refuses a path through a symlink and /mnt is one in the live session: use the real path.
root=$(realpath /mnt/sysroot)
fc=$root/etc/selinux/targeted/contexts/files/file_contexts
test -f "$fc"
setfiles -F -r "$root" "$fc" "$root/var/lib/flatpak"
%end
