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
- Say it = do it. "I'm starting X" must be a tool call in the same turn. "I'll tell you when X" must start a background watcher in the same turn (see "Long jobs"). Never end a turn with a promise and nothing running.
- Test fixtures (test kickstart, extra disks, overrides) must not set what the test verifies. Before a check, list the fixtures attached; remove them for the final check. Note them in `PROGRESS.md` next to the result.
- VM observation is text first: disk write counters, the DIAG raw disk, ssh in `tests/` images. A screenshot only when text cannot answer, at most one per question, and say why. After any VT switch or diagnostic, put the VM back (Ctrl+Alt+F1/F2) before handing it to the maintainer.
- Subagent reports are leads, not facts. "Not found" never means "does not exist": check any absence or any claim a decision rests on in the primary source (code at the tag in use, the image) before using it.

## Long jobs (builds, VM installs)
- Every long job writes its own exit file: `(cmd >log 2>&1; echo $? >job.exit)`. Delete `job.exit` before starting. Watchers wait on that file, never on `pgrep` (`pgrep -f` matches the watcher's own command line).
- Watcher timeout = 2 x the expected duration (ISO build ~30 min, VM install ~35 min, image + VM ~30 min), and it reports both outcomes (done / timed out). No fixed iteration count shorter than the job, no `; true`.
- Use `LC_ALL=C` for any command whose output a watcher parses (`virsh domstate`, etc.).
- While a job runs, give the maintainer the expected end time (local time) and check it yourself at that time.

## Launch prompt for the next step
- Written in French, ready to paste, in the same shape as the previous one: repository and branch state, files to read (`SPEC.md`, `AGENTS.md`, `PROGRESS.md`), the single step to do and nothing else, the question to ask the maintainer before writing (if any), and the usual rules (verify package names with `dnf repoquery`, logs in files, update `PROGRESS.md`, commit on a branch, open a PR, stop).
