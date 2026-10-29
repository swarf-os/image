# 0010 — Discover reviews (ODRS) blocked by /etc/hosts (step 4)

Date: 2026-10-29. Status: accepted. Closes the item deferred in 0004.

## Context
Discover 6.7.5 hard-codes `https://odrs.gnome.org/1.0/reviews/api` (`Odrs.cpp`, `APIURL`).
Ratings are downloaded at start; opening an application page sends `app_id`, `distro`,
`version`, `locale` and a salted `user_hash`. No setting, no environment variable.
The VM resolves hosts with `files` first (`/etc/nsswitch.conf`), so `/etc/hosts` wins.

## Decision
Block it: `system/etc/hosts` is Fedora's file (`setup` package) plus
`0.0.0.0 odrs.gnome.org`. Consistent with telemetry off (0004). Cost: Discover shows no
star ratings or reviews. The file is a named exception to "`/etc` stays untouched"; a
`setup` update to `/etc/hosts` will not follow (the file is unchanged for years). Not done
with `RUN` in `configure.sh`: podman bind-mounts `/etc/hosts` during `RUN`.

## Rejected
Accept and document: ratings are of little use for a few Flathub apps, and the query leaks
the app being browsed. A firewall rule cannot filter by name.
