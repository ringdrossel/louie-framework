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
| Should Fix | 4 | 3 | 2 | **9** |
| Suggestion | 2 | 2 | 1 | **5** |
| **Total** | **7** | **7** | **4** | **18** |

"Critical" here means *structural gap that blocks the stated goals*, not "broken today."

## Findings Index

| ID | Tier | Title | Status |
|----|------|-------|--------|
| P-01 | Critical | Dependency + file-scope annotations on plan phases (work-package model) | pending |
| P-02 | Should Fix | Runtime execution-capability convention (detect concurrency, degrade to sequential) | pending |
| P-03 | Should Fix | Within-feature parallel implementation (concurrent Nina work packages) | pending |
| P-04 | Should Fix | Across-feature parallelism via a feature dependency graph | pending |
| P-05 | Suggestion | Parallel read/analysis fan-out (batched context reads, fanned scans) | pending |
| P-06 | Should Fix | Auto-pilot is the gate model for parallel execution (composition rule) | pending |
| P-07 | Suggestion | Overlap Max's review and Ava's test writing | pending |
| S-01 | Critical | Partition `architecture.md` into a slim index + per-domain docs | pending |
| S-02 | Critical | First-class, maintained codebase map for large projects | pending |
| S-03 | Should Fix | `overview.md` index scaling: domain grouping + `Retired` status | pending |
| S-04 | Should Fix | Incremental, chunked `louie-evaluate` + smart-merge on rescan | pending |
| S-05 | Should Fix | Context-read discipline for agents at scale | pending |
| S-06 | Suggestion | Monorepo / multi-package story | pending |
| S-07 | Suggestion | `louie-status` aggregation command (backlog promotion) | pending |
| E-01 | Critical | Agents ship subagent frontmatter but are never installed or used as subagents | pending |
| E-02 | Should Fix | Single-source generation / consistency lint for init scripts + command tables (live bug) | pending |
| E-03 | Should Fix | Framework versioning: VERSION stamp, cut releases, update-framework delta | pending |
| E-04 | Suggestion | Remove or justify the `model: sonnet` pin in agent frontmatter | pending |

Full detail: compact entries in `findings.md`; deep design per theme in `parallelism.md`, `scaling.md`, `efficiency.md`.

## Suggested Application Order

Dependencies between findings dictate an order that differs from pure tier order:

1. **E-02** (consistency lint/generator) — fixes a live bug and makes every later change to 12 scripts + 5 tables safe.
2. **E-03** (versioning) — cheap, and each subsequent finding lands as a versioned release.
3. **P-01** (work-package annotations) — pure template + agent-instruction change; the foundation everything parallel builds on. Ships value even with zero concurrency (better ordering, better `louie-continue` resume points).
4. **E-01 + P-02** (subagent installation + capability convention) — the runtime layer. E-04 folds into this naturally.
5. **P-03, P-06** (within-feature parallel run under auto-pilot) — first real concurrency.
6. **S-01, S-02, S-05** (architecture partition, codebase map, read discipline) — the big-codebase package; best done together since they share the "index-first" principle.
7. **P-04** (across-feature) — builds on P-01+P-03 and S-03's overview changes.
8. **S-03, S-04, S-07** — index scaling, chunked evaluate, status command.
9. **P-05, P-07, S-06** — opportunistic.

## Status Lifecycle & How to Apply

Same lifecycle as `louie-evaluate`: `pending → applied / modified / skipped / deferred`.

To run an apply session in a framework-dev context: pick the next `pending` finding (suggested order above), read its deep-detail section in the category file, implement on this repo (each finding lists its touch points), then update the Status column here **and** the entry in `findings.md`, and add a Run History line below. Findings are sized so most are one focused session; P-03/P-04 and S-01/S-02 are feature-branch-sized.

When a finding is applied, move its design content into the appropriate permanent internals doc (`core.md`, a new `parallelism.md` internals doc, etc.) — this folder is a working set, not the long-term home.

## Run History

- 2026-07-02: initial evaluation — 18 findings (4 Critical, 9 Should Fix, 5 Suggestions), all pending.
