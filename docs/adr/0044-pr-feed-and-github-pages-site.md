# 0044 — An RSS feed of CI pull requests, and the download page moves to GitHub Pages

Date: 2026-11-18. Status: accepted (maintainer, 2026-11-18). Nothing is built yet: this ADR records
the decision; the work is split in two pull requests (below).

## Problem
- GitHub offers no feed for pull requests (as far as I know; not checked from the agent's sandbox,
  whose proxy answers 403 to `pulls.atom`, `issues.atom` and `releases.atom` alike). The maintainer
  wants to be told when the CI opens a pull request (the `manifest-drift` PR of ADR 0014, and
  Dependabot's).
- The download page is served by the Worker `get` (ADR 0029). It cannot carry a feed, and the Worker
  should not become the project's website.

## Decision
- **Site in this repository, not a dedicated one.** The feed is driven by events of this
  repository's workflows. A `GITHUB_TOKEN` cannot start a workflow in another repository, so a
  dedicated repository would need a GitHub App token or a cron, and a cron-only workflow is switched
  off after 60 days without a commit (ADR 0017). Cost accepted: the URL is
  `https://swarf-os.github.io/image/`, not the root. The feed URL cannot be redirected later (Pages
  cannot redirect XML), so this URL is the one to keep.
- **Source in `site/`** (not `docs/`: `docs/` is the maintainer's notes and is not published).
  Logic in `tools/` (SPEC: YAML only calls scripts). Deployed by a workflow `site.yml` with the
  Pages Actions flow, from `main` only. A Pages deployment replaces the whole site, so one
  concurrency group covers every trigger.
- **The feed lists open pull requests** authored by `github-actions[bot]` and `dependabot[bot]`
  (maintainer: Dependabot too). Item `guid` is the PR URL plus the head commit, because
  `manifest-drift` is one PR whose branch is force-pushed and body edited: a plain URL would notify
  once only. Triggers: a direct `workflow_dispatch` from `build.yml` after `tools/drift-pr.sh`
  (PRs opened with `GITHUB_TOKEN` start no `pull_request` workflow), PR closed, a cron as a net,
  and by hand.
- **Download page on GitHub Pages, files still on R2 through the Worker.** R2 stays private (no
  `r2.dev`, no domain: ADR 0029), so the Worker remains as a file server (`/<release>/<file>`,
  Range, ETag). It also answers `/latest.json` (release folder, file name, size) with CORS for
  `https://swarf-os.github.io`; the page reads it when it loads, so the weekly upload redeploys
  nothing and no link dies when the old release is deleted. `/` on the Worker redirects to the Pages
  site. The visual word (ADR 0030) is unchanged; Pages cannot send `X-Robots-Tag`, so the page uses
  `<meta name="robots" content="noindex">`.
- Rejected: page generated at deploy time with the release data. `iso.yml` would have to start the
  deployment before the old release is deleted (splitting `tools/r2-upload.sh`), and each feed
  deployment would need the current release anyway, which brings back a lookup on the Worker.

## Steps
1. Feed: `tools/pr-feed.sh`, `site.yml`, a minimal `site/index.html`, the call in `build.yml`,
   `site/**` and `site.yml` in the `paths-ignore` of `build.yml` (ADR 0032).
2. Page: `site/index.html` reads `/latest.json`; Worker route, redirect and `tests/worker-check.sh`;
   the Worker keeps its page until the new one is seen online.

## Maintainer action before step 1
Settings → Pages → Source: GitHub Actions; restrict the `github-pages` environment to `main`.

## To read before writing (not read yet)
GitHub docs for `actions/configure-pages`, `actions/upload-pages-artifact`, `actions/deploy-pages`
(inputs, permissions, `workflow_dispatch` from `GITHUB_TOKEN`), and the RSS 2.0 `guid` rules. Source
and date go in the step's ADR; actions pinned by SHA (SPEC, CI rule 9).
