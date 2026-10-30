# 0013 — The GHCR image is public (step 5)

Date: 2026-10-29. Status: accepted (maintainer decision).

## Context
Machines pull updates from `ghcr.io/swarf-os/image` (Discover, `bootc switch`). SPEC.md left
open: public, or private with a read-only token on each machine. The repository is public and
nothing sensitive may ever be in the image (SPEC, Cloudflare section).

## Decision
The package is public. No token on the machines, no `auth.json` to renew, and the ISO (step 6)
needs no credential.

## Consequences
GHCR creates a package private on its first push. After the first successful publish the
maintainer sets the package to public once (Package settings → Change visibility); until then
a machine cannot pull. Until it is public, CI reads and writes with `GITHUB_TOKEN`.
