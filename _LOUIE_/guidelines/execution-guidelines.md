# Execution Guidelines

How LOUIE work is executed on different runtimes: when independent work may run concurrently, and what every runtime falls back to. Companion to `interaction-guidelines.md` (which governs how to *ask*; this file governs how to *run*). Read by orchestrating commands (`louie-feature`, `louie-extend`, `louie-bugfix`, `louie-update`) and by Nina before implementation.

The data this file acts on is the work-package annotations on `feature.md` Implementation Plan phases — `[Depends: … | Files: …]`, defined in `_LOUIE_/templates/feature-template.md` § Implementation Plan. The annotations are plain markdown that every runtime can read; concurrency is an *optional execution strategy* on top.

## Capability Check

Ask one behavioral question about your runtime — not "which product is this":

> Can I dispatch a subagent or background task that works independently on its own context and returns a result to me?

- **Yes** → you are a *capable* runtime: you may run independent work packages concurrently, per the dispatch rules below.
- **No / unsure** → run sequentially (next section). When unsure, sequential — it is always correct.

Known answers today: **Claude Code — yes** (native subagents; `claude-init.sh/.bat` installs the LOUIE agents to `.claude/agents/`, so `nina-the-coder`, `max-the-reviewer`, `ava-the-tester` etc. are directly dispatchable). Cursor, Codex CLI, Gemini CLI, opencode, pi: treat as **no** unless the runtime documents such a mechanism. The check is phrased behaviorally so a new or upgraded runtime slots in without a framework change.

## The Sequential Baseline

Without capability (or in manual mode, or when annotations are absent): execute work packages **sequentially, in dependency order, preferring the order written**. This is not a degraded mode — it is the baseline every project must remain correct under. A plan that only works when run in parallel is a broken plan.

## Dispatch Rules (capable runtimes)

Concurrency lives strictly inside **unattended stretches** — under auto-pilot semantics, after the plan-agreement gate, before the pre-merge summary. Manual mode is sequential, always: blocking gates punctuate the chain, and there is no unattended stretch to parallelize.

### Which stage runs where

Interactivity is the dividing line — a subagent cannot converse with the user mid-run:

| Stage | Main loop or subagent | Why |
|-------|----------------------|-----|
| Tom (interview, playback, agreement gate) | **Main loop, always** | Pure conversation |
| Sophie — first run / proposal gate | Main loop | Conversational gate |
| Sophie — subsequent-run eval, evaluate/import scans | Subagent OK | Read-only analysis; returns the eval + handoff; the orchestrator applies any doc updates she proposes |
| Leo — proposal discussion | Main loop | Conversational gate |
| Nina (implement, bugfix, apply loops) | Subagent in unattended stretches; main loop in manual mode | Work stage |
| Max (review) | Subagent OK | Read-only; returns the verdict; the orchestrating command owns the auto-fix loop (dispatches Nina rounds) and writes the Change History line from Max's result |
| Ava | Subagent OK | Work stage |
| Ivy | Main loop | Conversational by nature |

**Inline read-and-follow remains the universal fallback** and the manual-mode default on every runtime, Claude Code included. Subagent dispatch is an upgrade path, not a fork — the agent files behave identically either way.

### Seeding a subagent

A dispatched agent starts with a fresh context. Seed it with exactly what the handoff protocol already produces: the feature folder path (`feature.md`, `requirements.md`, `decisions.md`), the specific phase/task and its `Files:` scope, and the standard context list from the agent's own Context section. The handoff blocks exist precisely so a fresh context can start cold — if a subagent needs something that isn't in the artifacts, that's a handoff gap to fix in the docs, not a reason to pass chat history.

## Hard Rules (both modes)

1. **Gates serialize.** Concurrency exists only between gates, never across one. Two simultaneous dialogs is never acceptable.
2. **Disjoint write scopes only.** Never run two packages whose `Files:` sets overlap. Overlap → sequential. Disjointness is declared, not discovered — no merge machinery, no conflict resolution.
3. **Integration phases always run alone** — after the packages they depend on, never in parallel with anything.
4. **A package that needs user input pauses.** A subagent returns the question (or `paused: <what diverged>` for a deviation-tripwire hit) instead of a result; the orchestrator surfaces it. It does not improvise an answer.
5. **Absent annotations = sequential in written order.** Unannotated plans are valid, never a blocker (see the degradation rule in `feature-template.md`).
