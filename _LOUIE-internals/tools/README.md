# Framework-Dev Tools

Repo-only tooling for maintaining the framework. Nothing in this folder is distributed — the distributed framework stays build-step-free.

## check-consistency.sh (finding E-02)

Lints the surfaces that must stay in sync by hand. Run before every commit:

```
bash _LOUIE-internals/tools/check-consistency.sh
```

Exit 0 = clean; exit 1 with `FAIL:` lines otherwise.

### What it checks

1. **Command-set consistency.** Canonical set = `_LOUIE_/commands/louie-*.md` filenames. Every registration surface must list exactly that set: the 12 init scripts' embedded command tables/bullet lists (`_LOUIE_/setup/*-init.sh/.bat`), root `CLAUDE.md`, `README.md`, `_LOUIE_/workflow/ai-workflow.md`, and `_LOUIE_/setup/project-setup.md`. Both directions: missing commands and listed-but-nonexistent commands fail.
2. **Merged-bullet corruption.** The "two list items on one line" pattern (`- \`x\` — desc- \`y\` — desc`) that regex-based insertions have produced twice (see CHANGELOG: the `louie-continue` rollout, and the Key Files bug fixed 2026-07-02).
3. **Path existence.** Every backticked `_LOUIE_/...` path referenced in distributed files (root `CLAUDE.md`, `README.md`, all `.md` under `_LOUIE_/`, the init scripts) must exist. Placeholders (`<...>`), globs (`*`), and ellipses are skipped; `foo.sh/.bat` checks both variants. `_LOUIE-internals/` is exempt — internals docs may reference planned files.
4. **sh/bat pairing.** Every init script exists in both variants, and both register the same command set.
5. **Version bump discipline (finding E-03).** `_LOUIE_/VERSION` exists, is a single semver line, and equals the newest `## X.Y.Z — date` release header in `_LOUIE-internals/CHANGELOG.md` — a release cut without a version bump, or a bump without a release, fails. `## Unreleased` may accumulate freely between releases.

### Deliberate omissions

If a surface is ever *supposed* to omit a command, add a `surface-path:command` line to the `EXCLUSIONS` variable at the top of the script. The list is empty by default and should stay short — an exclusion is a documented decision, not a suppressed warning.

### Known limitations

- A command mentioned on *any* listing line of a surface (table row or `cmd` → file bullet) counts as registered — the lint doesn't verify it sits in the primary command table specifically. Prose mentions never count.
- `.bat` scripts are parsed after stripping `echo ` prefixes and `^` escapes; they are not executed (no Windows in the dev loop). Behavioral parity between `.sh` and `.bat` beyond the command list is still a manual review item.
- Doc *descriptions* per command are not compared across surfaces — only presence. Divergent wording is allowed (surfaces legitimately abbreviate).

### Follow-up

The full E-02 design (`framework-evaluation/efficiency.md` § E-02) also sketches a generator that renders the init scripts from per-tool templates. The lint was chosen first: it delivers drift-safety with far less machinery, while the scripts keep real per-tool differences. The generator is parked in `BACKLOG.md` in case the maintenance tax persists.
