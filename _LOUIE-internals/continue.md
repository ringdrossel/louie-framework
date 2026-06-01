# Continue

**Audience:** AI assistants working on the LOUIE framework. Design notes for `louie-continue` — resume in-progress work after a break/restart.

## Problem

A user stops mid-feature, restarts the machine, opens a fresh session, and wants to pick up where they left off — ideally without manually re-explaining what was happening. The naive ask is "find the chat and continue it."

## Why not "find the chat"

A LOUIE command is prompt-only — instructions the model follows inside the *current* session. It cannot read past chat transcripts or spawn a resumed session of itself. Native session-resume exists in some runtimes (`claude --resume`, opencode history) but is user-invoked harness functionality, not driveable from a markdown command, and not cross-tool. So chat-recovery is out as a dependency.

## Why artifacts + git is the right base

LOUIE already persists all durable state in `_LOUIE-output/` + git. Those files survive restart, tool switch, and machine change — strictly more robust than chat history. `louie-continue` reconstructs "where you stopped" from them:

- **Overview `Status: In Development`** — primary anchor for feature work (set by `louie-feature` when Nina starts). Reuses the status lifecycle added in the overview-currency change.
- **Git** — branch, uncommitted diff, recent commits. Richest "where did I stop" signal and the anchor for bugfix/extend (which don't flip the overview to In Development).
- **`feature.md` breadcrumbs** — Status checkboxes, Implementation Plan phase ticks, Open Questions, last Change History line, Handoff sections.

## Design decisions

- **No new state file (infer, don't store).** The chain position is derived from existing breadcrumbs + git, not from a `Next:` pointer each agent must maintain. A stored pointer would add bookkeeping to every step and go stale; inference self-heals.
- **Detect features *and* bugfix/extend.** Features anchor on the overview status; bugfix/extend anchor on git + a recently-added bugfix doc / appended requirements. Both kinds resume.
- **Native chat-resume is suggested, never required.** On Claude Code, `louie-continue` points the user at `claude --resume` to optionally restore the conversation, after it has already rebuilt state from files.
- **Multi-candidate → structured choice.** Uses `interaction-guidelines.md` when more than one in-progress target exists.
- **No new agent.** It's an orchestrator: read state, then hand off to the existing chain (`coder.md`, `louie-bugfix.md`, …) through normal gates.

## Files

- `_LOUIE_/commands/louie-continue.md` — the command.
- Registered in `CLAUDE.md`, `README.md`, `_LOUIE_/workflow/ai-workflow.md` (new scenario), `_LOUIE_/setup/project-setup.md`, all six init scripts (× sh/bat), internals index.

## Out of scope

- Recovering or summarizing past chat transcripts.
- A cross-tool session-resume abstraction.
- A persisted per-step progress marker (deliberately inferred instead).
