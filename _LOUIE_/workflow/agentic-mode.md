# Agentic Mode

**Audience:** autonomous agents (orchestrators, unattended harnesses) operating LOUIE without a human who can answer prompts in-session. Read this once before invoking any `louie-*` command autonomously.

If a human **is** driving this session — even through you — do not use agentic mode. The normal interactive commands apply.

## When agentic mode applies

Use agentic mode when **no human can answer a prompt during this run**. The test is simple: if you raised a structured choice right now, would a person answer it? No → agentic mode.

Declare it explicitly by appending `--agentic` to the command:

```
louie-feature --agentic <task description or spec>
louie-bugfix --agentic <feature> <bug description>
```

LOUIE never infers agentic mode, and it is never stored as a project setting — each invocation declares it. `--agentic` supersedes the auto-pilot resolution order entirely; combining it with `--manual` is a contradiction and stops the run.

## Prerequisites

- The project must be **established**: a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md` exist (Critical Rule #2). If they don't, stop with `status: blocked` — project setup (`louie-setup` / `louie-import`) is human work and never runs agentically.
- You have a task in hand. If your task comes from an external tracker, fetch it via `louie-from-source` (see Composition below) and run the routed command with `--agentic`.

## What your task spec must contain

In agentic mode Tom's interview becomes an **evidential gate**: he maps his checklist against your task input instead of asking questions. Your task spec must answer:

1. **What** — what exactly should be built or changed, with expected inputs/outputs
2. **For whom** — who uses it (a persona sketch is enough)
3. **Done-when** — how success is verified; testable acceptance criteria
4. **Scope edges** — what is explicitly out of scope

How gaps are handled:

- **Low-stakes gaps** (a default value, a naming choice, an edge-case policy that any reasonable pick satisfies) → the run proceeds and records each as an explicit entry under `requirements.md` § Assumptions.
- **Scope-defining gaps** (what the thing fundamentally is, who it's for, what done means) → the run **halts** with `status: needs-human` and the unanswered questions in the run report. LOUIE does not guess scope.

Write task specs to pass this gate: a spec that answers the four points above runs straight through.

## Routing: task shape → command

| Your task is... | Run |
|-----------------|-----|
| A new capability the project doesn't have | `louie-feature --agentic` |
| A change/addition to an existing feature | `louie-extend --agentic` |
| A small contained change (< 50 lines) | `louie-update --agentic` |
| A defect — behavior diverges from documented intent | `louie-bugfix --agentic` |

When unsure between `update` and `extend`, pick `extend` — `update`'s 50-line escalation would halt the run anyway. This table routes tasks you already have in hand; adapter-fetched tasks carry their own `louie_type` routing (see Composition).

## What happens during the run

The command runs its full chain with auto-pilot implied `on` — Tom (evidential gate) → Sophie → Leo (if UI) → Nina → Max (`auto-fix-critical` loop) → Ava — and these gate resolutions:

- **Recommended defaults auto-apply** and are recorded in the run report (Sophie's minimal changes, Leo's UI direction).
- **The deviation tripwire halts instead of asking.** If the run materially diverges from the task spec (non-trivial architecture change, undiscussed scope, a fundamentally different UX, `update` crossing 50 lines), it stops with `status: needs-human` and the fork written into the run report.
- **Branch mode `ask` resolves to `current`** — no branch is created unless your invocation explicitly requests one.
- **A scope split** (the task is really several features) builds the **first** feature and lists the rest as follow-up tasks in the run report.

## Hard limits (never overridden)

- **Never merges.** The run always ends with work committed but unmerged. The merge decision belongs to a human (Critical Rule #3).
- **Never runs `louie-setup` / `louie-import`.**
- **Never creates a branch on its own.**
- **Halts rather than guesses** on scope-defining ambiguity and material deviations.

## What comes back

Every agentic run writes a **run report**:

- Feature-scoped runs: `_LOUIE-output/implementations/<feature>/run-report.md`
- Cross-cutting bugfixes: `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>-run-report.md`

The report starts with a machine-readable header — branch on `Status`:

| Status | Meaning | Your next move |
|--------|---------|----------------|
| `completed` | Chain finished through Ava; work committed, unmerged | Hand to a human for review + merge decision |
| `needs-human` | A decision fork (tripwire, scope-defining gap); resumable | Surface the `Pending decision` line to a human; resume after it's answered |
| `blocked` | Environmental/hard failure (missing prerequisites, tests can't run) | Escalate; not resolvable by re-running |

The prose body is the pre-merge summary for the human reviewer: Tom's playback + assumptions, Sophie's decision, Leo's direction, Max's rounds, Ava's verdict, files changed, follow-up tasks. Template: `_LOUIE_/templates/run-report-template.md`.

## Resuming

A `needs-human` run is left in a resumable state. Once the pending decision is answered, run `louie-continue <feature>` (interactively or with `--agentic` plus the answer in the invocation) — it reconstructs the position from artifacts + git; the run report is one more breadcrumb.

## Composition with source adapters

`louie-from-source` (fetching tasks from an external tracker) and agentic mode are orthogonal layers that compose:

1. Fetch the task via `louie-from-source` — the adapter supplies `louie_type` routing and a concept document.
2. Run the routed command with `--agentic`; the concept is the task spec for the evidential gate.
3. Mirror the run-report `Status` back to the source system (`update_status`): `completed` → your "done/review" state, `needs-human`/`blocked` → your escalation state.

See `_LOUIE_/adapters/louie-source-adapter.md` and `_LOUIE_/commands/louie-from-source.md`.
