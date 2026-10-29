# 0001 — Start on Fedora 44

Date: 2026-10-29. Status: accepted.

## Context
SPEC.md asks to check whether Fedora 45 is final before choosing the starting
version. On 2026-10-29 `quay.io/fedora/fedora-bootc:45` exists (built 2026-10-28)
but `https://fedoraproject.org/releases.json` still lists "45 Beta". F44 is the
latest final release.

## Decision
`ARG FEDORA_MAJOR=44` in the `Containerfile`. Chosen by the maintainer.
The bump to 45 comes later, once it is final (see SPEC, open question on the
version policy).
