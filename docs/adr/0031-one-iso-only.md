# 0031 — One ISO only in R2 (step 7, maintainer decision)

Date: 2026-11-03. Status: accepted. Changes SPEC ("keep the last two ISOs").

## Context
R2 is free up to 10 GB-month, counted as the daily peak averaged over 30 days, with no documented
spending cap (`r2/pricing`, read 2026-11-02). The ISO is 4.91 GB (run 41541236834). Two ISOs are
9.8 GB every day plus the weekly upload peak (a third ISO for a few minutes): about 10.5 GB-month,
billed. The maintainer does not want any R2 bill.

## Decision
The bucket keeps one release. Each weekly run uploads the new one, checks it, then deletes the
old one (ADR 0029): about 6 GB-month. A previous ISO, if ever needed, is rebuilt from the dated
GHCR tag of that image: `tools/iso-build.sh ghcr.io/swarf-os/image:YYYYMMDD`. `tools/r2-upload.sh`
fails the run if the bucket holds more than 8 GB.

## Consequences
No ready-made fallback ISO for download. The ISO growing past ~8 GB would fail the guard (and
the free tier with the upload peak): revisit then.
