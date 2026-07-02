# Framework Evaluation — Summary

**What this is:** a `louie-evaluate`-style assessment of the LOUIE framework *itself* — its mechanics, not a codebase. Findings are persistent, tiered, carry a status, and can drive a step-by-step apply loop across framework-dev sessions.

- **Date:** 2026-07-02
- **Scope:** whole framework (`_LOUIE_/`, distribution model, `_LOUIE-internals/` design docs)
- **Lens:** the maintainer's three asks — (1) automatic parallel task execution, (2) scaling to 100k+ LOC codebases, (3) general efficiency — plus anything else found worthy
- **Constraints agreed with the maintainer:** parallelism must be **tool-agnostic at its core** (prompt-level, works on all six runtimes) and *upgrade* to real concurrency where the runtime supports it; both **within-feature and across-feature** granularity; everything inside **one chat session**; scale target is **solo/small team on a big codebase**, not multi-human enterprise process

## Verdict

The framework is in good structural shape: lazy loading, per-feature folders, the gate system, and the settings pattern (review/branch/autopilot/language modes) are coherent and were clearly designed, not accreted. The three biggest gaps are all *absence*, not *defect*:

1. **The chain is strictly serial by design** — nothing in any artifact records what depends on what, so no runtime (however capable) can safely run two things at once. The fix is data, not tooling: dependency + file-scope annotations on plan phases and features. Once the data exists, sequential runtimes ignore it at zero cost and capable runtimes exploit it.
2. **Every top-level artifact is a single file** — `architecture.md`, `overview.md`, and whole-repo `louie-evaluate` all assume they fit in context. At 100k+ LOC they don't. The per-feature folder split solved this for implementations; the same index-plus-partition move needs to happen one level up.
3. **The framework ships Claude Code subagent definitions and never uses them** — agent files carry `name`/`tools`/`model` frontmatter but `claude-init.sh` never installs them to `.claude/agents/`. Fixing this single gap is the mechanical prerequisite for parallel dispatch *and* the biggest context-efficiency win available.

One live bug was found in passing (all six `.sh` init scripts emit a malformed Key Files bullet — see E-02).

## Tally

| Tier | Parallelism | Scaling | Efficiency | Total |
|------|:-:|:-:|:-:|:-:|
| Critical | 1 | 2 | 1 | **4** |
| Should Fix | 4 | 3 | 3 | **10** |
| Suggestion | 2 | 2 | 1 | **5** |
| **Total** | **7** | **7** | **5** | **19** |

"Critical" here means *structural gap that blocks the stated goals*, not "broken today."

## Findings Index

| ID | Tier | Title | Status |
|----|------|-------|--------|
| P-01 | Critical | Dependency + file-scope annotations on plan phases (work-package model) | applied |
| P-02 | Should Fix | Runtime execution-capability convention (detect concurrency, degrade to sequential) | applied |
| P-03 | Should Fix | Within-feature parallel implementation (concurrent Nina work packages) | applied |
| P-04 | Should Fix | Across-feature parallelism via a feature dependency graph | applied |
| P-05 | Suggestion | Parallel read/analysis fan-out (batched context reads, fanned scans) | applied |
| P-06 | Should Fix | Auto-pilot is the gate model for parallel execution (composition rule) | applied |
| P-07 | Suggestion | Overlap Max's review and Ava's test writing | applied |
| S-01 | Critical | Partition `architecture.md` into a slim index + per-domain docs | applied |
| S-02 | Critical | First-class, maintained codebase map for large projects | applied |
| S-03 | Should Fix | `overview.md` index scaling: domain grouping + `Retired` status | applied |
| S-04 | Should Fix | Incremental, chunked `louie-evaluate` + smart-merge on rescan | applied |
| S-05 | Should Fix | Context-read discipline for agents at scale | applied |
| S-06 | Suggestion | Monorepo / multi-package story | applied |
| S-07 | Suggestion | `louie-status` aggregation command (backlog promotion) | applied |
| E-01 | Critical | Agents ship subagent frontmatter but are never installed or used as subagents | applied |
| E-02 | Should Fix | Single-source generation / consistency lint for init scripts + command tables (live bug) | applied |
| E-03 | Should Fix | Framework versioning: VERSION stamp, cut releases, update-framework delta | applied |
| E-04 | Suggestion | Remove or justify the `model: sonnet` pin in agent frontmatter | applied |
| E-05 | Should Fix | Downstream migration path for shape-changing findings (update channels + lazy backfill) | applied |

Full detail: compact entries in `findings.md`; deep design per theme in `parallelism.md`, `scaling.md`, `efficiency.md`.

## Suggested Application Order

Dependencies between findings dictate an order that differs from pure tier order:

1. **E-02** (consistency lint/generator) — fixes a live bug and makes every later change to 12 scripts + 5 tables safe.
2. **E-03** (versioning) — cheap, and each subsequent finding lands as a versioned release. Prerequisite for E-05's version-gated migrations.
3. **P-01** (work-package annotations) — pure template + agent-instruction change; the foundation everything parallel builds on. Ships value even with zero concurrency (better ordering, better `louie-continue` resume points).
4. **E-01 + P-02** (subagent installation + capability convention) — the runtime layer. E-04 folds into this naturally.
5. **P-03, P-06** (within-feature parallel run under auto-pilot) — first real concurrency.
6. **S-01, S-02, S-05** (architecture partition, codebase map, read discipline) — the big-codebase package; best done together since they share the "index-first" principle.
7. **P-04** (across-feature) — builds on P-01+P-03 and S-03's overview changes.
8. **S-03, S-04, S-07** — index scaling, chunked evaluate, status command.
9. **P-05, P-07, S-06** — opportunistic.

**E-05 (downstream migration path) is not a step of its own** — it's the rule that every shape-changing finding above (P-01, P-04, S-01, S-02, S-03) ships its migration hook in the same release: template/behavior changes via the `_LOUIE_/` replace, new outputs via the step-5 bootstrap, layout changes via step-6 → `louie-migrate`, index columns via `louie-doc` reconcile, and lazy backfill (never heuristic rewriting) for plan annotations. See `efficiency.md` § E-05 for the channel mapping.

## Status Lifecycle & How to Apply

Same lifecycle as `louie-evaluate`: `pending → applied / modified / skipped / deferred`.

To run an apply session in a framework-dev context: pick the next `pending` finding (suggested order above), read its deep-detail section in the category file, implement on this repo (each finding lists its touch points), then update the Status column here **and** the entry in `findings.md`, and add a Run History line below. Findings are sized so most are one focused session; P-03/P-04 and S-01/S-02 are feature-branch-sized.

When a finding is applied, move its design content into the appropriate permanent internals doc (`core.md`, a new `parallelism.md` internals doc, etc.) — this folder is a working set, not the long-term home.

## Run History

- 2026-07-02: initial evaluation — 18 findings (4 Critical, 9 Should Fix, 5 Suggestions), all pending.
- 2026-07-02: added E-05 (downstream migration path — propagation channels, lazy backfill, version gating) after maintainer discussion; now 19 findings (4 / 10 / 5).
- 2026-07-02: fixed E-02's live merged-bullet bug in all 12 init scripts (verified via test run of `claude-init.sh`). E-02 remains `pending` — the generator / consistency lint is still open.
- 2026-07-02: **E-02 applied** — consistency lint shipped as `_LOUIE-internals/tools/check-consistency.sh` (command-set diff on listing lines across 16 surfaces, merged-bullet pattern, `_LOUIE_/` path existence, sh/bat pairing; all four checks mutation-tested). The lint chosen over the generator (per maintainer decision; generator parked in `BACKLOG.md`). It immediately caught more live drift, fixed in the same batch: `/louie-update-framework` missing from all 12 init-script tables, `louie-evaluate` + `louie-recipe` missing from `project-setup.md` Quick Reference. Run the lint before every commit (rule in `_LOUIE-internals/README.md`).
- 2026-07-02: **E-03 applied** — `_LOUIE_/VERSION` created at `1.0.0` (semver adopted per maintainer decision; pre-existing `v05.x` tags remain history, play no role in gating). CHANGELOG cut into its first release section; `louie-update-framework` is version-aware (delta report from the pulled clone's changelog, version-gated migration rule, pre-VERSION fallback = old behavior); lint check 5 enforces bump discipline; release process documented in `core.md` § Versioning & Release Process. Tag `v1.0.0` on `main` when this merges.
- 2026-07-02: **P-01 applied** — `[Depends: … | Files: …]` phase annotations landed as pure markdown convention: template (§ Implementation Plan, with the E-05 degradation rule written into the spec — absent annotations = sequential in written order, never retro-annotate), `louie-feature` step 6 authors them, Nina validates write scope before implementing (deviation → fix annotation / tripwire), `louie-extend` annotates only the phase it adds on legacy plans, `louie-continue` resumes at any unblocked phase, `agent-handoffs.md` documents the Nina/Max contract. No execution change yet — dispatch lands with P-02/P-03.
- 2026-07-02: **E-01 + P-02 + E-04 applied** (the runtime layer, one batch). New `_LOUIE_/guidelines/execution-guidelines.md`: behavioral capability check, sequential baseline ("not a degraded mode"), hard rules (gates serialize / disjoint write scopes / integration alone / pause-don't-improvise / absent annotations = sequential), the stage dispatch table, and subagent seeding via the existing handoff artifacts. `claude-init.sh/.bat` now install `_LOUIE_/agents/*.md` to `.claude/agents/` (verified by temp-dir execution). Frontmatter pass: `model: sonnet` dropped from all seven agents (inherit session model; rationale + tiering policy in `core.md` § Agents as Subagents); Ava's `tools:` expanded to `Edit, Write, Bash` (she writes tests and runs suites); Sophie/Max stay read-only — their doc writes are applied by the orchestrator. Registered in Key Files of all 12 init scripts, root `CLAUDE.md`, `README.md`; Nina's Context list points at the guideline.
- 2026-07-02: **P-03 + P-06 applied** (first real concurrency). `execution-guidelines.md` gained § Within-feature parallel runs (7-step orchestration loop: ready-set → one Nina subagent per package → tick/narrate/recompute → integration last → centralized validation at join points → one Max review with seams-first → orchestrator-only commits; failures drain, don't poison siblings) and § Gate Composition (containment in auto-pilot's unattended stretches; manual = sequential always; per-branch tripwire pause; no new setting — `parallel:` runbook toggle deliberately deferred). Nina gained Package Mode (`coder.md` step 2b: one phase, stay in scope, cheap self-checks only, no ticks/commits, `paused:` on deviation); Max checks seams + `Files:` scope contract (`reviewer.md`); `louie-feature` step 10 + § Auto-Pilot and `louie-extend` step 10 carry the dispatch pointer; composition recorded in `autopilot.md` internals.
- 2026-07-02: **S-01 + S-02 + S-05 applied** (the big-codebase package). S-05: § Context Discipline in `execution-guidelines.md` (index-first, partition reads, Grep-before-Read, skim caps, fix-don't-compensate), one-line pointer in all seven agents' Context sections. S-01: partition threshold (~400 lines / ~6+ domains) in `architecture-template.md`; Sophie's subsequent-run size check proposes the split (always material — pauses under auto-pilot); new `architecture-domain-template.md`; split runs as `louie-migrate architecture` (second migration case); `louie-evaluate` LOUIE-mode compliance runs per domain. S-02: canonical `codebase-map-template.md`; Sophie creates at import-when-large or with the split; Nina appends rows (coder step 4); `louie-doc` 4b reconciles size columns + flags dead paths; evaluate's non-LOUIE throwaway map now uses the same template (promotable on import). E-05 hooks shipped in-batch: `louie-migrate` architecture case, `update-framework` step 5 (+codebase-map bootstrap) and step 6 (+oversized-architecture detection).
- 2026-07-02: **P-04 applied** (across-feature parallelism). Tom records inter-feature dependency edges at the Scope Split Gate (`analyst.md` 4a + 5b); `feature.md` Metadata `Dependencies:` made load-bearing; new **`Depends on`** column on the overview Features table (scaffold + setup/import writers). `louie-feature` § Batch Mode approves a whole split in one sitting → concurrent independent chains (cap 3–4) on capable runtimes under auto-pilot, dependency-ordered queue otherwise; `--batch` flag. `execution-guidelines.md` § Across-feature parallel runs holds the dispatch rules (aggregate-`Files:` disjointness, per-feature summaries, sequential merges under `ask` branch mode). `louie-continue` offers "resume the batch." E-05 hook in-batch: `louie-doc` reconcile adds/repairs the `Depends on` column (channel 4).
- 2026-07-02: **S-03 + S-04 + S-07 applied, and E-05 marked applied** (index scaling, chunked evaluate, status command). S-03: `louie-doc` reconcile gained size-triggered overview stages (flat <30 → per-domain sections 30–100 → per-domain files >100) + terminal `Retired` status (collapsed section, folder kept, agents skip it; set via `louie-doc` — chose the doc-step over a new command to avoid conflating features with roadmap epics); overview scaffold + `feature.md` template + `louie-continue` updated. S-04: `louie-evaluate` chunked scan (per domain/dir, merge-then-ID, concurrent on capable runtimes) + smart-merge on rescan (file+normalized-signature, status carried forward, unmatched→resolved) + chunk-aligned domain re-runs; `evaluate.md` internals rewritten, BACKLOG smart-merge item absorbed. S-07: new **`louie-status`** command (read-only aggregation, no agent, index-first per Context Discipline) registered on all 17 surfaces (lint: 24 commands); BACKLOG "Where am I?" absorbed. **E-05 → applied:** its full channel-mapping shipped across batches — P-01 lazy backfill (b3), architecture-split via `louie-migrate` + codebase-map bootstrap (b6), `Depends on` reconcile column (b7); nothing left open.
- 2026-07-02: **P-05 + P-07 + S-06 applied — all 19 findings now applied; the evaluation is complete.** P-05: § Read Fan-Out in `execution-guidelines.md`, fan-out clause folded into all seven agents' Context Discipline pointer, evaluate/import scans reference it. P-07: § Reviewer/Tester Overlap (auto-pilot + capable runtime only; serial default); `tester.md`/`reviewer.md`/`louie-feature` steps 11–12 carry the parallel-dispatch case. S-06: monorepo decision rule documented in `core.md` § Monorepo Direction + a Per-Package Commands table in `tech-stack-template.md` (no machinery). BACKLOG monorepo item absorbed. Final tally: 4 Critical + 10 Should Fix + 5 Suggestion, all applied over 9 batches; E-05 rode along as the per-batch migration-hook rule. Remaining manual step at merge to `main`: tag `v1.0.0`.
