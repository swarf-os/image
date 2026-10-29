# Add the swarf KDE defaults to XDG_CONFIG_DIRS, right after /etc/xdg
# (local administrator settings) and before Fedora's kde-settings directory.
# Plasma sources the scripts of this directory in alphabetical order:
# Fedora's env.sh has already set XDG_CONFIG_DIRS.

swarf_xdg=/usr/share/swarf/xdg

case ":${XDG_CONFIG_DIRS:-}:" in
*":$swarf_xdg:"*) ;;
*":/etc/xdg:"*)
    XDG_CONFIG_DIRS=$(printf '%s' "$XDG_CONFIG_DIRS" | sed "s|/etc/xdg|/etc/xdg:$swarf_xdg|")
    ;;
*)
    XDG_CONFIG_DIRS="/etc/xdg:$swarf_xdg${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"
    ;;
esac
export XDG_CONFIG_DIRS
unset swarf_xdg
