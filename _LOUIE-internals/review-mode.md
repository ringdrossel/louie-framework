# Review Mode

**Audience:** AI assistants working on the LOUIE framework. Design notes for the `review-mode` feature — a per-project setting that controls whether `louie-review` stops for human approval or auto-hands fixes to Nina in a loop.

## Problem

Today `louie-review` always ends with Max presenting findings and asking "Want me to apply the fixes?" For trusted projects (solo work, prototypes, well-tested codebases) this prompt is friction — the user *always* says yes, then waits for Nina to start. The user wants an opt-in mode where Critical + Should-fix items auto-flow to Nina and the cycle loops until the review is clean.

## Modes

Three project-wide modes, set during `louie-setup` and changeable later:

| Mode | Behavior |
|------|----------|
| `manual` | Current behavior. Max presents the verdict and asks before any code changes. |
| `auto-fix-critical` | Max auto-hands `Critical` + `Should-fix` to Nina. Nina applies, re-runs typecheck/tests/build, hands back to Max. Loop until clean or cap hit. `Suggestions` are surfaced at the end and need approval. |
| `auto-fix-all` | Same loop as `auto-fix-critical`, but `Suggestions` are also auto-applied. Heavy-handed; intended for solo/throwaway projects. |

**Default:** none — Tom asks during `louie-setup` and the answer is stored project-wide. No silent default to avoid accidentally enabling auto-fix on a project where the user expected the gate.

## Storage

Persisted in `_LOUIE-output/runbook.md` under a new `## Review Mode` section:

```markdown
## Review Mode

**Mode:** `manual` | `auto-fix-critical` | `auto-fix-all`
**Loop cap:** 3 (max review→fix→review rounds before falling back to manual)
**Set:** YYYY-MM-DD via louie-setup (or louie-review-mode)
```

Why runbook and not architecture/preferences/CLAUDE.md:
- **Runbook** is per-project, tool-agnostic, already-loaded by review agents, and conceptually about "how this project operates day-to-day" — the review mode fits.
- **Not `CLAUDE.md`/`AGENTS.md`** — those are tool-specific; the same project might be opened in Claude Code one day and Codex the next.
- **Not a new `preferences.md`** — one more file is overhead; runbook already covers "operational knobs."

## Per-call override

`louie-review` accepts an optional first-arg mode that overrides the project setting for that one invocation:

```
louie-review                  → use project setting (or manual if unset)
louie-review manual           → one-time manual
louie-review auto             → alias for auto-fix-critical
louie-review auto-fix-critical
louie-review auto-fix-all
```

The override does **not** mutate the runbook. To change the persistent setting, the user runs `louie-review-mode`.

## New command: `louie-review-mode`

Shows the current mode and asks the user to confirm or change it. Updates the runbook in place. Idempotent — re-running with the same answer is a no-op.

UX sketch:
```
Current review mode: auto-fix-critical (set 2026-05-19)

Change to:
  1) manual              — Max presents findings, asks before fixing
  2) auto-fix-critical   — auto-fix Critical + Should-fix; loop; surface Suggestions
  3) auto-fix-all        — auto-fix everything; loop
  4) keep current

>
```

## The loop (auto modes)

1. Max produces the standard verdict (Critical / Should-fix / Suggestions).
2. If the in-scope severity buckets are empty → done, success.
3. Else: Max writes a short handoff block (which items, which files) and invokes Nina.
4. Nina applies fixes, runs typecheck / tests / build per `_LOUIE-output/tech-stack.md`. On red, she does **not** loop on her own — she hands back to Max with the failures noted.
5. Max re-reviews the diff. Goto 2.
6. **Loop cap:** 3 rounds. If hit, fall back to `manual` for the remainder — surface the unresolved diff and let the user decide. Cap is configurable per-project in the runbook (`Loop cap: N`).
7. **Regression guard:** if Round N+1 introduces a new Critical that wasn't in Round N, stop immediately and surface — that's a sign Nina is making things worse, don't keep going.
8. Final entry in the feature's `## Change History`: one line summarizing rounds + outcomes, e.g. `2026-05-19: Max review (auto-fix-critical) — 3 rounds, 1 critical + 4 should-fix resolved, 2 suggestions deferred`.

## Files touched (implementation plan)

Framework internals:
- `_LOUIE-internals/review-mode.md` (this file) — design
- `_LOUIE-internals/BACKLOG.md` — strike entry once landed
- `_LOUIE-internals/CHANGELOG.md` — Unreleased entry

Distributed framework files:
- `_LOUIE_/commands/louie-review.md` — branch on mode, accept override arg
- `_LOUIE_/commands/louie-review-mode.md` — **new command**
- `_LOUIE_/commands/louie-setup.md` — Tom asks the question during setup
- `_LOUIE_/commands/louie-import.md` — same question during import (default to `manual` if user skips, since imported projects are higher-risk)
- `_LOUIE_/agents/analyst.md` — Tom's question + how he records the answer
- `_LOUIE_/agents/reviewer.md` — Max reads runbook, branches on mode, manages the loop, enforces cap + regression guard
- `_LOUIE_/agents/coder.md` — Nina's "address review findings" handoff input shape
- `_LOUIE_/templates/runbook-template.md` — new `## Review Mode` section (placeholder when not yet set)
- `CLAUDE.md` (root of this repo + via init scripts) — add `louie-review-mode` to the command table
- `README.md` — add `louie-review-mode` to the command table
- `_LOUIE_/setup/project-setup.md` — mention the new question

Downstream sync:
- The six `*-init.sh/.bat` scripts append a LOUIE section that lists commands. They need the new command in their lists too, otherwise downstream `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` / `.cursorrules` won't know about it after running the init script.

## Open design questions

1. **Should auto modes still pause for Suggestions in `auto-fix-critical`?** Current proposal: yes — Suggestions are surfaced post-loop and need approval. Alternative: skip Suggestions entirely in auto mode and let the user run a separate pass.
2. **What does Nina do on test failure mid-loop?** Current proposal: hand back to Max with failures noted; Max decides next step. Alternative: Nina tries one self-repair pass before bouncing. I lean against — keeps the loop boundaries clean.
3. **How does this interact with `louie-review-doc`?** That command is already "review + fix + docs in one flow." Proposal: in `manual` mode, `louie-review-doc` is unchanged. In auto modes, it becomes the natural default — `louie-review` and `louie-review-doc` collapse to nearly the same behavior, differing only in whether docs are updated. May want to deprecate `louie-review-doc` in a future version, but keep for now.

## Out of scope

- Per-severity overrides (e.g., "auto-fix Critical, ask for Should-fix"). Three modes is enough.
- Per-call regression guard tuning. Cap is project-wide.
- Telemetry / metrics on how often the loop runs.
