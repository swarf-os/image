# Switch an installed Kinoite to swarf-os, and roll back

For a machine that already runs Fedora Kinoite (ADR 0033, 0034). The account, `/home` and the
Flatpak apps stay. Everything is done with `tools/switch.sh`, as root, on the machine itself.
Nothing reboots on its own: you reboot.

## Get the script
```sh
git clone https://github.com/swarf-os/image
cd image
```
Logs go to `../work/` (next to the clone); the terminal only shows the useful lines and `OK`.

## 1. Look first
```sh
sudo tools/switch.sh inventory
```
It must say `layered packages: none`: the script refuses a system with rpm-ostree layered
packages, because `bootc switch` drops them without a word (seen in a VM, ADR 0035; `bootc
upgrade` refuses them). Remove them first. It also says whether Plasma Setup was completed.
A swarf-os machine with audio layered stays on an older image with `rpm-ostree rebase` instead
(README, "Rollback").

## 2. Switch
```sh
sudo tools/switch.sh switch      # pins Kinoite (first time only), stages ghcr.io/swarf-os/image:stable
systemctl reboot
sudo tools/switch.sh status      # booted = ghcr.io/swarf-os/image:stable, "digest check: MATCH"
```
`MATCH` means the booted image is the one `:stable` points to. `DIFFERENT` later on is normal when
a newer image was promoted since (`:stable` moves at most daily).

**After every reboot, run `status`.** If the booted line did not change, the new deployment
failed to install at shutdown and the old one booted: `journalctl -b -1 -u ostree-finalize-staged`.

## 3. Roll back, and return
```sh
sudo tools/switch.sh rollback    # next boot = the previous deployment ([1] in status)
systemctl reboot
sudo tools/switch.sh status
```
Run it again to come back. Other ways:
- **Boot menu, one boot only.** The menu shows every deployment. `(ostree:0)` is the default.
  swarf-os entries are all titled `Fedora Linux 44 (Forty Four)`: only the number tells them apart,
  `(ostree:0)` the current image, `(ostree:1)` the previous one. Kinoite is the entry titled
  `(Kinoite)`. The menu may show only one second: press an arrow key as soon as it appears (if it
  does not appear, hold Shift or press Esc during start-up).
- **Any deployment as the default:** `sudo tools/switch.sh default INDEX` (index from `status`).

## Stay on an older image
A plain rollback lasts only until Discover's next daily update: the deployment still follows
`:stable` and Discover stages it again. To stay back, pin a digest:
```sh
sudo tools/switch.sh pin-to sha256:<digest>   # the image at that digest, never updated
sudo tools/switch.sh switch                   # later: back to :stable and daily updates
```

## Clean up
Kinoite stays pinned (and uses disk space) until `sudo tools/switch.sh unpin INDEX`.
