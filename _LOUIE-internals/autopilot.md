# Auto-Pilot

**Audience:** AI assistants working on the LOUIE framework. Design notes for the `auto-pilot` feature — a per-command setting that lets the agent chain run unattended from the moment the user approves the plan through to a pre-merge summary, instead of stopping at every in-flight gate.

## Problem

The full chains (`louie-feature`, `louie-extend`) stop for the user at several gates: the plan confirmation, Sophie's architecture proposal, Leo's UI proposal, and Max's review. For a user who has *already discussed the task thoroughly with Tom and agreed on the approach*, most of those gates are friction — they confirm things that were already settled in the conversation. The user wants to discuss with Tom, approve once, and let the rest build itself, stopping only before merge.

This is **not** "skip the gates." It's "move the human checkpoint to the front (the moment of agreement) and the back (before merge), and let the middle run." The plan still gets written, Sophie still evaluates, Leo still designs, Max still reviews, Ava still tests — they just don't *block* unless something genuinely diverges from what was agreed.

## The mental model: gate at agreement, narrate the run

The key insight that shaped the design: by the time the user and Tom have discussed back-and-forth and agreed on the procedure, `feature.md` is usually a faithful transcription of that conversation — re-approving it is a redundant round-trip. So the human checkpoint **moves earlier**, to the moment of agreement (end of Tom's playback, *before* any document is written). The user approves "write it up and run it from here." `requirements.md` + `feature.md` are then written as the **first step of the unattended run**, not as a separate approval gate.

`feature.md` is never skipped — `louie-extend`, `louie-continue`, and `louie-review` all read it later as the source of truth. It is demoted from "thing you approve" to "thing that's auto-generated."

The middle of the chain still **narrates**: each agent presents its output in chat as it goes (content-first running log). Auto-pilot suppresses the *blocking*, not the *visibility*. This is consistent with the two-turn approval-gate rule (see `_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second) — content is always shown; auto-pilot only removes the choice dialog that would otherwise stop the run.

## What auto-pilot changes vs. preserves

**Turns from blocking gates into narrated steps (when on):**

| Gate | Manual behavior | Auto-pilot behavior |
|------|-----------------|---------------------|
| Plan confirmation (`feature.md`) | Present plan, wait for approval | Pre-approved at the agreement gate; plan written as first unattended step |
| Sophie architecture proposal | Propose changes, wait for approval | Auto-apply *minimal* changes, narrate what changed |
| Leo UI proposal | Propose UX direction, wait for approval | Auto-apply the recommended direction, narrate it |
| Max review | Present findings, ask before fixing | Run the `auto-fix-critical` loop (see Review-mode composition) |

**Preserved as hard stops (always, even on):**

- **Tom's interview + the agreement gate.** This is the front checkpoint. Auto-pilot never skips the conversation — it's *triggered by* approving its outcome.
- **The merge-to-main gate** (Critical Rule #3). Auto-pilot **always stops before merge** and presents a final summary. It never auto-merges.
- **Branch creation** stays governed by branch-mode. Auto-pilot never auto-creates a branch. If branch-mode is `ask`, the branch question is resolved *at the agreement gate* (same checkpoint as plan approval), so there is no mid-run prompt.
- **The deviation tripwire** (below) — if the unattended run materially diverges from what was agreed, it pauses regardless of the setting.

## The deviation tripwire

Auto-pilot trades a series of gates for one front-loaded approval. That bet only holds while the written plan stays faithful to the discussion. When it doesn't, auto-pilot **pauses anyway** and surfaces the fork (content-first, two-turn gate), despite being on.

"Material deviation" — pause when any of these appear during the unattended run:

- **Sophie needs a non-trivial architecture change** — a new boundary, dependency, or pattern, not just mapping the feature onto existing patterns. ("Fits the existing architecture, no changes" → sail through. "This needs a new service / a schema migration / a new external dependency" → pause.)
- **A new implementation phase or scope chunk** surfaces that wasn't part of the discussion.
- **Scope is clearly larger** than the conversation implied. For `louie-update` this reuses the existing 50-line escalation rule — crossing it pauses even under auto-pilot.
- **Leo's UI requires a fundamentally different UX** than what was discussed (e.g. the agreed flow turns out to need a multi-step wizard nobody mentioned).

Honest about the cost: the tripwire is a **judgment call**, not a crisp boundary. It will occasionally pause when the user would have been fine, or sail through something they'd have wanted to see. This is the same class of judgment LOUIE already asks agents to make (the 50-line escalation in `louie-update`, Tom's Scope Split Gate) — acceptable, not novel.

## Review-mode composition

The Max stage is *already* automatable via review-mode (`manual` / `auto-fix-critical` / `auto-fix-all`). Auto-pilot must compose with it, not reinvent it.

Rule: **auto-pilot implies an effective review floor of `auto-fix-critical` for that run.** If the project's review-mode is already `auto-fix-all`, that stays (the floor never downgrades). If it's `manual`, auto-pilot lifts it to `auto-fix-critical` for the run only.

This is a **per-run effective value** — auto-pilot does **not** mutate the runbook's `## Review Mode` setting. The loop cap, regression guard, and test-failure protocol in `reviewer.md` apply unchanged. After the loop, leftover Suggestions (in `auto-fix-critical`) fold into the final pre-merge summary rather than prompting mid-run.

## Per-command leverage (and the update/bugfix thinness)

Auto-pilot is a per-command setting (feature / extend / update / bugfix) because the user asked to decide per command. But its leverage differs sharply:

- **`feature` / `extend`** — full leverage. Tom agreement → unattended Sophie → Leo → Nina → Max → Ava. This is where auto-pilot earns its keep.
- **`update` / `bugfix`** — thin. Neither has a Tom/Sophie/Leo gate. `louie-update` is already the fast lane (implement → slim Max → spec sync); `louie-bugfix` is Nina → Max → Ava. The only gate auto-pilot removes is the Max review pause, which is **already** review-mode's job. So auto-pilot here ≈ "run the Max loop unattended." Kept for predictability and a uniform mental model ("I can set auto-pilot per command"), but documented as thin so nobody expects more. For `update`/`bugfix`, the agreement gate doesn't apply (there's no plan to approve) — auto-pilot simply means the review loop runs without the end-of-review approval prompt, and the terminal pre-merge summary still applies.

## Triggers (three layers)

The gate-at-agreement is the **mechanism**; the other two just decide whether the user gets asked.

1. **Inline choice at the agreement gate** — the core mechanism. When auto-pilot is *off* for the command, Tom's playback ends with a structured choice: **Approve & continue step-by-step** / **Approve & auto-pilot the rest** / **Revise the plan**. Works with zero configuration.
2. **Persistent per-command setting** — stored in `runbook.md` `## Auto-Pilot`, managed by `louie-autopilot-mode`. When *on* for the command, the agreement gate **presents the agreement summary and proceeds without a second confirmation** (the discussion was the approval) — it does not re-ask "manual or auto-pilot?". Default **off** for all commands.
3. **Per-call flag** — `louie-feature --auto` / `louie-feature --manual`. One-shot override of the persistent setting for that invocation. Does **not** mutate the runbook (mirrors `louie-review`'s override).

Resolution order for a given run: `--auto`/`--manual` flag > persistent setting > inline choice at the gate.

### On-mode pause decision

When auto-pilot is persistently **on**, the agreement gate proceeds **without** a second confirmation. Rationale: a second "go ahead" would re-introduce the exact gate auto-pilot exists to remove. The agreement summary is still presented (content-first), so the user sees what they agreed to — they just aren't asked to re-confirm. The deviation tripwire remains the safety valve.

## Storage

Persisted in `_LOUIE-output/runbook.md` under a new `## Auto-Pilot` section:

```markdown
## Auto-Pilot

Controls how far each command runs unattended after you approve the plan. See `_LOUIE_/commands/louie-autopilot-mode.md` for full details.

**feature:** off
**extend:** off
**update:** off
**bugfix:** off
**Set:** YYYY-MM-DD

Valid values per command: `on` / `off` (default `off`). Per-call override: `louie-<command> --auto` / `--manual`. Auto-pilot stops before merge, never auto-creates a branch, and pauses anyway if the written plan materially diverges from what you agreed.
```

Why runbook and not architecture/preferences/`CLAUDE.md` — same rationale as review-mode and branch-mode: the runbook is per-project, tool-agnostic, already read by the chain agents, and the natural home for "how this project operates day-to-day." It sits alongside `## Review Mode` and `## Branch Mode`, placed after `## Branch Mode`, before `## Debugging`.

## New command: `louie-autopilot-mode`

Shows the current per-command settings and lets the user change them. Updates the runbook in place. Idempotent. UX mirrors `louie-review-mode` / `louie-branch-mode` but operates on four command toggles rather than one mode value. Because there are four toggles, the command asks which command(s) to change, then the on/off value — see the command file for the exact interaction.

## The terminal checkpoint (pre-merge summary)

Auto-pilot always ends at a single human checkpoint before merge. The summary presents, content-first:

- What was built (feature + phases completed)
- Sophie's decision (no change / what changed and why)
- Leo's UI direction (if applicable)
- Max review outcome (rounds, what was fixed, any deferred Suggestions)
- Ava's test result + ship recommendation
- Files changed
- The explicit merge decision, left to the user (per Critical Rule #3)

If the deviation tripwire fired mid-run, that pause already happened earlier; the terminal summary still applies at the end.

## Files touched (implementation plan)

Framework internals:
- `_LOUIE-internals/autopilot.md` (this file) — design
- `_LOUIE-internals/README.md` — index row
- `_LOUIE-internals/CHANGELOG.md` — Unreleased entry

Distributed framework files:
- `_LOUIE_/commands/louie-autopilot-mode.md` — **new command**
- `_LOUIE_/commands/louie-feature.md` — agreement gate, `--auto`/`--manual`, narrate-don't-block
- `_LOUIE_/commands/louie-extend.md` — same
- `_LOUIE_/commands/louie-update.md` — thin auto-pilot (review loop unattended)
- `_LOUIE_/commands/louie-bugfix.md` — thin auto-pilot (review loop unattended)
- `_LOUIE_/agents/analyst.md` — Tom's agreement gate (inline 3-way choice / proceed when on); setup default note
- `_LOUIE_/agents/architect.md` — Sophie auto-applies minimal changes + narrates + tripwire when on
- `_LOUIE_/agents/designer.md` — Leo auto-applies recommended direction + narrates when on
- `_LOUIE_/agents/reviewer.md` — auto-pilot implies `auto-fix-critical` effective floor
- `_LOUIE_/commands/louie-setup.md` — set `## Auto-Pilot` to all-off (no question, like branch-mode)
- `_LOUIE_/commands/louie-import.md` — same
- `_LOUIE_/templates/runbook-template.md` — new `## Auto-Pilot` section placeholder
- `CLAUDE.md` + `README.md` — command tables
- `_LOUIE_/setup/project-setup.md` + `_LOUIE_/workflow/ai-workflow.md` — mention
- all six `*-init.sh/.bat` — add `louie-autopilot-mode` to the command lists

## Composition with parallel execution (P-03 / P-06)

Auto-pilot's unattended stretches are **the container for all parallel execution** — see `_LOUIE_/guidelines/execution-guidelines.md` § Gate Composition. The composition rules, decided in the framework evaluation (P-06):

- Parallel dispatch happens only between the plan-agreement gate and the pre-merge summary, on capable runtimes. Manual mode is sequential, always — its blocking gates leave no unattended stretch.
- The deviation tripwire keeps working per branch: a subagent that hits it returns `paused: <what diverged>`; siblings run to completion; the orchestrator surfaces the pause content-first (two-turn gate) and dispatches nothing new until it's resolved.
- Narration extends per package (start/finish as results come in) — same "suppress blocking, not visibility" rule.
- **Deliberately no new setting.** Parallelism is an execution strategy inside existing modes, not a mode. If a kill switch is ever demanded, a `parallel: on/off` line under `## Auto-Pilot` in the runbook is the reserved slot.

## Out of scope

- **Auto-merge.** Critical Rule #3 is non-negotiable; auto-pilot always stops before merge.
- **Per-stage granularity** (e.g. auto-apply Sophie but pause Leo). Too fine; the tripwire already handles the "pause when it matters" case.
- **Making `update`/`bugfix` richer.** Their thinness is inherent — they have no pre-code gates. Accepted.
- **Telemetry on how often the tripwire fires.**
