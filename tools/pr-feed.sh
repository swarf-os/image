#!/bin/bash
# RSS 2.0 feed of the open pull requests opened by the CI (github-actions[bot], the
# manifest-drift pull request of ADR 0014) and by Dependabot (ADR 0044, 0045).
#   tools/pr-feed.sh OUTPUT.xml
# Needs gh (GH_TOKEN with pull-requests:read, or nothing: the repository is public) and jq.
# Environment:
#   GITHUB_REPOSITORY  owner/name (default swarf-os/image)
#   SITE_URL           public URL of the site, with a trailing slash
#                      (default https://<owner>.github.io/<name>/)
#   PR_JSON            test hook: a file holding the pulls API answer, used instead of gh
# One item per open pull request. The guid is the pull request URL plus the head commit, so a
# force-pushed manifest-drift (same URL, new commit) is a new item for the readers.
set -euo pipefail
export LC_ALL=C
out=${1:?usage: tools/pr-feed.sh OUTPUT.xml}
repo=${GITHUB_REPOSITORY:-swarf-os/image}
owner=${repo%%/*}
SITE_URL=${SITE_URL:-https://${owner,,}.github.io/${repo#*/}/}
case $SITE_URL in */) ;; *) SITE_URL=$SITE_URL/ ;; esac

tmp=$(mktemp "$out.XXXXXX")
trap 'rm -f "$tmp"' EXIT

# body_html: GitHub renders the Markdown body (media type application/vnd.github.html+json), so
# the readers show it as formatted text.
if [ -n "${PR_JSON:-}" ]; then
    prs=$(jq -s 'add // []' "$PR_JSON")
else
    prs=$(gh api -H 'Accept: application/vnd.github.html+json' --paginate \
        "repos/$repo/pulls?state=open&per_page=100" | jq -s 'add // []')
fi

# The jq program is a here-document (quoted: nothing is expanded) so that quotes stay readable.
# esc: XML escaping, after dropping the control characters XML 1.0 forbids; 39 is the apostrophe.
read -r -d '' program <<'JQ' || true
def esc:
  gsub("[\\x00-\\x08\\x0b\\x0c\\x0e-\\x1f]"; "")
  | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;")
  | gsub("\""; "&quot;") | gsub([39] | implode; "&apos;");
def rfc822: fromdateiso8601 | strftime("%a, %d %b %Y %H:%M:%S GMT");
[ .[] | select(.user.login == "github-actions[bot]" or .user.login == "dependabot[bot]") ]
| sort_by(.updated_at) | reverse as $items
| ($items | map(.updated_at) | max // (now | todate)) as $last
| (
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
    "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">",
    "<channel>",
    "<title>\("\($repo): pull requests of the CI and Dependabot" | esc)</title>",
    "<link>\($site | esc)</link>",
    "<atom:link href=\"\("\($site)feed.xml" | esc)\" rel=\"self\" type=\"application/rss+xml\"/>",
    "<description>\("Open pull requests opened by the CI and by Dependabot in \($repo)" | esc)</description>",
    "<language>en</language>",
    "<lastBuildDate>\($last | rfc822)</lastBuildDate>",
    ( $items[] |
      "<item>",
      "<title>\("#\(.number) \(.title)" | esc)</title>",
      "<link>\(.html_url | esc)</link>",
      "<guid isPermaLink=\"false\">\("\(.html_url)#\(.head.sha)" | esc)</guid>",
      "<pubDate>\(.updated_at | rfc822)</pubDate>",
      "<category>\(.user.login | esc)</category>",
      "<description>\((.body_html // "" | if . == "" then "<p>(no description)</p>" else . end) | esc)</description>",
      "</item>"
    ),
    "</channel>",
    "</rss>"
  )
JQ
jq -r --arg site "$SITE_URL" --arg repo "$repo" "$program" <<<"$prs" >"$tmp"

# A feed that is not well-formed would silently stop every reader: fail the deployment instead.
if command -v xmllint >/dev/null; then
    xmllint --noout "$tmp"
fi
mv "$tmp" "$out"
trap - EXIT
echo "OK: $out ($(grep -c '^<item>' "$out") items)"
