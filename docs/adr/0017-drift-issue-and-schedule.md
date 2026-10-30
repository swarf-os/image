# 0017 — One `drift` issue for failures, and the 60-day schedule rule (step 5)

Date: 2026-10-29. Status: accepted.

## Decision
- Any failed run on `schedule`, `main` or dispatch calls `tools/drift-issue.sh fail`: one open
  issue labelled `drift` (created if needed) gets a comment with the run URL and the last
  40 log lines; the next green run closes it. `:stable` is untouched by a failure, so machines
  stay on the previous image, and the issue is what tells the maintainer (and the agent).
- Pull request runs never publish and never open the issue.

## Not solved
GitHub disables scheduled workflows on a public repository after 60 days without repository
activity. A drift pull request, Dependabot pull requests and the maintainer's commits count as
activity; a quiet stretch with none would silently stop the daily build. No mitigation is added
here (a keep-alive commit every day would be noise). To check: Actions tab shows a "disabled
due to inactivity" banner; re-enable with `gh workflow enable build.yml`.
