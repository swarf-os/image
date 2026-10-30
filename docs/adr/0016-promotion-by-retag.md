# 0016 — `:testing` → `:stable` by retag, drift pull request (step 5)

Date: 2026-10-29. Status: accepted.

## Decision
- Order: build → static checks → push `:testing` and a dated tag `:YYYYMMDD` → cosign keyless
  signature, provenance and SBOM attestations → boot test **on the pushed digest** → promotion.
- Manifest unchanged and all green: `tools/promote.sh` copies the manifest of that digest to
  `:stable` (`skopeo copy --all --preserve-digests`, same repository) and checks that `:stable`
  has the same digest. Nothing is rebuilt between test and promotion.
- Manifest changed (packages, units, repos, `VERSION_ID`): `tools/drift-pr.sh` force-pushes the
  fixed branch `manifest-drift` with the new `manifest/` and `manifest/tested-digest`, and
  opens or updates one pull request. Merging it runs `.github/workflows/promote.yml`, which
  retags the digest recorded in the file. The merge is the maintainer saying "I looked".
- Dated tags exist for rollback and for testing an unattended update from an older image.
  `tools/prune.sh` keeps the newest 30 dated tags and never deletes `:testing`, `:stable`,
  `.sig` tags or untagged versions (attestations).

## Consequences
The repository setting "Allow GitHub Actions to create and approve pull requests" must be on
(it was off on 2026-10-29: `can_approve_pull_request_reviews: false`); until then the drift
step fails and opens the issue. Pull requests made with `GITHUB_TOKEN` do not start workflows,
which this design does not need. After a merge the push to `main` starts a normal run, which may
promote a newer digest with the same manifest.
