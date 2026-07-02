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

### Within-feature parallel runs (the orchestration loop)

At the implementation step of `louie-feature` / `louie-extend`, on a capable runtime, during an unattended stretch, the orchestrating session runs this loop instead of one long Nina pass:

1. **Validate + compute the ready set.** Nina (main loop, or a planning subagent) validates the plan's annotations, then collects every phase whose `Depends:` are all complete and whose `Files:` set is disjoint from every other in-flight package.
2. **Dispatch one implementation subagent per ready package** (the Nina agent, seeded per § Seeding a subagent: feature folder, the phase, its `Files:` scope). The shared working tree is safe *because* write scopes are disjoint — that's the whole contract.
3. **As each package returns:** tick its phase in `feature.md`, narrate the finish, recompute the ready set, dispatch newly unblocked packages.
4. **Integration phases run last, sequentially** — main loop or a single subagent.
5. **Validation is centralized.** Packages self-check what's cheap (their own diff compiles in isolation, spot checks); they do **not** run the project's full build/lint as a completion gate — two concurrent builds on one tree interleave confusingly. The orchestrator runs the full lint/build/test pass once after each join point and once before handoff to Max.
6. **One review.** Max reviews the merged result exactly as a sequential run, with the package boundaries listed in Nina's handoff ("implemented as N parallel packages; integration in phase 4") so he can check the seams first — seams are where parallel work actually breaks.
7. **The orchestrator commits, never the subagents.** One commit per package at join time (Conventional Commits, package named) or a single squashed feature commit — follow the project's existing discipline.

**Failure handling:** a package that errors or returns incomplete does not poison its siblings — they were independent by construction. Let the in-flight set drain, then surface the failure; the fix round (or tripwire pause) happens sequentially. The two-attempt rule (`coder.md` § Step 1b) applies per package.

### Across-feature parallel runs

When a scope split (Tom's Scope Split Gate) produced several features, the same machinery applies one level up — the unit is a **feature chain segment** (Sophie eval → feature doc → Nina package run → Max → Ava) instead of a single phase.

- **The dependency graph is the data.** Tom records inter-feature edges at the split; they live in each `feature.md` Metadata `Dependencies:` and the overview's `Depends on` column. A feature is *ready* when its dependencies are `Tested`/`Implemented` or it has none.
- **Batch agreement, then dispatch.** The plan-agreement gate can approve the whole batch in one sitting (Tom plays back the split; the user approves or trims). Under auto-pilot that approval starts the batch run; without it, features run one at a time exactly as today.
- **Dispatch ready features concurrently**, each as its own chain segment (the P-03 within-feature loop nests inside each). Cross-feature disjointness is checked from each feature's **aggregate `Files:` scope** — overlap (usually shared wiring) serializes those two features; that's expected, not a failure.
- **Cap concurrent feature chains low (3–4).** The limit isn't the runtime — it's reviewability: the user still reads every pre-merge summary. One summary per feature, presented as each chain finishes (batch-style at the end for whatever finished together).
- **Branch/merge:** under `current` branch mode all features land on the current branch and the orchestrator owns commit ordering. Under `ask`-mode-with-branches, one branch per feature and **sequential merges** at the end — merge stays a per-feature user gate (Critical Rule #3), never parallel.
- **Sequential fallback:** a dependency-ordered queue — build the ready features in order, one at a time. Exactly today's behavior; no feature waits on an unrelated one.

## Read Fan-Out

The cheapest concurrency win, zero risk — reads can't conflict. Each agent's "Context (Read First)" list is a set of *independent* reads, not ordered steps: on a capable runtime, batch them or read them concurrently; order doesn't matter. Sequential runtimes read them in listed order — no change.

Whole-codebase scans (`louie-evaluate`, `louie-import`'s Sophie pass) fan out the same way: on a capable runtime, scan per top-level directory (or per domain / category) as concurrent read-only passes, then **merge results before assigning finding IDs** (IDs must stay stable and dense — never assign per-chunk). On other runtimes, the same chunking runs sequentially. This is the enabling half of the chunked evaluate (S-04).

## Reviewer/Tester Overlap

Only under auto-pilot on a capable runtime; the default everywhere else (and in manual mode) stays serial Max → Ava.

- After Nina's handoff, dispatch **Max and Ava together**. Ava works from `feature.md` + `requirements.md` — her test checklist barely depends on Max's verdict.
- When Max returns clean: Ava's result stands; have Ava (same subagent, follow-up) fold Max's "Key concerns for testing" into a targeted top-up pass.
- When Max requires fixes: the fix rounds run as usual; Ava's suite then **re-runs against the fixed code** — her tests weren't wasted, they're the regression net for the fix round.
- Honest cost/benefit: one extra Ava top-up pass vs. Max's full wall-clock hidden. Worth it on big features, which is why it stays a *suggestion*, not a default.

## Gate Composition

Parallelism and gates compose by **containment**: concurrency lives strictly inside the unattended stretches auto-pilot already defines. This adds no new mode and no new setting — parallel execution is an execution strategy inside existing modes. (If it ever needs a kill switch, a `parallel: on/off` line under the runbook's `## Auto-Pilot` is the natural slot — deliberately deferred until someone actually asks.)

- **Manual mode → sequential, always.** Blocking gates punctuate the chain; there is no unattended stretch to parallelize.
- **Auto-pilot (or the walkthrough's unattended segments) → parallel dispatch allowed** between the plan-agreement gate and the pre-merge summary.
- **Deviation tripwire in a parallel branch:** the branch pauses *itself* — the subagent stops and returns `paused: <what diverged>` instead of a result. Sibling branches run to completion (finishing independent work wastes nothing). The orchestrator presents the pause content-first (two-turn gate) alongside the completed branches' narration, and dispatches **no new packages** while a pause is unresolved.
- **Narration:** auto-pilot's "suppress blocking, not visibility" rule extends naturally — narrate each package's start and finish in chat as results come in.

## Hard Rules (both modes)

1. **Gates serialize.** Concurrency exists only between gates, never across one. Two simultaneous dialogs is never acceptable.
2. **Disjoint write scopes only.** Never run two packages whose `Files:` sets overlap. Overlap → sequential. Disjointness is declared, not discovered — no merge machinery, no conflict resolution.
3. **Integration phases always run alone** — after the packages they depend on, never in parallel with anything.
4. **A package that needs user input pauses.** A subagent returns the question (or `paused: <what diverged>` for a deviation-tripwire hit) instead of a result; the orchestrator surfaces it. It does not improvise an answer.
5. **Absent annotations = sequential in written order.** Unannotated plans are valid, never a blocker (see the degradation rule in `feature-template.md`).

## Context Discipline

Context is the scarce resource. Each agent's Context section names *what* to read; these rules govern *how much* — they matter little at 5k LOC and are the difference between working and flooding at 100k+. Single-sourced here; agents point at this section instead of carrying their own copy.

1. **Index-first, always.** Read the indexes before any full document: `_LOUIE-output/implementations/overview.md`, the `architecture.md` index, and `_LOUIE-output/codebase-map.md` (if present). They tell you which partitions matter for the task.
2. **Partition reads.** If `_LOUIE-output/architecture/` exists (partitioned architecture), read the index plus **only the domain doc(s) for the code you're touching** — never the whole folder. Same for feature folders: only the feature(s) in play, never several "for context."
3. **Grep before Read** on source code: locate by search, then read the located region. Use line-range reads on files over ~500 lines.
4. **Skim caps.** `runbook.md` and `tech-stack.md` are read in full — they're capped by design. Everything else is read selectively once the project is large.
5. **Fix stale indexes, don't compensate.** When an index is missing, stale, or wrong, say so and fix or flag it — bulk-reading around a broken index rebuilds the same context every session and helps nobody after you.
