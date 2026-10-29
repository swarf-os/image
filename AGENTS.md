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
