# Parallelism — Deep Design (P-01 … P-07)

How LOUIE lets independent work run concurrently while staying tool-agnostic. This is the design detail behind the P-findings in `findings.md`.

## Design Principles (agreed with the maintainer)

1. **Tool-agnostic core, runtime upgrade.** The parallelism *data* (what depends on what, what touches what) lives in plain markdown that every runtime reads. Concurrency is an *optional execution strategy* on top: runtimes with subagent/background-task support exploit the data; all others execute sequentially in dependency order and lose nothing. Same shape as the structured-choice pattern in `interaction-guidelines.md` — author once, render per capability.
2. **Single session.** All concurrency happens inside one chat session via subagent dispatch from the orchestrating main loop. No worktrees, no second terminal, no multi-session coordination.
3. **Gates serialize.** Concurrency exists only between gates, never across one. See § Gate Composition.
4. **Disjointness is declared, not discovered.** Two units may run concurrently only when their declared file sets don't overlap. Overlap → sequential. No merge machinery, no conflict resolution — prevention over cure.

## The Work-Package Model (P-01)

The unit of parallelism is the **work package**: a plan phase whose dependencies are satisfied and whose declared file set is disjoint from every other in-flight package.

### Annotation format

`feature-template.md` § Implementation Plan — phase headings gain a bracket annotation:

```markdown
## Implementation Plan

> Phases declare dependencies and file scope. Phases whose dependencies are met
> and whose Files sets are disjoint are independent work packages — they may run
> in any order, or concurrently on runtimes that support it.

### Phase 1: Data model  [Depends: none | Files: src/db/**, src/models/recipe.ts]
- [ ] Define schema
- [ ] Migration

### Phase 2: API endpoints  [Depends: 1 | Files: src/api/recipes/**]
- [ ] CRUD routes

### Phase 3: Shelf UI (static)  [Depends: none | Files: src/ui/shelf/**]
- [ ] Components against fixture data

### Phase 4: Integration  [Depends: 2, 3 | Files: src/app.ts, src/ui/shelf/data.ts]
- [ ] Wire UI to API
```

Rules:

- `Depends:` names phase numbers or `none`. `Files:` is a small glob list — the *write* scope, not everything read. Reads never conflict.
- Authored when `feature.md` is created (step 6 of `louie-feature`), from the architecture's folder structure. **Nina validates before implementing**: if her plan for a phase would write outside its declared Files scope, that's a plan deviation — fix the annotation first (manual) or treat as the deviation tripwire (auto-pilot).
- An **integration phase** (depends on 2+ phases, touches shared wiring files) is normal and expected — it's simply never parallel with anything.
- Sequential runtimes: annotations are documentation. They still improve `louie-continue` (resume at any unblocked phase, not just "first unticked") and give Max a checkable contract (did the diff stay in scope?).

### Why phase-level, not task-level

Task-level dependency graphs (checkbox granularity) look more powerful but are noise: tasks inside a phase share files almost by definition, and the annotation burden would violate the brevity rules. Phases are already the unit Nina implements and ticks — annotate the unit that exists.

## Capability Detection and Degradation (P-02)

New `_LOUIE_/guidelines/execution-guidelines.md`, read by orchestrating commands and by Nina. Content outline:

- **Capability check:** "Does your runtime let you dispatch a subagent/background task that works independently and returns a result?" Claude Code: yes (Task/subagent mechanism; LOUIE agents install as native subagents — see E-01). Cursor / Gemini CLI / Codex CLI / opencode / pi: treat as no unless the runtime documents otherwise; the check is phrased behaviorally, not by product name, so new runtimes slot in without a framework release.
- **If capable:** you may run ready work packages concurrently per the dispatch rules below.
- **If not:** execute work packages sequentially, in dependency order, preferring the order written. This is not a degraded mode — it is the baseline every project must remain correct under.
- **Hard rules (both modes):** gates serialize (§ Gate Composition); never run two packages with overlapping Files sets; integration phases always run alone; a package that needs user input pauses (capable runtimes: the subagent returns a question instead of a result; the orchestrator surfaces it).

Also the single home for the **Context Discipline** rules (S-05) — both are "how agents execute," and single-sourcing follows the language-setting precedent.

## Gate Composition (P-06)

Parallelism and gates compose by **containment**: concurrency lives strictly inside the unattended stretches that auto-pilot already defines.

- **Manual mode → sequential, always.** Blocking gates (Sophie's proposal, Leo's proposal, Max's verdict) punctuate the chain; there is no unattended stretch to parallelize.
- **Auto-pilot (or the walkthrough's unattended segments) → parallel dispatch allowed** between the agreement gate and the pre-merge summary.
- **Deviation tripwire in a parallel branch:** the branch *pauses itself* — the subagent stops and returns `paused: <what diverged>` instead of a result. Sibling branches run to completion (they were independent by construction; finishing them wastes nothing). The orchestrator then presents the pause content-first (two-turn gate) alongside the completed branches' narration. It does not dispatch new packages while a pause is unresolved.
- **Narration:** auto-pilot's "suppress blocking, not visibility" rule extends naturally — the orchestrator narrates each package's start/finish in chat as results come in.

This adds **no new setting**. Parallelism is an execution strategy inside existing modes, not a new mode. (If it ever needs a kill switch, a `parallel: on/off` line under `## Auto-Pilot` in the runbook is the natural slot — defer until someone asks.)

## Within-Feature Parallel Runs (P-03)

The orchestration loop, on a capable runtime, during an unattended stretch, at `louie-feature` step 10:

1. Nina (main loop or a planning subagent) validates annotations and computes the ready set: dependencies met, Files disjoint.
2. Dispatch one **implementation subagent per ready package** (the Nina agent definition, seeded with: feature folder path, the phase to implement, its Files scope, and the standard context list). The shared working tree is safe because write scopes are disjoint.
3. As each package returns: tick its phase in `feature.md`, narrate, recompute the ready set, dispatch newly unblocked packages.
4. Integration phase(s) run last, sequentially, in the main loop or a single subagent.
5. **Validation is centralized:** subagents do not run the project's build/lint as a completion gate against each other (two concurrent builds on one tree can interleave confusingly). Each package self-checks what it can cheaply; the orchestrator runs the full lint/build/test pass once after each join point, and once before handoff to Max.
6. **One review:** Max reviews the merged result exactly as today, with the package boundaries listed in Nina's handoff ("implemented as N parallel packages; integration in phase 4") so he can check the seams first — seams are where parallel work actually breaks.
7. Commits: one commit per package at join time (Conventional Commits, package named), or a single squashed feature commit — follow the project's existing discipline; the orchestrator, not the subagents, commits.

Failure handling: a package that errors or returns incomplete does not poison siblings — the orchestrator surfaces it after the in-flight set drains, and the fix round (or tripwire pause) happens sequentially. Two-attempt rule from `coder.md` applies per package.

## Across-Feature Parallel Runs (P-04)

Builds on the same machinery one level up. The unit becomes a **feature chain segment** (Sophie eval → feature doc → Nina packages → Max → Ava).

- **Dependency capture:** at the Scope Split Gate, Tom already clusters stories; he now also states the edges ("`shelf-ui` needs `books-core`; `auth` is independent") in each `requirements.md` handoff and in the split playback the user approves. `feature.md` Metadata `Dependencies:` becomes load-bearing (feature slugs, or `None`), and the `overview.md` Features table gains a `Depends on` column so the graph is readable without opening folders.
- **Batch agreement:** the plan-agreement gate happens once per feature but in one sitting — Tom plays back the split, the user approves the batch (or trims it). Under auto-pilot, that approval starts the batch run; without it, features run one at a time exactly as today.
- **Dispatch:** features whose dependencies are complete (`Tested`/`Implemented`) or absent run concurrently — each as its own chain: Sophie-eval subagent → orchestrator writes `feature.md` → Nina package run (P-03, nested) → Max → Ava. Cross-feature file disjointness is checked the same way, from each feature's aggregate Files scope; overlap (usually shared wiring) serializes those two features — expected and fine.
- **Branch/merge:** under default branch mode (`current`) all features land on the current branch; the orchestrator owns commit ordering. Under `ask`-mode-with-branches, one branch per feature and *sequential merges* at the end — merge remains a per-feature user gate (Critical Rule #3), never parallel.
- **Pre-merge summary:** one per feature (they complete at different times); the orchestrator presents them as each chain finishes, batch-style at the end for whatever finished together.
- **`louie-continue`:** several `In Development` rows becomes the *normal* case — the existing "several candidates → structured choice" path already handles it; add "resume the batch" as an option when annotations show a batch was in flight.

Scope guard: cap concurrent feature chains low (3–4). The limit isn't the runtime, it's reviewability — the user still reads every pre-merge summary.

## Read Fan-Out (P-05)

- Each agent's Context section gains one line: "These reads are independent — batch them (or read them concurrently) if your runtime supports it; order doesn't matter."
- `louie-evaluate` step 5 and `louie-import`'s Sophie scan gain a fan-out note: on capable runtimes, scan per top-level directory (or per category) as concurrent read-only subagents, then merge results **before** finding-ID assignment (IDs must stay stable and gap-free). On other runtimes, chunk sequentially — same chunking, no concurrency. This is also the enabling half of S-04 (evaluate at scale).

## Reviewer/Tester Overlap (P-07)

Only under auto-pilot on capable runtimes; default stays serial.

- After Nina's handoff, dispatch Max and Ava together. Ava works from `feature.md` + `requirements.md` (her checklist barely depends on Max).
- When Max returns: if verdict is clean, Ava's result stands; the orchestrator has Ava (same subagent, follow-up) fold Max's "Key concerns for testing" into a targeted top-up pass. If Max requires fixes, the fix rounds run as today; Ava's suite then re-runs against the fixed code — her tests weren't wasted, they're the regression net for the fix round.
- Cost/benefit is honest: one extra Ava top-up pass vs. the full Max wall-clock hidden. Worth it on big features; that's why it's a Suggestion, not a default.

## What's Explicitly Out of Scope

- **Worktree / multi-session parallelism.** The single-session constraint makes disjoint-file dispatch sufficient; worktrees add setup cost and a merge problem LOUIE doesn't need.
- **Speculative parallelism** (running Phase 2 optimistically before Phase 1 lands). Complexity without demand.
- **Parallel gates.** Two dialogs at once is never acceptable.
- **A new persistent mode/setting.** Reuse auto-pilot; add a runbook toggle only if real usage asks for it.

## Implementation Order

P-01 (annotations — pure convention, ships alone) → P-02 (guideline) + E-01 (subagent install) → P-03 + P-06 (first real concurrency) → P-05 (fold into evaluate/import) → P-04 (batch features) → P-07 (opportunistic).
