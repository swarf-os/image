# 0045 — The pull request feed: details decided while writing (ADR 0044, PR 1)

Date: 2026-11-18. Status: written and tested locally; NOT deployed (needs a merge to `main`).

## Sources read (2026-11-18; the GitHub pages carry no date)
- Action files read at the tag, in a shallow clone: `actions/upload-pages-artifact` v5.0.0
  (`fc324d3547104276b827a68afc52ff2a11cc49c9`), `actions/deploy-pages` v5.0.1
  (`368f82528645a54fb793d4d04e342629a3f51346`), `actions/configure-pages` v6.0.0
  (`45bfe0192ca1faeb007ade9deae92b16b8254a0d`). These are the highest `vN.N.N` tags from
  `git ls-remote --tags` the same day; the SHAs are the tag commits.
- docs.github.com: "Triggering a workflow", "Events that trigger workflows" (`workflow_dispatch`,
  `pull_request`, `pull_request_target`, `schedule`), "Using custom workflows with GitHub Pages",
  "Configuring a publishing source", "Deployments and environments", "Using concurrency",
  "Troubleshooting Dependabot on GitHub Actions", REST "Create a workflow dispatch event".
- RSS 2.0 specification (rssboard.org).

## Facts that decided the design
- `upload-pages-artifact`: inputs `name` (`github-pages`), `path`, `retention-days` (1),
  `include-hidden-files` (false). It tars the directory with `--dereference`, leaves out `.git`,
  `.github` and every dot file. `deploy-pages`: inputs `token`, `timeout`, `error_count`,
  `reporting_interval`, `artifact_name`, `preview` (alpha, unused); output `page_url`; the job needs
  `pages: write` and `id-token: write` and an `environment` (default `github-pages`).
- `configure-pages` only extracts site metadata and configures static site generators; `enablement`
  needs a token other than `GITHUB_TOKEN`. The site is plain HTML with relative links and the feed
  builds its own URL, so **it is not used** (one action less to pin). If Pages is not enabled,
  `deploy-pages` fails on its own; that message was not seen.
- "Events triggered by the `GITHUB_TOKEN` will not create a new workflow run", except
  `workflow_dispatch` and `repository_dispatch`. So `build.yml` can start `site.yml` with
  `gh workflow run`. The docs do not name the token permission a dispatch needs (the REST page
  only says "repo" for classic tokens); the job already has `actions: write`. **A dispatch also only
  works if the workflow file is on the default branch**: before this PR is merged it cannot work.
- A `pull_request` run has `GITHUB_REF` = `refs/pull/N/merge`; an environment limited to `main`
  refuses it ("Deployments and environments"). `pull_request_target` runs in the context of the
  default branch (`GITHUB_REF` = default branch), default types `opened`, `synchronize`,
  `reopened`; the docs warn against running untrusted code on it.
- Dependabot-triggered `push`, `pull_request`, `pull_request_review` and
  `pull_request_review_comment` runs get a read-only token like a fork. `pull_request_target` is
  not in that list.
- Concurrency: one running and one pending run per group; a new pending run replaces the old one
  even with `cancel-in-progress: false`.
- RSS 2.0: `isPermaLink` defaults to **true**, so a guid that is not a plain permalink needs
  `isPermaLink="false"`. Dates are RFC 822 (four-digit year preferred). An item needs a title or a
  description.

## Decisions
- **`pull_request_target`, not `pull_request`, for "a pull request opened, reopened or closed".**
  Deviation from the step text ("pull_request closed"): with `pull_request` the run has
  `refs/pull/N/merge`, which the `github-pages` environment limited to `main` refuses, so every
  closed pull request would give a red run. `pull_request_target` runs on `main`. The job checks
  out `main` (never the pull request head), runs only `tools/` and `site/` from `main`, and only
  for pull requests whose author is `github-actions[bot]` or `dependabot[bot]`. `opened` and
  `reopened` are added to `closed` so a Dependabot pull request reaches the feed without waiting
  for the cron. The workflow file used is the one on `main`, so a pull request cannot change it.
- **Extra `pull_request` trigger, build only**, on `site/**`, `tools/pr-feed.sh` and `site.yml`:
  the build job runs (feed built, artifact uploaded), the deploy job is skipped (not `main`).
  Without it, such a pull request has no check at all (`build.yml` ignores `site/**`, ADR 0032).
- Two jobs: `build` has `contents: read` and `pull-requests: read`; `deploy` has only
  `pages: write` and `id-token: write`. `GITHUB_TOKEN` is not persisted in the checkout.
- Concurrency group `site` for every deploying trigger; pull request builds use their own group.
- Cron `43 */6 * * *`: a net (a Dependabot rebase changes the head commit without any event we
  listen to; a lost dispatch). Not at the top of the hour (delays at "the start of every hour").
- **Feed**: the open pull requests of `github-actions[bot]` and `dependabot[bot]` (`tools/pr-feed.sh`,
  `gh api` with `application/vnd.github.html+json`, so the readers get the rendered body, English
  and French as written). `guid` = `<PR URL>#<head sha>`, `isPermaLink="false"`; `pubDate` and
  `lastBuildDate` come from `updated_at` (no change, same bytes); `<category>` = author. All text
  goes through an XML escaper (control characters dropped); the script runs `xmllint --noout`
  when present and fails the build on a malformed feed. Closed pull requests leave the feed
  (readers keep what they have fetched).
- `build.yml`: `gh workflow run site.yml --ref main` after the drift step when the manifest
  changed, `continue-on-error`: a feed failure must not open the `drift` issue (ADR 0017); the cron
  catches up. `site/**` and `site.yml` join `paths-ignore`. `tools/pr-feed.sh` does not (a change
  to it is checked by the `pull_request` build of `site.yml`, and it is not in the image either way).

## Not confirmed by a primary source
- "A Pages deployment replaces the whole site" (ADR 0044): the pages read do not say it.
- That the GitHub token of a Dependabot-opened `pull_request_target` run can deploy (the docs list
  other events as read-only; this one is not listed). If it fails, the cron still publishes.
- That `actions: write` is enough for `gh workflow run` with `GITHUB_TOKEN`.
