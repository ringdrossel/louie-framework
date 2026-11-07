# louie-continue

When the user says **`louie-continue`**, resume in-progress LOUIE work after a break, a restart, or a fresh session. It reconstructs *where you stopped* from artifacts on disk (`_LOUIE-output/`) + git — **not** from chat history. The files are the memory; they survive a restart, a tool switch, even a different machine.

Optional argument: `louie-continue <feature>` targets a specific feature instead of auto-detecting.

## What it does not do

It does **not** read or recover past chat transcripts — a LOUIE command can't reach prior conversations. It rebuilds state from the artifacts, which is more reliable than chat anyway. If the runtime has native session-resume (e.g. Claude Code's `claude --resume`), it *suggests* it as an optional way to also restore the original conversation — but it never depends on it.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/implementations/overview.md`, `_LOUIE-output/runbook.md`, and `_LOUIE-output/architecture.md` (skim).
   - If there's no `_LOUIE-output/` yet, tell the user there's no LOUIE project to continue and point them at `louie-setup` / `louie-import`.
   - **Resolve the project profile** from the runbook's `## Project Profile` section (absent = `standard`) and pass it to the agent you resume. In a `standard` project, skip every step marked "Only if the profile is `game`".

2. **Checkpoint first:** if `_LOUIE-output/checkpoint.md` exists, read it and **delete it immediately** — before any resume work — so a consumed checkpoint can't linger to confuse a later session. It names the task, phase completed, next step, gates passed, and chat-only decisions (format: `_LOUIE_/guidelines/interaction-guidelines.md` § Checkpoint). Treat it as the primary signal, not as authority: reconcile it against git and the artifacts in step 5 — **on any disagreement the files win** (the session may have died after the last write), and the checkpoint only narrows the search. When it reconciles, take its target and skip step 4's picking.

3. **Detect in-progress work** (no checkpoint, or it didn't reconcile — gather candidates from three signals):
   - **Overview anchor:** every row in the Features table with `Status: In Development`. This is the primary signal for feature work — `louie-feature` sets it when coding starts. Skip any row in the collapsed `### Retired` section — retired features are terminal, not resumable.
   - **Git anchor:** run `git status` and `git diff --stat`, note the current branch and recent commits. Uncommitted changes, a `feature/<name>` branch, or recently-touched source under a feature folder all point at active work. This catches **bugfix / extend** in progress (which don't flip the overview to `In Development`): look for a recently-added `implementations/<feature>/bugfixes/<date>-<slug>.md` (or `_LOUIE-output/bugfixes/<date>-<slug>.md`) whose fix isn't committed, or a `requirements.md` recently appended by `louie-extend`.
   - **Setup anchor:** a half-finished `louie-setup` looks like *no* activity to the other two signals (every feature still `Planned`, no source code) — check for it explicitly. It's in progress when requirements folders exist but the foundation isn't complete or no feature has started: `_LOUIE-output/implementations/*/requirements.md` exists **and** (`_LOUIE-output/architecture.md` is missing **or** no folder has a `feature.md` and every Features-table row is `Planned`). If so, add a candidate of kind `setup` (target: the project).
   - **Content anchor — only if the profile is `game`:** rows with status `Outlined` or `Drafted` in `_LOUIE-output/story/overview.md` or `_LOUIE-output/game-design/overview.md`, and uncommitted changes under the content paths declared in `architecture.md` § Content Pipeline, point at an unfinished `louie-content` run. Add a candidate of kind `content` (target: the chapter, character, support, or level).
   - Build a candidate list. Each candidate is `(target, kind ∈ {feature, bugfix, extend, setup}, evidence)` — plus kind `content` when the profile is `game`.

4. **Pick the target:**
   - **None:** report there's nothing obviously in progress. Show the most recent activity (latest `Change History` line across features, last commit) and offer to start something (`louie-feature` / `louie-bugfix`). Stop.
   - **One:** use it.
   - **Several:** present a **structured choice** — use your runtime's structured-choice tool if it has one, otherwise a lettered list (see `_LOUIE_/guidelines/interaction-guidelines.md`). One option per candidate, each labelled with a one-line "where it stands." **If several `In Development` features share a dependency graph** (the overview's `Depends on` column links them and they were approved together as a batch — see `louie-feature` § Batch Mode), offer a **"resume the batch"** option that continues all of them in dependency order, alongside the per-feature options.
   - If the user passed `louie-continue <feature>`, skip straight to that target.

5. **Reconstruct the state** for the chosen target (read-only):
   - **Feature:** read its `feature.md` — the highest-ticked `Status` checkbox, which `Implementation Plan` phases are ticked, `Open Questions`, the last `Change History` line, and the `Handoff` sections. Read `decisions.md` if present. **Resume point:** if the plan phases carry `[Depends: …]` annotations, any unticked phase whose dependencies are all ticked is a valid resume point (prefer the earliest; mention the others if there are several). Without annotations, the resume point is the first unticked phase — the classic behavior.
   - **Run report:** if `run-report.md` exists in the feature folder (an agentic run — see `_LOUIE_/workflow/agentic-mode.md`), read its header. `Status: needs-human` means the run halted on the `Pending decision:` question — that decision (now answered by the user, or by the agent's new invocation) is the resume point; the report's per-agent sections say exactly where the chain stopped.
   - **Bugfix:** read the per-fix doc (`bugfixes/<date>-<slug>.md`) — Symptoms / Root Cause / Fix / Detect-Avoid — and whether a regression test exists.
   - **Git:** current branch, the uncommitted diff, and recent commits touching the target. This is the richest "where did I stop" signal — reconcile it against what the docs claim.
   - **Roadmap:** if the feature was seeded `--from-roadmap`, note the linked epic and its status.
   - **Setup:** read `overview.md`'s Features table, note which requirements folders exist, and which of the three foundation docs (`architecture.md`, `tech-stack.md`, `runbook.md`) are present.
   - **Content — only if the profile is `game`:** read the target's doc (`story/chapters/<nn>-<slug>.md`, `story/characters/<name>.md`, the `relationships.md` row, or `game-design/levels/<map>.md`) — its status, its Consistency Check boxes — plus the content files it lists and their git state, and `story/run-report.md` / `game-design/run-report.md` if an agentic content run left one (its `Pending decision:` is the resume point).

6. **Infer the chain position** (which agent/step is next) from the breadcrumbs — no stored progress pointer exists (the checkpoint, if any, was consumed in step 2); it's derived:
   - **Setup, before the foundation:** requirements folders exist but `architecture.md` is missing → resume `louie-setup` at Sophie (its step 5).
   - **Setup, at the gate:** foundation docs exist, no folder has a `feature.md`, every feature `Planned` → resume at the architecture gate (`louie-setup` step 6). Gate answers live only in chat, so re-present the digest and re-run the gate — unless the checkpoint records it as already confirmed, in which case go straight to the first feature doc (step 7).
   - `requirements.md` exists but no `feature.md` → create the feature doc (Sophie eval + confirmation gate still apply).
   - `feature.md` exists, code partial or absent → **Nina**, resuming at an unblocked unticked `Implementation Plan` phase (dependencies ticked, per the annotations; first unticked when unannotated).
   - Code exists but no Max review recorded in `Change History` → **Max**.
   - Reviewed but `Tested` unticked / no test files → **Ava**.
   - **Bugfix:** diagnosed but not fixed → finish the fix; fixed but no regression test → **Ava**; fixed + tested but uncommitted → wrap up.
   - **Content — only if the profile is `game`:** resume `louie-content` for the target. `Planned` with an agreed brief in the checkpoint → **Mira / Kai** proposal; `Outlined` → write; `Drafted` → consistency check; `Checked` but the overview not updated or content uncommitted → wrap up (optional Ava content-integrity run first).

7. **Summarize and propose the next step:**
   - Give a tight recap: target, kind, where it stands (phase X of Y, N files uncommitted, what's done, open questions), and the **single recommended next action**.
   - **End the turn after the recap** — if you ask for the go-ahead with a structured choice, it goes alone in the next response, and is skipped if the user's reply already decides (two-turn gate; a dialog hides the recap it asks about — see `_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second). A plain-text "Shall I pick up from there?" may close the recap message instead.
   - Wait for the user's go-ahead, then continue by reading and following the relevant agent/command (`_LOUIE_/agents/coder.md`, `_LOUIE_/commands/louie-bugfix.md`, etc.). All normal gates and review/branch modes still apply.
   - If the runtime has native chat-resume, add one optional line: "To also restore the original conversation, you can run `claude --resume` and pick the session from <date> — optional; I've already reconstructed the state from your files."

8. **Respect uncommitted work.** Surface the uncommitted diff; never reset, stash, or overwrite it without asking. Honour the project's branch mode.

## Agentic

When invoked with `--agentic`, an autonomous agent — usually the unattended loop, `_LOUIE_/tools/louie-run.sh` — is driving and nobody can answer a prompt. Full contract: `_LOUIE_/workflow/agentic-mode.md` (§ Unattended loop defines the units and the status file). This is the one command the loop ever starts; everything else is reached through it.

```
louie-continue --agentic [--unit feature|phase] [<feature>]
```

The Procedure above runs with these deltas:

- **Step 2 (checkpoint)** unchanged — consume it, reconcile it, files win.
- **Step 4 (pick the target) never asks.** Resolution order:
  1. `<feature>` given → that one; if it does not exist, `Status: blocked`.
  2. A `setup` candidate (requirements folders but no confirmed foundation, or the architecture gate not passed) → `Status: blocked`, `Pending decision: run louie-setup interactively` — setup is human work, never unattended.
  3. A run report with `Status: needs-human` whose `Pending decision` is **not** answered in this invocation → re-emit `needs-human` with the same decision and stop. Do not redo the work and do not guess the answer. (An answer supplied in the invocation text counts as answered — record it in `decisions.md` or `requirements.md` § Assumptions before continuing.)
  4. Exactly one in-progress candidate → it.
  5. Several in-progress → dependency order from the overview's `Depends on` column, then overview row order; features before bugfix/extend leftovers; a batch resumes in dependency order.
  6. None in progress → the first `Planned` row (overview order, `### Retired` skipped) whose `Depends on` are all `Implemented`/`Tested` (or `—`) **and** whose folder has a `requirements.md` — run `louie-feature --agentic <feature>` with that `requirements.md` as the task spec for Tom's evidential gate. A ready `Planned` row **without** `requirements.md` has no task spec → `Status: needs-human`, `Pending decision: write requirements for <feature> (louie-feature interactively) or retire it`.
  7. **Only if the profile is `game`:** after every feature is `Implemented`/`Tested`, content rows (`Planned` → `Outlined` → `Drafted`) in overview order via `louie-content --agentic`.
  8. Nothing left → write `run-status.md` with `Status: done`, `Next: none`, and stop. Write no run report.
- **Steps 5–6 (reconstruct, infer the chain position)** unchanged.
- **Step 7 (summarize and propose) becomes hand-off without a gate:** narrate the recap (it lands in the run log), then immediately continue through the routed command's `--agentic` path at the inferred position (`louie-feature` § Agentic, `louie-bugfix` § Agentic, …), honouring `--unit`:
  - `feature` (default) — finish the feature's remaining chain.
  - `phase` — finish exactly one unit boundary: plan (`feature.md` written), one Implementation Plan phase (ticked + committed), or finish (Max loop → Ava → overview sync → run report). Definitions: `_LOUIE_/workflow/agentic-mode.md` § Unattended loop.
- **Step 8 (uncommitted work)** — never reset or stash. A dirty tree from a dead session is reconciled like any other evidence: if the diff matches an unticked phase, it is that phase's partial work; continue it.
- **Last action, always: write `_LOUIE-output/run-status.md`** (format: `_LOUIE_/workflow/agentic-mode.md` § Run status), after the run report and the commit. `Next:` names what a fresh session should do: `feature <slug>` (the next ready feature, or this one when `--unit phase` left it unfinished), `phase <n> of <slug>`, `review <slug>`, or `none`.

Hard limits are agentic mode's: never merge, never create a branch (branch mode `ask` resolves to `current`), never run `louie-setup` / `louie-import`, halt with `needs-human` rather than guess at anything scope-defining. The structured-choice tool is never called.

## Cross-Cutting Notes

- **No new agent.** This command orchestrates: it reads the checkpoint (if any) and existing artifacts + git, then hands off to the existing chain.
- **The checkpoint is an ephemeral handoff, not a progress store.** It exists only between a mid-chain stop and the next resume, is deleted on consumption, and loses to the files on any conflict. Everything else is *inferred*, not stored — a missing checkpoint is always recoverable.
- **Read-only until you resume.** Reconstruction touches nothing; the first write happens when the resumed chain step runs (through its normal gated flow).
- **The `In Development` flag is the primary anchor** for features; git is the anchor for bugfix/extend and the tie-breaker everywhere.

## Usage

```
louie-continue
```

```
louie-continue user-authentication
```

or driven by the unattended loop (one fresh session per unit — see `_LOUIE_/workflow/agentic-mode.md` § Unattended loop):

```
louie-continue --agentic --unit feature
```
