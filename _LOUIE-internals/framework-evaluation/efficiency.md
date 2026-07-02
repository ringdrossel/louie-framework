# Efficiency & Mechanics — Deep Design (E-01 … E-05)

Framework-mechanics findings that don't belong to the parallelism or scaling themes but make everything else cheaper, safer, or faster.

## E-01 — Install the agents as real subagents on Claude Code

### The gap, precisely

Every `_LOUIE_/agents/*.md` file begins with Claude Code subagent frontmatter:

```yaml
---
name: nina-the-coder
description: Nina — Full-Stack Implementation Engineer
tools: Read, Glob, Grep, Edit, Write, Bash
model: sonnet
---
```

That is the exact format Claude Code loads from `.claude/agents/`. But `claude-init.sh` only copies commands to `.claude/commands/` — the agents directory is never created, so the frontmatter is dead metadata. Agents run via "read and follow `<agent>.md`" — a persona switch inside one main context.

### Why it's the highest-leverage single change

- **Context isolation is the practical scaling ceiling today.** In a full `louie-feature` run, one context accumulates Tom's whole interview, Sophie's evaluation, Leo's design discussion, Nina's entire implementation trail (every file read, every diff), Max's review rounds, and Ava's test writing. Long features hit compaction mid-chain — where reconstruction quality is at the runtime's mercy. As subagents, each stage starts fresh, seeded by exactly the artifacts LOUIE already produces. **The handoff-file design (`agent-handoffs.md`) is already subagent-shaped** — persistent canonical docs + a compact handoff block is precisely what a fresh context needs. The framework built the interface and never plugged it in.
- **It's the mechanical prerequisite for parallelism.** P-03/P-04/P-07 dispatch concurrent agents; that requires agents *be* dispatchable.
- **It sharpens the artifacts.** When the next agent genuinely cannot see the conversation, anything load-bearing *must* land in the docs — which is the framework's stated philosophy ("the files are the memory," `louie-continue`). Inline persona-switching lets context leak between stages and papers over incomplete handoffs; subagents enforce the discipline the docs already claim.

### Dispatch rules (which stage runs where)

Interactivity is the dividing line — a subagent on most runtimes cannot converse with the user mid-run:

| Stage | Main loop or subagent | Why |
|-------|----------------------|-----|
| Tom (interview, playback, agreement gate) | **Main loop, always** | Pure conversation |
| Sophie — first run / proposal gate | Main loop | Conversational gate |
| Sophie — subsequent-run eval, evaluate/import scans | Subagent OK | Read-only analysis; returns eval + handoff; a material change returns `paused:` (deviation tripwire) |
| Leo — proposal discussion | Main loop | Conversational gate |
| Nina (implement, bugfix, apply loops) | Subagent (unattended stretches); main loop in manual mode | Work stage |
| Max (review, auto-fix loop driver) | Subagent OK | Read-only; the fix rounds dispatch Nina subagents |
| Ava | Subagent OK | Work stage |
| Ivy | Main loop | Conversational by nature |

Inline read-and-follow remains the universal fallback (all other runtimes) and the manual-mode default even on Claude Code — this is an upgrade path, not a fork. The rules live in the execution guideline (P-02); the agent files themselves don't change behaviorally.

### Mechanics

- `claude-init.sh` / `.bat`: also `mkdir -p .claude/agents` and copy `_LOUIE_/agents/*.md` there. Idempotent like the command copy; `louie-update-framework` step 4 refreshes them automatically since it re-runs the script.
- Verify frontmatter `tools:` lists are right before shipping (they predate real use): Nina needs `Bash` (has it); Max drives fix rounds by *dispatching Nina*, so he may need task-dispatch capability on runtimes where the loop runs inside him — alternatively the orchestrating command owns the loop and Max stays read-only (cleaner; recommended).
- Watch item: subagent-Sophie writing `_LOUIE-output/` files needs `Write` (her frontmatter is read-only today — correct for eval mode; first-run mode stays in the main loop anyway).

## E-02 — Single-source the init scripts and command tables (live bug found)

### Evidence

- **Past:** the changelog's `louie-continue` rollout entry records a regex that swallowed a newline and merged two table rows across all 12 init scripts — found and fixed one release later.
- **Present:** all six `.sh` scripts currently emit a malformed Key Files block (verified 2026-07-02, e.g. `claude-init.sh:82`):

  ```
  - `_LOUIE_/guidelines/interaction-guidelines.md` — how to ask the user to choose- `_LOUIE_/agents/` — agent definitions
  ```

  — two bullets merged (missing newline), plus a stray blank line above. Same bug class, second occurrence. `.bat` variants not yet checked — do so when fixing.

Root cause both times: **every command/file addition hand-edits ~17 surfaces** — 12 init scripts (6 tools × sh/bat) + command tables in root `CLAUDE.md`, `README.md`, `ai-workflow.md`, `project-setup.md`, and the init scripts' embedded CLAUDE.md/AGENTS.md sections. The changelog shows nearly every entry ends with "…and all six init scripts (× sh/bat)". That's the framework's largest maintenance tax and its most reliable bug generator.

### Recommendation

Two levels; the first is the real fix, the second the minimum viable one:

1. **Generator** (`_LOUIE-internals/tools/generate-distribution.sh` or a small Node/Python script): the command list, one-line descriptions, and Key Files block live once (either a manifest `_LOUIE-internals/commands-manifest.md`, or better, parsed straight from each `_LOUIE_/commands/*.md` — the H1 + first sentence already are the name + description). The script renders the per-tool init scripts from per-tool templates (the scripts differ only in target paths and context-file name) and rewrites the marker-delimited table sections of the four docs. Init scripts become build artifacts; humans stop editing them.
2. **Consistency lint** (`check-consistency.sh`): extracts the command list from all 17 surfaces and diffs them; validates every path referenced in framework docs exists; greps for the merged-bullet pattern (`^- \`.*\` — .*- \`` ). Add "run the lint before committing" to `_LOUIE-internals/README.md` authoring rules.

Both are framework-repo-only tooling — nothing ships downstream, so the "no build step" property of the distributed framework is untouched. Fix the live merged-bullet bug in the same change regardless of which level lands.

## E-03 — Version the framework

### The gap

`CHANGELOG.md` is one ever-growing `## Unreleased` section; downstream copies carry no version marker at all. Consequences:

- `louie-update-framework` step 5 ("show what changed") has no delta basis — it can only diff files and guess.
- Migrations key off filesystem heuristics ("old layout detected") because "coming from version < X" is inexpressible. Works for the layout change; won't generalize (e.g. a template format change leaves no filesystem fingerprint — the BACKLOG's template-versioning item is this same gap).
- Bug reports/support ("which LOUIE are you on?") have no answer.

### Recommendation

- **`_LOUIE_/VERSION`** — single line, semver. Ships with the copy (it's inside `_LOUIE_/`), so every downstream project is stamped. Major = breaking artifact-shape changes (per-feature folders would have been 2.0), minor = new commands/features, patch = fixes.
- **Cut releases in `CHANGELOG.md`:** current Unreleased content becomes the first tagged release section (`## 1.0.0 — 2026-07-XX`); tag the repo to match. Keep entry style unchanged.
- **`louie-update-framework`:** read local VERSION before replacing, read pulled VERSION, print the CHANGELOG sections in between as the "what changed" report, and run any migrations whose trigger version falls in the gap (layout heuristics stay as fallback for pre-VERSION copies).
- **Hook for later:** template versioning (BACKLOG) becomes "templates changed in 1.3 — docs created before that may need migration," which is only expressible once VERSION exists.

Bump discipline belongs in the E-02 tooling (lint fails if CHANGELOG gained a release with no VERSION bump, and vice versa).

## E-04 — The `model: sonnet` pin

All seven agents pin `model: sonnet`. Today it's inert (E-01); the moment agents install as subagents it activates, with two problems:

1. **Silent downgrade.** A user running a stronger session model gets sonnet-quality output from Sophie's architecture decisions and Max's reviews — the two most judgment-heavy stages — without being told. LOUIE's own philosophy is "ask, don't guess"; silently substituting a weaker model violates its spirit.
2. **Staleness.** Model names age; a pinned name in seven files is a drift liability with no owner (E-03's release process is the natural review hook, but inheriting avoids the problem entirely).

**Recommendation:** drop the `model:` key from all seven agents — subagents then inherit the session model, which matches user expectation. If cost-tiering is ever wanted, do it deliberately: document in `core.md` which stages tolerate a cheaper tier (mechanical apply-loops, maybe Ava's boilerplate) and which never should (Sophie, Max), and revisit each release. Land together with E-01 so the frontmatter is touched once.

## E-05 — Downstream migration path for the shape-changing findings

### The question this answers

"If we change the framework per the scaling and parallelism findings, how do *existing* downstream projects' artifacts get updated — does `louie-update-framework` handle it?" Mostly yes — because the framework already has the right propagation channels. This finding pins each shape-changing finding to its channel so implementers don't improvise per-finding.

### The four propagation channels (all existing)

`louie-update-framework` deliberately never overwrites `_LOUIE-output/`. Changes reach downstream projects through:

1. **Wholesale `_LOUIE_/` replace** — agents, commands, guidelines, templates. Behavior changes apply automatically on the next run.
2. **Step-5 new-canonical-output bootstrap** — "offer to bootstrap, never silently create." Precedent: `runbook.md` retrofit.
3. **Step-6 detect-and-offer-migration** — filesystem detection handing off to `louie-migrate`. Precedent: the flat→per-feature layout migration.
4. **`louie-doc` reconcile pass** — self-heals mechanical index formats. Precedent: legacy three-table overview → single-table conversion.

### Channel mapping

| Finding | Channel | Existing-project impact |
|---|---|---|
| P-02, P-03, P-05, P-06, S-05 | 1 | None — behavior applies on next run |
| E-01 (subagent install) | 1 (step 4 re-runs init scripts) | None |
| P-01 (plan annotations) | 1 (template) + **lazy backfill rule** | Old docs stay unannotated; absent annotations = sequential |
| P-04 (`Depends on` column) | 4 | One reconcile run adds the column |
| S-02 (codebase map) | 2 | Bootstrap offered for large projects (Sophie generates) |
| S-01 (architecture split), S-03 stage 3 | 3 — new detection case: `architecture.md` over threshold → offer split | Offered, user-gated, one-way |
| S-04 (chunked evaluate + smart-merge) | 1 | Smart-merge protects existing `evaluation/` statuses on first rescan |

### The two rules to codify

1. **Lazy backfill for P-01 — never heuristic rewriting.** Completed features are never annotated retroactively (nothing will re-execute them); in-flight features get annotated the next time Nina or `louie-extend` touches them. A missing annotation degrades to sequential execution — today's exact behavior — so un-migrated docs are *safe*, not broken. This follows the layout migration's own precedent: no backfill of bugfixes from Change History, because "noisy data is worse than incomplete data." The degradation rule ("absent annotations = sequential, always") must be written into the P-01 spec itself, not just here.
2. **Version-gated migrations via E-03.** Step 6's filesystem heuristics happened to work for the layout change but can't express "your feature docs predate the annotation format." With `_LOUIE_/VERSION` shipped, update-framework compares local vs. pulled version and knows exactly which migrations apply — another reason E-03 sits early in the application order, before any shape-changing finding lands.

### Implementation checklist (small by design)

- `louie-update-framework.md`: add the architecture-size case to step 6's detection list; add `codebase-map.md` to step 5's new-canonical-output check.
- `louie-migrate.md`: add the architecture-split migration case (content moves, cross-reference rewrite per the existing migrate algorithm).
- `louie-doc.md`: reconcile pass adds/repairs the `Depends on` column.
- P-01 spec: the sequential-degradation rule.
- Each shape-changing finding, when applied, ships its migration hook in the same release (E-03 version bump ties them together).

## Not Findings (checked and fine)

For completeness, mechanics examined and deliberately *not* flagged:

- **Persona/voice overhead** (introductions, first-person style) — negligible tokens, real UX value; keep.
- **Two-turn gate round-trip cost** — the extra turn is the price of the user actually seeing what they approve; the evaluate-walkthrough carve-out already handles the high-frequency case.
- **Command file length** (`louie-feature.md` ~130 lines with Auto-Pilot) — well within one read; lazy-loading contains it.
- **Runbook caps** (Debugging ~10 rows) — the discipline is right and self-pruning; no scale change needed.
- **Handoff-block duplication** across canonical docs — it's the subagent seeding interface (E-01); the redundancy is load-bearing.
