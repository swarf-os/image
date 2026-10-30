#!/bin/bash
# One open issue labelled "drift" says the daily pipeline is failing.
#   tools/drift-issue.sh fail "SUMMARY" [LOGFILE]   open it, or add a comment if already open
#   tools/drift-issue.sh ok                          close it with a comment
# Needs gh with issues:write; GITHUB_RUN_URL is added to the text when set.
set -euo pipefail
mode=$1
label=drift
gh label create "$label" --color D93F0B --description "Daily CI failure" 2>/dev/null || true
open=$(gh issue list --label "$label" --state open --json number --jq '.[0].number // empty')
case $mode in
fail)
    body="$2"
    [ -n "${GITHUB_RUN_URL:-}" ] && body="$body"$'\n\n'"Run: $GITHUB_RUN_URL"
    [ -n "${3:-}" ] && [ -f "$3" ] && body="$body"$'\n\n```\n'"$(tail -40 "$3")"$'\n```'
    if [ -n "$open" ]; then
        gh issue comment "$open" --body "$body"
    else
        gh issue create --label "$label" --title "Daily build is failing: :stable stays on the previous image" --body "$body"
    fi
    ;;
ok)
    [ -n "$open" ] && gh issue close "$open" --comment "Back to green${GITHUB_RUN_URL:+: $GITHUB_RUN_URL}" || true
    ;;
esac
