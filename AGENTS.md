# AGENTS.md

Personal Fedora bootc image (Plasma, minimal). `SPEC.md` is the source of truth.

**Read `SPEC.md` and `PROGRESS.md` at the start of every session.**

## Agent rules
- Never run `sudo`/`run0` on the host. Use rootless paths or give me a script to run.
- Long outputs: scripts write the log to a file and print only OK or the useful error lines.
- Read the upstream docs (Fedora, bootc, KDE, systemd) for the version in use before writing; never guess a package name, unit name or key. Check it with `dnf repoquery -l` or in the image. Source and date in the ADR.
- Check the visible result before saying "fixed". Test in the VM before handing over.
- One step per session: read SPEC.md + PROGRESS.md, do the step, update PROGRESS.md, commit, stop.
- One short ADR per decision, written when decided.
- Code and docs in English.
- At the end of a step, call the supervisor model (`advisor`) for a quick check of the work, then generate the launch prompt for the next step (see "Launch prompt" below).

## Launch prompt for the next step
- Written in French, ready to paste, in the same shape as the previous one: repository and branch state, files to read (`SPEC.md`, `AGENTS.md`, `PROGRESS.md`), the single step to do and nothing else, the question to ask the maintainer before writing (if any), and the usual rules (verify package names with `dnf repoquery`, logs in files, update `PROGRESS.md`, commit on a branch, open a PR, stop).
