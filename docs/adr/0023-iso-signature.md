# 0023 — SHA256SUMS is signed keyless by the workflow (step 6)

Date: 2026-10-30. Status: accepted (maintainer: keyless). Signing is untested until the workflow
runs: `workflow_dispatch` and `schedule` only run from `main`.

## Decision
`iso.yml` runs `cosign sign-blob --yes --bundle SHA256SUMS.bundle SHA256SUMS` (Sigstore keyless,
the GitHub OIDC token). Verification:

    cosign verify-blob --bundle SHA256SUMS.bundle \
      --certificate-identity 'https://github.com/swarf-os/image/.github/workflows/iso.yml@refs/heads/main' \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com SHA256SUMS
    sha256sum -c SHA256SUMS

This is the identity SPEC left open. It only matches runs from `main`, which is intended.

## Consequences
No key to keep. Verification needs the Sigstore transparency log (online or a bundle with the
inclusion proof, which `--bundle` contains).
