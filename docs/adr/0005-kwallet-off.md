# 0005 — KWallet off (step 3)

Date: 2026-10-29. Status: accepted.

## Context
SPEC: KWallet "not wanted at all". `kf6-kwallet` stays installed (hard dependency of
`kf6-kwallet-libs` users, step 2). In `kf6-kwallet` 6.31 two D-Bus-activated daemons exist:
`kwalletd6` (legacy API) and `ksecretd` (provides `org.freedesktop.secrets` and the secret
portal). Kyanite only knew `kwalletd`.

## Decision (maintainer, 2026-10-29)
`/usr/share/swarf/xdg/kwalletrc` sets `[Wallet] Enabled=false` and `[KSecretD] Enabled=false`
(keys from `/usr/share/config.kcfg/kwalletsettings.kcfg`). Both daemons check their key at
start and exit (`kwalletd/main.cpp`, `ksecretd/main.cpp`, kwallet v6.31.0), so D-Bus
activation succeeds without a wallet. `pam-kwallet` and `kwalletmanager5` are blacklisted.

## Consequences
- No `org.freedesktop.secrets` provider in the session. Flatpak browsers and other apps
  keep their secrets themselves or ask again each time.
- The files are read through `XDG_CONFIG_DIRS` set at the start of a Plasma session
  (`/etc/xdg/plasma-workspace/env/swarf-xdg.sh`, same mechanism as Kyanite ADR 0014). Only a
  logged-in session proves the result; see PROGRESS.
