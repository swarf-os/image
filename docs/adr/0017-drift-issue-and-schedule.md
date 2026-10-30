# 0017 — One `drift` issue for failures, and the 60-day schedule rule (step 5)

Date: 2026-10-29. Status: accepted.

## Decision
- Any failed run on `schedule`, `main` or dispatch calls `tools/drift-issue.sh fail`: one open
  issue labelled `drift` (created if needed) gets a comment with the run URL and the last
  40 log lines; the next green run closes it. `:stable` is untouched by a failure, so machines
  stay on the previous image, and the issue is what tells the maintainer (and the agent).
- Pull request runs never publish and never open the issue.

## The 60-day rule
GitHub docs (events-that-trigger-workflows, read 2026-10-30): "In a public repository, scheduled
workflows are automatically disabled when no repository activity has occurred in 60 days."
The docs do not define "repository activity" and do not say whether scheduled runs, drift or
Dependabot pull requests count; nothing here relies on any of them. A disabled schedule opens no
issue (an absent run is not a failure).

Mitigation, cheap and unproven: each successful scheduled run ends with `gh workflow enable
build.yml` (needs `actions: write`). Third-party projects report that this resets the
inactivity timer; GitHub does not document it. Stronger option, not done (needs a token on the
NUC): a systemd timer on the NUC runs `gh workflow run build.yml` when the last run is older
than two days; a manual dispatch is not subject to the rule. Check by hand now and then: the
Actions tab shows "disabled due to inactivity"; `gh workflow enable build.yml` fixes it.
