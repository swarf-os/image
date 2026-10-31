# 0012 — Task manager with icons and text (step 4, maintainer request)

Date: 2026-10-29. Status: accepted.

## Context
Plasma 6.7.5's default panel layout (`plasma-desktop`,
`/usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js`)
adds `org.kde.plasma.icontasks`, the icons-only widget. The maintainer wants icons and text.
`org.kde.plasma.taskmanager` is the widget with titles (`libtaskmanager` applet in the image).

## Decision
`build/configure.sh` replaces the widget id in that template (the same mechanism as Kyanite
and Bazzite), failing the build if the line is not found before or after. The same step writes an
empty `launchers` list into the widget's General group: no pinned apps (maintainer request,
step 6, the installed system showed pinned launchers).
Tested live in the VM (`bootc usroverlay`, same `sed`, panel reset): the panel shows
window titles.

## Consequences
Applies to new users only (the layout runs when the panel is first created). Breaks if
Plasma renames the widget or the template: the build fails.
