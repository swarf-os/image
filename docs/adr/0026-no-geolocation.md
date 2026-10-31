# 0026 — Anaconda geolocation off (step 6, maintainer decision)

Date: 2026-10-31. Status: accepted (to be confirmed on the next ISO).

## Context
`/etc/anaconda/anaconda.conf` has `geolocation_provider = https://geoip.fedoraproject.org/city`
and `use_geolocation = True`. With a network, the installer asked that server and preselected
French and a French layout on the VM. This corrects ADR 0022 ("starts in English, US") and the
first VM install, where the French default was wrongly put down to the test kickstart.

## Decision
The `swarf-os` profile sets an empty `geolocation_provider` and `use_geolocation = False`
(`iso/swarf-os.conf`): no request, in line with the no-telemetry rule (ADR 0004). The installer
starts in English with a US keyboard, as ADR 0022 says. Language, keyboard and time zone are
chosen by hand.
