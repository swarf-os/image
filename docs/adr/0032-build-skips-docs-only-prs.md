# 0032 — Pull requests that touch only docs or the Worker skip the image build

Date: 2026-11-03. Status: accepted (maintainer request, after PR #34 waited about 10 minutes
for a build that could not change: it touched only docs and `tests/worker-check.sh`).

## Decision
`build.yml` keeps running on every schedule, push to `main` and dispatch. On `pull_request` it gets
`paths-ignore`: `docs/**`, `*.md` (repository root only), `worker/**`, `tests/worker-check.sh`,
`.github/workflows/worker.yml`. None of these is in the image or used by `tools/`, `build/`,
`iso/` or `system/` (checked with grep: only comments name `docs/adr`). The Worker has its own
`worker` workflow.

## Rules checked (GitHub docs, "Workflow syntax", read 2026-11-03)
- The workflow is skipped only when *all* changed paths match `paths-ignore`; one other file and
  it runs.
- `*` does not match `/` (`*.js`: "files at the root of the repository"); `**` matches `/`.
- A skipped workflow leaves a required check "Pending". `main` has no branch protection and no
  ruleset (checked 2026-11-03), so nothing blocks the merge.

## Consequence
Such a PR shows no `build` check; merge it once its other checks (if any) are green.
