# 0030 — The download page word is a client-side visual gate (step 7, maintainer decision)

Date: 2026-11-03. Status: accepted.

## Decision
The page asks for a word (`fraws`), checked in the browser by a few lines of JavaScript in
`worker/src/index.js`. It is plain text in the public repository and the file links are in the
page and work without it. No Worker secret, no cookie, no server check.

## Why
It only keeps casual visitors away while the project is not yet in line with Fedora's trademark
rules (SPEC, Identity). It is not security and must not look like it: the code says so. The ISO
is effectively public (SPEC), so nothing sensitive may ever be in the image. The page also sends
`noindex` and a `robots.txt` that disallows everything.
