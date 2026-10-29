#!/bin/bash
# Step 3 checks, run as root inside the test VM: tools/vmssh 'bash -s' < tests/check-config.sh
# Prints one line per failure and OK or FAILED at the end. Nothing here needs a Plasma session:
# the XDG files are read with XDG_CONFIG_DIRS set the way plasma-workspace/env/swarf-xdg.sh sets it.
fail=0
check() { # check DESCRIPTION EXPECTED ACTUAL
    [ "$2" = "$3" ] || { echo "FAIL $1: expected '$2', got '$3'"; fail=1; }
}

for kv in kernel.kptr_restrict=2 kernel.dmesg_restrict=1 net.core.bpf_jit_harden=2 \
    kernel.unprivileged_bpf_disabled=1 kernel.kexec_load_disabled=1 kernel.sysrq=0 \
    dev.tty.ldisc_autoload=0 kernel.yama.ptrace_scope=1 fs.protected_regular=2 \
    fs.protected_fifos=2 fs.suid_dumpable=0 'kernel.core_pattern=|/bin/false' \
    net.ipv4.conf.all.accept_redirects=0 net.ipv6.conf.all.accept_redirects=0 \
    net.ipv4.conf.all.rp_filter=2 net.ipv4.tcp_rfc1337=1 net.ipv6.conf.all.use_tempaddr=2; do
    check "sysctl ${kv%%=*}" "${kv#*=}" "$(sysctl -n "${kv%%=*}" 2>&1)"
done

for u in bootc-fetch-apply-updates.timer systemd-homed.service flatpak-add-fedora-repos.service \
    rpm-ostree-countme.timer mdmonitor.service raid-check.timer; do
    check "disabled $u" disabled "$(systemctl is-enabled "$u" 2>&1)"
done
for u in geoclue.service avahi-daemon.service avahi-daemon.socket systemd-coredump.socket; do
    check "masked $u" masked "$(systemctl is-enabled "$u" 2>&1)"
done
check "firewalld enabled" enabled "$(systemctl is-enabled firewalld.service 2>&1)"
check "firewalld active" active "$(systemctl is-active firewalld.service 2>&1)"

check "default zone" swarf "$(firewall-cmd --get-default-zone 2>&1)"
check "zone services (test image adds ssh)" "dhcpv6-client mdns ssh" "$(firewall-cmd --zone=swarf --list-services 2>&1)"
rpm -q firewall-config >/dev/null 2>&1 && { echo "FAIL firewall-config installed"; fail=1; }
rpm -q plasma-firewall >/dev/null 2>&1 || { echo "FAIL plasma-firewall missing"; fail=1; }

check "os-release VARIANT_ID" custom "$(. /usr/lib/os-release && echo "$VARIANT_ID")"
check "os-release ID" fedora "$(. /usr/lib/os-release && echo "$ID")"
NetworkManager --print-config 2>&1 | grep -A1 '^\[connectivity\]' | grep -q '^enabled=false' ||
    { echo "FAIL NetworkManager connectivity not disabled"; fail=1; }
check "authselect" "Current configuration is valid." "$(authselect check 2>&1)"
check "failed units" 0 "$(systemctl --failed --no-legend 2>&1 | wc -l)"

export XDG_CONFIG_DIRS=/etc/xdg:/usr/share/swarf/xdg:/usr/share/kde-settings/kde-profile/default/xdg
rd() { kreadconfig6 --file "$1" --group "$2" --key "$3" 2>&1; }
check "kwalletrc Wallet" false "$(rd kwalletrc Wallet Enabled)"
check "kwalletrc KSecretD" false "$(rd kwalletrc KSecretD Enabled)"
check "ksplashrc Engine" none "$(rd ksplashrc KSplash Engine)"
check "kwinrc overview" false "$(rd kwinrc Plugins overviewEnabled)"
check "kwinrc systembell" false "$(rd kwinrc Plugins systembellEnabled)"
check "kwinrc zoom" false "$(rd kwinrc Plugins zoomEnabled)"
check "kaccessrc SystemBell" false "$(rd kaccessrc Bell SystemBell)"
mkdir -p /tmp/kdedefaults-sim && printf '[KSplash]\nEngine=KSplashQML\n' >/tmp/kdedefaults-sim/ksplashrc
check "ksplashrc beats kdedefaults" none "$(XDG_CONFIG_DIRS=/tmp/kdedefaults-sim:$XDG_CONFIG_DIRS rd ksplashrc KSplash Engine)"
check "panel task manager" 1 "$(grep -c 'addWidget("org.kde.plasma.taskmanager")' /usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js)"
check "kdeglobals ghns" false "$(rd kdeglobals 'KDE Action Restrictions' ghns)"
check "kdeglobals look and feel (Fedora's, untouched)" org.fedoraproject.fedora.desktop "$(rd kdeglobals KDE LookAndFeelPackage)"
check "UserFeedback.conf" false "$(grep -h '^Enabled=' /usr/share/swarf/xdg/KDE/UserFeedback.conf | cut -d= -f2)"

check "bootc-fetch-apply-updates.timer" disabled "$(systemctl is-enabled bootc-fetch-apply-updates.timer 2>&1)"
check "rpm-ostreed-automatic.timer" disabled "$(systemctl is-enabled rpm-ostreed-automatic.timer 2>&1)"
check "polkit rule rpm-ostree upgrade" 1 "$(grep -c 'rpmostree1.upgrade' /usr/share/polkit-1/rules.d/org.projectatomic.rpmostree1.rules)"
check "Discover unattended" true "$(rd PlasmaDiscoverUpdates Global UseUnattendedUpdates)"
check "Discover interval" 86400 "$(rd PlasmaDiscoverUpdates Global RequiredNotificationInterval)"
check "odrs.gnome.org blocked" 0.0.0.0 "$(getent ahostsv4 odrs.gnome.org | awk 'NR==1{print $1}')"

[ "$fail" = 0 ] && echo OK || echo FAILED
exit "$fail"
