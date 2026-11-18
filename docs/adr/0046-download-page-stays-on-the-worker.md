# 0046 — The download page stays on the Worker; GitHub Pages serves only the feed

Date: 2026-11-18. Status: accepted (maintainer, 2026-11-18). Supersedes the "Download page on
GitHub Pages" decision and step 2 of ADR 0044. Step 1 of ADR 0044 and ADR 0045 stand.

## Problem
ADR 0044 planned to move the download page to GitHub Pages: the page would read `/latest.json` on
the Worker, and the Worker would redirect `/` to the site. Before writing it, the maintainer asked
whether R2 could be connected to Pages directly, and then chose the simpler layout below.

## Decision
- **Cloudflare keeps everything about the ISO**: R2 bucket (private), the Worker `get`, the download
  page with the visual word (ADR 0029, 0030, 0031), unchanged.
- **GitHub Pages serves only the RSS feed** and its minimal `site/index.html` (ADR 0044 step 1,
  ADR 0045).
- Not built, because the page no longer moves: `/latest.json`, the CORS header for
  `https://swarf-os.github.io`, the redirect of `/`, changes to `tests/worker-check.sh`. The Worker
  is not touched, so `worker.yml` and the `paths`/`paths-ignore` of `build.yml` (ADR 0032) need no
  change.

## Why (sources read 2026-11-18; the pages carry no date)
- GitHub Docs, "GitHub Pages limits": a published site is 1 GB at most; the soft bandwidth limit is
  100 GB a month. The ISO is about 5 GB, so Pages cannot host it.
- Cloudflare docs, R2 "Public buckets": two ways to read a bucket from outside, `r2.dev` (rate-limited,
  "should only be used for development purposes", no cache, WAF or Access) and a custom domain (must
  be a zone of the same Cloudflare account). The project has no domain and ADR 0029 chose no
  `r2.dev`. So without the Worker there would be no public path to the ISO.
- Cloudflare docs, R2 "CORS": a bucket serving a page on another origin needs a CORS policy, and a
  public bucket cannot be listed from a browser, so CI would also have to write a `latest.json` into
  the bucket. More moving parts than keeping the page where the files are. The page did not say
  whether `r2.dev` URLs return CORS headers.

## Consequences
- The feed URL `https://swarf-os.github.io/image/feed.xml` is unchanged.
- Nothing to redeploy when the weekly ISO replaces the release folder (as before ADR 0044).
- If a domain is ever added (ADR 0029 notes it would also give a `security@` alias), the question can
  be asked again: this ADR would then be revisited, not patched.
