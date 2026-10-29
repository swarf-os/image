#!/bin/bash
# Rebuild the swarf-os image, the SSH test image (tests/) and the session VM
# "swarf-dev" (qemu:///session, Secure Boot, TPM), without root.
# Work files (dnf cache, bcvk, VM disk, SSH key) live in $SWARF_WORK
# (default: ../work next to the repository).
set -euo pipefail
R=$(cd "$(dirname "$0")/.." && pwd)
W=${SWARF_WORK:-$(cd "$R/.." && pwd)/work}
mkdir -p "$W/dnf-cache" "$W/vm"
key=$W/vm/id_swarf_test
[ -f "$key" ] || ssh-keygen -q -t ed25519 -N '' -C swarf-test -f "$key"
cache=(-v "$W/dnf-cache:/var/cache/libdnf5:Z")
podman build --ulimit core=0 "${cache[@]}" -t localhost/swarf-os:dev "$R" >"$W/build-dev.log" 2>&1
podman build --ulimit core=0 "${cache[@]}" -t localhost/swarf-os:test "$R/tests" >"$W/build-test.log" 2>&1
grep -E "^Checks|^Warnings" "$W/build-dev.log" || true
virsh -c qemu:///session destroy swarf-dev >/dev/null 2>&1 || true
virsh -c qemu:///session undefine swarf-dev --nvram --tpm >/dev/null 2>&1 || true
rm -f "$W/vm/swarf-dev.qcow2"
"$W/bin/bcvk" to-disk --format qcow2 --filesystem btrfs --disk-size 30G --memory 4096 --vcpus 4 \
    localhost/swarf-os:test "$W/vm/swarf-dev.qcow2" >"$W/vm/bcvk-to-disk.log" 2>&1
virt-install --connect qemu:///session --name swarf-dev --memory 4096 --vcpus 4 --osinfo fedora-unknown --import \
    --disk path="$W/vm/swarf-dev.qcow2",bus=virtio \
    --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes,firmware.feature1.name=enrolled-keys,firmware.feature1.enabled=yes \
    --tpm emulator,model=tpm-crb,version=2.0 \
    --network type=user,backend.type=passt,portForward0.proto=tcp,portForward0.range0.start=2222,portForward0.range0.to=22 \
    --sysinfo type=smbios,oemStrings.entry0="io.systemd.credential:ssh.authorized_keys.root=$(cat "$key.pub")" \
    --video virtio --graphics spice --noautoconsole >/dev/null
echo "VM swarf-dev ready (tools/vmssh 'command')"
