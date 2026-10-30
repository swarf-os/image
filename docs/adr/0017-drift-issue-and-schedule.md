# 0017 — One `drift` issue for failures, and the 60-day schedule rule (step 5)

Date: 2026-10-29. Status: accepted.

## Decision
- Any failed run on `schedule`, `main` or dispatch calls `tools/drift-issue.sh fail`: one open
  issue labelled `drift` (created if needed) gets a comment with the run URL and the last
  40 log lines; the next green run closes it. `:stable` is untouched by a failure, so machines
  stay on the previous image, and the issue is what tells the maintainer (and the agent).
- Pull request runs never publish and never open the issue.

## The 60-day rule
GitHub docs (events-that-trigger-workflows, read 2026-10-30; the page has no date):
"In a public repository, scheduled workflows are automatically disabled when no repository
activity has occurred in 60 days." Checked: the page says nothing about private repositories
for this rule, so it is documented for public ones only (not proven absent for private ones).
The docs do not define "repository activity". A disabled schedule opens no issue (an absent
run is not a failure). `workflow_dispatch` and `push` are not affected.

Measures:
1. Each successful scheduled run ends with `gh workflow enable build.yml` (`actions: write`,
   `continue-on-error`). Free.
2. A private guardian repository (`swarf-os/guardian`) runs a daily workflow with a
   GitHub App installation token (secrets `APP_CLIENT_ID` and `APP_PRIVATE_KEY`, Actions read/write on `swarf-os/image` only; a personal access token would expire within 366 days, the organisation limit):
   it enables `build.yml` and fails if the last successful run on `main` is older than 48 h
   or if the token stops working. The failed run is the alert.
3. Rejected: a timer on a NUC (needs a machine that stays on); a shared token in the image
   (the image and repository are public, anyone could read it).

## Not proven
- That `gh workflow enable` resets the inactivity counter. Only third-party tools claim it
  (gh-workflow-immortality); GitHub does not document it. Whether commits, runs or
  Dependabot pull requests count as "activity" is also undocumented.
- That the private guardian's own schedule is exempt from the rule (documented for public
  repositories only).
- The App private key must stay secret; revoke it in the App settings if it leaks.
