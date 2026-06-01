# Branch Mode

**Audience:** AI assistants working on the LOUIE framework. Design notes for the `branch-mode` feature — a per-project setting that controls whether `louie-feature` creates a branch per feature.

## Problem

Earlier framework guidance pushed "all work happens on a feature branch" and "never commit directly to `main`." For solo developers, prototypes, and projects with no branch protection, that is friction: a branch per feature plus a merge gate buys nothing when one person commits straight to `main` all day. The user wanted the default flipped — work on the current branch, no automatic branching — while keeping a branch-per-feature workflow available for anyone who wants it.

## Modes

Two project-wide modes, default `current`:

| Mode | Behavior |
|------|----------|
| `current` | Work on the current branch (including `main`). No auto-branch, no prompt. The default. |
| `ask` | At the start of each new feature, ask whether to create `feature/<name>` or stay put. |

**Default:** `current`. Deliberately silent — the whole point of the change is that LOUIE stops creating branches and stops asking unless told to. A branch is only ever created when the user explicitly asks (in any mode) or picks "yes" under `ask` mode.

Scope is **`louie-feature` only** (per the change request). `louie-extend` / `louie-update` / `louie-bugfix` always run on the current branch and are not gated by this setting.

## Storage

Persisted in `_LOUIE-output/runbook.md` under a `## Branch Mode` section, placed right after `## Review Mode`:

```markdown
## Branch Mode

**Mode:** `current` | `ask`
**Set:** YYYY-MM-DD via louie-setup (or louie-branch-mode)
```

Same rationale as Review Mode for living in the runbook: per-project, tool-agnostic, already in the agents' context, conceptually an "operational knob." Not `CLAUDE.md`/`AGENTS.md` (tool-specific), not a new `preferences.md` (one more file).

## New command: `louie-branch-mode`

Shows the current mode and asks the user to confirm or change it. Updates the runbook in place. Idempotent.

## Relationship to the removed "never commit to `main`" rule

This change retired the framework-dev Critical Rule *"Never commit directly to local `main`. All work happens on a feature branch."* (root `CLAUDE.md` only — it never shipped in the init-script Critical Rules). The distributed *"Never merge to `main` without approval"* rule is kept: it still governs branch modes, and is simply inert in `current` mode where there is no branch to merge. `coding-guidelines.md` § Git Discipline was reworded so branching is described as Branch-Mode-governed rather than mandatory.

## Files touched (implementation)

Framework internals:
- `_LOUIE-internals/branch-mode.md` (this file) — design
- `_LOUIE-internals/README.md` — index row
- `_LOUIE-internals/CHANGELOG.md` — Unreleased entry

Distributed framework files:
- `_LOUIE_/commands/louie-branch-mode.md` — **new command**
- `_LOUIE_/commands/louie-feature.md` — branch-handling step that reads the mode
- `_LOUIE_/commands/louie-setup.md` — records the default (non-interactive; default is "don't ask")
- `_LOUIE_/templates/runbook-template.md` — new `## Branch Mode` section
- `_LOUIE_/guidelines/coding-guidelines.md` — Git Discipline reworded
- `CLAUDE.md` (root) — remove the "never commit to `main`" rule; add command to table
- `README.md` — add command to table
- `_LOUIE_/workflow/ai-workflow.md` — add command to the command tables
- `_LOUIE_/setup/project-setup.md` — command table row
- the six `*-init.sh/.bat` scripts — command lists

## Out of scope

- A third "always auto-branch every feature" mode. The request collapsed to two modes (default-no-ask vs. ask-per-feature); branch-on-demand covers anyone who wants a branch.
- Branch-mode gating for `louie-extend` / `louie-update` / `louie-bugfix`.
- Auto-naming schemes beyond `feature/<feature-name>`.
