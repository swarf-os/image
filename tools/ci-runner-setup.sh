#!/bin/bash
# Prepare a GitHub ubuntu-26.04 runner for the build and the boot test (not for local use).
#  - free the system disk and keep container storage on /mnt (the image is ~5.4 GB and the
#    build needs several times that),
#  - open /dev/kvm to the runner user (udev rule from Kyanite docs/troubleshooting.md),
#  - install sbverify, virtiofsd and qemu (bcvk runs the VM with the host's), and bcvk (pinned by sha256).
# Prints the KVM and disk state so that the log shows why a boot test cannot start.
set -euo pipefail
BCVK_VERSION=0.22.0
BCVK_SHA256=eb72198c0d36fab75bfcadbb6794a87afa6f496a4da6b1b34d27728243fa6474

sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL
sudo mkdir -p /mnt/containers
sudo chown "$USER" /mnt/containers
mkdir -p ~/.config/containers
printf '[storage]\ndriver = "overlay"\ngraphroot = "/mnt/containers"\n' >~/.config/containers/storage.conf

echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666", OPTIONS+="static_node=kvm"' |
    sudo tee /etc/udev/rules.d/99-kvm4all.rules >/dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger --name-match=kvm
ls -l /dev/kvm || { echo "ERROR: no /dev/kvm on this runner" >&2; exit 1; }

sudo apt-get update -qq
sudo apt-get install -y -qq sbsigntool virtiofsd qemu-system-x86

mkdir -p ~/bin
curl -fsSL -o /tmp/bcvk.tar.gz \
    "https://github.com/bootc-dev/bcvk/releases/download/v$BCVK_VERSION/bcvk-x86_64-unknown-linux-gnu.tar.gz"
echo "$BCVK_SHA256  /tmp/bcvk.tar.gz" | sha256sum -c -
tar -xzf /tmp/bcvk.tar.gz -C ~/bin
mv ~/bin/bcvk-x86_64-unknown-linux-gnu ~/bin/bcvk
chmod +x ~/bin/bcvk
echo "$HOME/bin" >>"$GITHUB_PATH"
podman --version
df -h / /mnt
