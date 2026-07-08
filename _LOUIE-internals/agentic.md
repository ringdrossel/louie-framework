# Agentic Mode

**Audience:** AI assistants working on the LOUIE framework. Design notes for `agentic mode` — LOUIE driven by an autonomous agent (an orchestrator like OpenClaw, Hermes, or a custom harness) instead of a human working interactively with an AI runtime.

**Status: implemented 2026-07-08.**

## Problem

LOUIE assumes a human on the other side of every gate: Tom interviews *someone*, structured choices are answered *by someone*, the pre-merge summary is read *by someone watching the chat*. But LOUIE is also used inside autonomous agents that pick up a task, run unattended, and report back. In that topology there is nobody to answer a prompt mid-run — every blocking gate is a deadlock, and every streamed narration is written to nobody.

The goal: let an autonomous agent operate the existing commands end-to-end **without forking the framework and without weakening the human experience**. The human does not disappear — they move to *after* the run: they review the result, discuss fixes, and drive follow-up changes (interactively or through the agent).

## The mental model: auto-pilot with the counterpart swapped, checkpoints made durable

Agentic mode is **not** a new chain. It is three moves on top of what exists:

1. **Auto-pilot implied `on`** for the run (feature / extend / update / bugfix) — same mechanism as the effective review floor: a per-run value, never written to the runbook.
2. **The gate counterpart is the driving agent, not a human.** Tom's agreement gate survives but becomes *evidential* (below). Everything auto-pilot already auto-applies stays auto-applied.
3. **Checkpoints become durable artifacts instead of chat.** The narration and the terminal pre-merge summary land in a run report with a machine-readable status, because nobody is watching the stream. The human reads it later; the orchestrator branches on the status field.

Every gate keeps exactly one of three resolutions in agentic mode — no gate is deleted:

| Resolution | Meaning |
|------------|---------|
| **auto** | Take the recommended default, record it in the run report |
| **halt-and-report** | Stop cleanly, write the open fork into the run report (`status: needs-human`), leave the work resumable via `louie-continue` |
| **forbidden** | The action never happens in agentic mode (merge, `louie-setup`) |

## Declaration, never inference

The caller declares agentic mode explicitly: `louie-<command> --agentic <task>` (or the orchestrator's bootstrap prompt states it, which amounts to passing the flag on every call). LOUIE never guesses "this looks like an agent," and there is **no stored "we are agentic" setting** — a runbook flag would leak into a later human session and silently strip its gates, which is the one way this feature could break LOUIE for humans. The runbook stays untouched by agentic mode entirely (no `## Agentic` section in v1; add one only if per-project policy tuning turns out to be needed).

Flag interactions: `--agentic` supersedes the whole auto-pilot resolution order (`--auto`/`--manual`/persistent setting/inline choice) — combining it with `--manual` is a contradiction; stop and say so.

**Prerequisite:** an established project. Critical Rule #2 stands unchanged — no confirmed `architecture.md` + `tech-stack.md`, no agentic run (`status: blocked`, pointing at `louie-setup`/`louie-import` as human work). Humans establish projects; agents operate them.

## The evidential Tom gate

Two topologies exist. **(B)** an orchestrator drives a LOUIE session and answers prompts — Tom's gate works as-is, nothing to design. **(A)** the agent *is* the LOUIE runtime (reads the markdown and executes the chain itself) — Tom's conversation collapses, and an agent playing both Tom and the approver will approve anything. Design for A; B falls out for free.

In topology A the gate stops being conversational and becomes **evidential**: Tom maps his interview checklist (what / for whom / done-when / scope) against the task input the agent was given.

- **Answered by the task** → proceed; the playback is written into the run report instead of spoken.
- **Unanswered, low-stakes** → proceed with an explicit entry under `requirements.md` § Assumptions (a section the human checks first at review).
- **Unanswered, scope-defining** → **halt-and-report**. Never guess the scope. The unanswered questions go into the run report as the pending decision.

This is what keeps the gate from becoming theater: the approval is grounded in evidence the human can audit later, and the "assumption vs. halt" line is the same class of judgment call as the deviation tripwire — when unsure, halt.

The Scope Split Gate (analyst.md § Step 4a) resolves without a prompt: split into per-feature `requirements.md` folders as usual, run the chain for the **first** feature, and list the rest in the run report as follow-up tasks for the orchestrator.

## The run: what changes per stage

Tom (evidential gate) → Sophie → Leo (if UI) → Nina → Max → Ava, i.e. the auto-pilot unattended run with these deltas:

- **Branch mode `ask`** cannot prompt: treat as `current` unless the invocation itself requested a branch (same rule as today's "user already asked for a branch"). Never auto-create.
- **The deviation tripwire fires → halt-and-report**, not pause-and-ask. There is no one to renegotiate the agreement with mid-run; sailing past it would remove the framework's main mid-run safety valve. The fork is written into the run report, the work stays committed/resumable, `louie-continue` picks it up (its artifact+git inference works unchanged; the run report is one more breadcrumb).
- **Max** runs the `auto-fix-critical` floor exactly as under auto-pilot (reuse, don't restate).
- **Narration goes to the run report**, not (only) chat. Auto-pilot's principle "suppress blocking, not visibility" translates to: visibility means durability when nobody is watching.
- **The merge gate is `forbidden`.** The run always ends with work committed and unmerged, Critical Rule #3 untouched. Post-run changes are normal `louie-update` / `louie-bugfix` runs — agent-driven or interactive; the review loop needs no new machinery.
- **Language:** there is no conversation, so the Conversation setting is moot; the run report follows the Documents setting like any artifact.

## The run report

Per-feature home, per core.md conventions: `_LOUIE-output/implementations/<feature>/run-report.md`, overwritten per agentic run (git history keeps prior ones). Cross-cutting bugfixes without a feature folder put it next to the bugfix doc (`_LOUIE-output/bugfixes/<date>-<slug>-run-report.md`).

Machine-readable header first, prose after:

```markdown
# Run Report: <feature>

**Status:** completed | needs-human | blocked
**Command:** louie-feature --agentic
**Date:** YYYY-MM-DD
**Pending decision:** — | <one-line question>   ← only when needs-human
```

- `completed` — chain finished through Ava; ready for human review and the merge decision.
- `needs-human` — a decision fork (tripwire, scope-defining gap); resumable once answered.
- `blocked` — environmental / hard failure (missing prerequisites, tests can't run).

Body = the terminal pre-merge summary made durable: Tom's playback + assumptions made, Sophie's decision, Leo's direction (if any), Max's rounds + deferred Suggestions, Ava's verdict + ship recommendation, files changed, follow-up tasks (e.g. split-off features), and the explicit note that merge is the human's call. The orchestrator branches on the header; the human reads the body.

Escalation channel: the run report **is** the required mechanism. Adapter status-writeback (`update_status(id, "needs-human")` etc.) is an optional layer on top for adapter-fed tasks — see composition below.

## Discovery: how an agent learns all this

Same channel humans' runtimes use — the instruction file the init scripts already append to (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `.cursorrules`). The LOUIE section gains one line:

> Operating autonomously (no human can answer prompts in this session)? Read `_LOUIE_/workflow/agentic-mode.md` before invoking any louie command.

Lazy-loaded, invisible to humans, exactly one hop for agents. Custom harnesses (where the user controls the system prompt) can skip discovery and point at the contract doc directly.

**The contract doc** — `_LOUIE_/workflow/agentic-mode.md`, distributed, written for AI readers — is the single file an agent needs:

- When agentic mode applies and how to declare it (`--agentic`)
- What a task spec must contain to pass the evidential gate (Tom's checklist as input requirements; scope-defining gaps halt the run) — doubles as prompt-authoring guidance for the orchestrator's developer
- Routing table, task shape → command: new capability → `louie-feature` · change to an existing feature → `louie-extend` · < 50 lines → `louie-update` · defect → `louie-bugfix`
- What comes back: run report location, the three statuses, resume via `louie-continue`
- Hard limits: never merge, never `louie-setup`, halt on tripwire

## Composition with source adapters

Orthogonal layers. `louie-from-source` **fetches and writes back** (adapter operations, `louie_type` routing, concept handoff); agentic mode **governs how gates resolve** during the run. An orchestrator working a tracker queue uses both: fetch via the adapter, run the routed command with `--agentic`, let the adapter mirror the run-report status back to the source. An orchestrator with the task already in hand (its own user chat, its own planning) skips the adapter and calls the command directly. The contract doc's routing table and the adapter's `louie_type` table stay separate but cross-referenced — one routes tasks-in-hand, the other routes fetched payloads.

## Files touched (implementation plan)

Framework internals:
- `_LOUIE-internals/agentic.md` (this file) — design
- `_LOUIE-internals/README.md` — index row
- `_LOUIE-internals/BACKLOG.md` — entry (designed, awaiting implementation) → moves to `CHANGELOG.md` when built

Distributed framework files:
- `_LOUIE_/workflow/agentic-mode.md` — **new contract doc** (the only substantial new file)
- `_LOUIE_/templates/run-report-template.md` — **new template**
- `_LOUIE_/commands/louie-feature.md` / `louie-extend.md` / `louie-update.md` / `louie-bugfix.md` — accept `--agentic`; a short `## Agentic` section each, deferring to the contract doc
- `_LOUIE_/agents/analyst.md` — evidential gate (assumption vs. halt rule, Scope Split resolution)
- `_LOUIE_/agents/architect.md` / `designer.md` — tripwire resolution becomes halt-and-report under `--agentic`
- `_LOUIE_/agents/reviewer.md` — one line: agentic implies the same `auto-fix-critical` floor as auto-pilot
- `_LOUIE_/guidelines/interaction-guidelines.md` — third rung on the degradation ladder: no interlocutor → gate-resolution policies + run report
- `_LOUIE_/commands/louie-continue.md` — run report as an additional resume breadcrumb
- `_LOUIE_/adapters/louie-source-adapter.md` + `_LOUIE_/commands/louie-from-source.md` — cross-reference composition
- All six `*-init.sh/.bat` — the one-line discovery pointer in the appended instruction-file section
- `CLAUDE.md` (framework repo, mirrors the downstream section) + `README.md` — the discovery line / a short mention
- `_LOUIE_/workflow/ai-workflow.md` — new scenario; `_LOUIE_/setup/project-setup.md` — mention

No new command: agentic mode is a per-invocation flag, not a stored mode, so there is no `louie-agentic-mode` settings command (deliberate — see Declaration).

## Out of scope

- **Auto-merge.** Critical Rule #3 is non-negotiable in every mode.
- **Agentic `louie-setup` / `louie-import`.** Establishing a project is human work; far riskier design, no demonstrated need.
- **A runbook `## Agentic` policy section** (per-gate tuning of auto vs. halt). Fixed policies in v1; add configurability only when a real project needs it.
- **A push/notification channel to the human.** The run report + orchestrator is the loop; LOUIE stays a markdown framework.
- **Multi-task orchestration** (queues, retries, parallel runs). That is the orchestrator's job; LOUIE handles one command invocation at a time.
