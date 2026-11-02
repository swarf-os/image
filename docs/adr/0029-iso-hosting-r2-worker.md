# 0029 — The ISO is published to R2, one release at a time, served by a Worker (step 7)

Date: 2026-11-03. Status: accepted (maintainer: workers.dev, default names, one ISO only to stay
in the free tier, Worker deployed by CI, signature keyless unchanged, weekly rhythm unchanged).
Upload and deployment are NOT seen on Cloudflare yet: they run on `main` once the secrets exist.

## Limits checked (Cloudflare docs, read 2026-11-02)
- R2 (`r2/platform/limits`, updated 2026-10-30): object up to 5 TiB; one request (a single PUT or
  one multipart part) at most 5 GiB; 10,000 parts. `r2/objects/multipart-objects`: parts of
  5 MiB at least, all the same size except the last; unfinished uploads aborted after 7 days.
- Workers and Pages static assets: 25 MiB per file (`workers/platform/limits`, 2026-10-29;
  `pages/platform/limits`). An ISO cannot be an asset. Worker request bodies are 100 MB on the
  Free plan, so the upload goes to the R2 S3 endpoint, not through the Worker. No response size
  limit; the CDN cache limit (512 MB) only means the ISO is not cached.
- R2 pricing (`r2/pricing`): free 10 GB-month, 1 M class A, 10 M class B operations, no egress
  fee. A GB-month is the daily *peak* averaged over 30 days. No spending cap is documented;
  budget alerts exist (`billing/manage/budget-alerts`) but only send an e-mail.
- `r2.dev` public buckets are rate-limited and for development only (`r2/buckets/public-buckets`).
  `workers.dev` needs no domain (`workers/configuration/routing/workers-dev`).
- R2 needs an R2 subscription (dashboard checkout) even for the free tier (`r2/get-started`).

## Decision
- Bucket `swarf-os-iso` (private), Worker `swarf-os` on `swarf-os.<subdomain>.workers.dev`,
  binding `ISO` (`worker/wrangler.jsonc`). The Worker serves the page and streams each file from
  R2 with `Range`, `HEAD`, `ETag` and `If-None-Match`, so downloads resume. File URLs are not
  secret and need no word (SPEC).
- **One ISO only.** The ISO is 4.91 GB (run 41541236834). Two would be 9.8 GB plus the weekly
  upload peak, about 10.5 GB-month: billed. One stays near 6 GB-month with the upload peak. The
  SPEC's "keep the last two" is changed. A previous ISO is rebuilt on demand from a dated
  GHCR tag: `tools/iso-build.sh ghcr.io/swarf-os/image:YYYYMMDD`.
- **Release folders.** `tools/r2-upload.sh` (called by `iso.yml` after signing, `main` only)
  uploads to `YYYYMMDD-HHMM/`: the ISO, `SHA256SUMS`, then `SHA256SUMS.bundle` last. The Worker
  shows the newest folder that has all three, so a half-done upload is never offered. File names
  stay as built (`swarf-os-44-x86_64.iso`), so the signed `SHA256SUMS` stays valid; the date is
  in the folder, not the file (SPEC naming line adjusted).
- After `rclone check` (sizes and MD5) passes, every other `YYYYMMDD-HHMM/` folder is deleted,
  whatever it holds, so a Fedora 45 file name does not leave the 44 ISO behind. Any failure before
  that leaves the previous release online. Then the bucket total is checked: above 8 GB the step
  fails (red run), since R2 would bill silently.
- **rclone 1.75.2**, pinned by sha256 (`rclone-v1.75.2-linux-amd64.zip`, checked against the
  release `SHA256SUMS`), configured from the environment with Cloudflare's documented settings
  (`provider = Cloudflare`, `no_check_bucket = true` for a bucket-scoped token). Multipart above
  64 MiB: about 75 equal parts. The AWS CLI was not chosen: its version on the runner image is not
  pinned, and since 2.23 it sends default checksums that are reported (unofficial source, not
  tested here) to fail on R2 unless `AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED` is set
  (AWS SDK reference, "Data integrity protections").
- **Worker deployment** by `.github/workflows/worker.yml` on changes to `worker/` (dry run on pull
  requests), wrangler 4.151.1 pinned by `package-lock.json`, run in the pinned `node:22` image,
  telemetry off (`WRANGLER_SEND_METRICS=false`, ADR 0004).
- No secret set → both workflows skip with a warning instead of failing.

## Secrets (created by the maintainer, GitHub → Settings → Secrets → Actions)
- `CLOUDFLARE_ACCOUNT_ID`.
- `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`: R2 API token, "Object Read & Write", bucket
  `swarf-os-iso` only.
- `CLOUDFLARE_API_TOKEN`: "Edit Cloudflare Workers" template, this account only.

## Seen / not seen
- Seen locally: `wrangler deploy --dry-run` (binding `env.ISO`); `wrangler dev --local` with a
  fake R2: page picks the newest complete folder and ignores an incomplete one,
  `tests/worker-check.sh` OK, 206 for start, open-ended and suffix ranges, a resumed
  `curl -C -` passes `sha256sum -c`, 304 on `If-None-Match`. `tools/r2-upload.sh` against
  `rclone serve s3`: multipart in equal parts, MD5 checked, old folder (other file name) deleted,
  stray object warned, size guard fails the step, missing secrets skip, partial secrets fail.
- NOT seen: a real upload to R2 (MD5 on a multipart object relies on rclone's metadata), the
  Worker on Cloudflare, the 5 GB download through it, the weekly run.
