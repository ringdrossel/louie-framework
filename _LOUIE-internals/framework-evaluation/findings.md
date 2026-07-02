# Framework Evaluation — Findings

Compact entry per finding: the gap, why it matters, the recommendation, and where the deep design lives. Status here mirrors `summary.md` — update both when applying.

Tier meanings: **Critical** = structural gap blocking a stated goal. **Should Fix** = meaningful improvement with clear design. **Suggestion** = worthwhile, lower urgency.

---

## Parallelism

### P-01 — Dependency + file-scope annotations on plan phases (work-package model)

- **Tier:** Critical · **Status:** applied
- **Gap:** `feature-template.md` § Implementation Plan is an ordered phase list with no dependency information and no file-scope declaration. Nothing in any artifact says "Phase 3 doesn't need Phase 2." Without that data, no runtime — however capable — can parallelize safely, and even sequential runtimes can't reorder intelligently.
- **Why it matters:** this is the tool-agnostic foundation the maintainer asked for. It's pure markdown convention: every runtime can read it, capable runtimes can act on it concurrently, and it costs nothing where unsupported. It also gives `louie-continue` sharper resume points and Max a conflict-check surface.
- **Recommendation:** phases gain `[Depends: none|<phase-nrs> | Files: <globs>]` annotations, authored at feature-doc creation, validated by Nina before implementation. Phases with satisfied dependencies and disjoint file sets are *work packages* that may run in any order or concurrently.
- **Detail:** `parallelism.md` § The Work-Package Model
- **Touches:** `feature-template.md`, `coder.md`, `louie-feature.md` (step 6), `louie-extend.md`, `louie-continue.md`, `agent-handoffs.md`
- **Progress:** applied 2026-07-02, all six touch points. Data-only per the design — no execution change until P-02/P-03. The E-05 lazy-backfill/degradation rule is written into the template blockquote itself; `louie-extend` carries the only-annotate-the-new-phase rule; `reviewer.md` integration deliberately deferred to P-03 (its touch list), with the Max scope-contract noted in `agent-handoffs.md` § Work-Package Annotations meanwhile.

### P-02 — Runtime execution-capability convention

- **Tier:** Should Fix · **Status:** applied
- **Gap:** LOUIE already has a platform-adaptive pattern for structured choices (`interaction-guidelines.md`: use the runtime's tool if present, degrade to a lettered list). There is no equivalent convention for *execution*: nothing tells an agent "if your runtime can dispatch subagents/background tasks, you may run independent work packages concurrently; otherwise run them sequentially in dependency order."
- **Why it matters:** without a written convention, per-runtime behavior will be improvised and inconsistent — the exact drift the structured-choice guideline was created to prevent.
- **Recommendation:** new `_LOUIE_/guidelines/execution-guidelines.md` (or a section in `interaction-guidelines.md`): capability detection per runtime, dispatch rules, the sequential fallback, and the hard rules (gates serialize; disjoint file sets; integration phases never parallel).
- **Detail:** `parallelism.md` § Capability Detection and Degradation
- **Touches:** new guideline file, `CLAUDE.md`/`README.md` key refs, init scripts (Key Files), agents' Context sections
- **Progress:** applied 2026-07-02 as `_LOUIE_/guidelines/execution-guidelines.md` (new file chosen over an `interaction-guidelines.md` section — S-05's Context Discipline and P-06's gate composition will share it). Contains the E-01 dispatch table. Registered in all Key Files blocks + `CLAUDE.md`/`README.md`; Context pointer added to Nina only for now (the all-agents Context touch ships with P-05/S-05).

### P-03 — Within-feature parallel implementation

- **Tier:** Should Fix · **Status:** applied
- **Gap:** Nina implements phases strictly in order even when they're independent (e.g. API + UI + migration).
- **Why it matters:** wall-clock time on multi-package features; this is granularity (a) the maintainer asked for, single-session compatible via subagent dispatch.
- **Recommendation:** on capable runtimes, during an unattended stretch (see P-06), the orchestrating session dispatches one implementation subagent per ready work package (disjoint `Files:` sets guarantee no write conflicts in the shared working tree); integration phases run sequentially afterwards; Max reviews the merged result once. Sequential fallback: dependency-ordered phases, exactly today's behavior.
- **Detail:** `parallelism.md` § Within-Feature Parallel Runs
- **Touches:** `coder.md`, `louie-feature.md`/`louie-extend.md` (step 10), `reviewer.md` (review the merge, note the package boundaries), execution guideline (P-02)
- **Progress:** applied 2026-07-02 with P-06. Orchestration loop in `execution-guidelines.md` § Within-feature parallel runs; Nina Package Mode (`coder.md` step 2b); handoff carries package boundaries; Max reviews merged result once, seams first, `Files:` scope as contract. Sequential fallback everywhere unchanged.

### P-04 — Across-feature parallelism via a feature dependency graph

- **Tier:** Should Fix · **Status:** applied
- **Gap:** Tom's Scope Split Gate already produces multiple features per request, but they're then built one at a time; `louie-feature` runs "once per approved feature." No artifact records inter-feature dependencies (the `Dependencies:` field exists in `feature.md` Metadata but is free-text and unused by any flow).
- **Why it matters:** granularity (b). After a split like `auth` / `books-core` / `shelf-ui`, independent features could proceed concurrently in one session instead of serially over days.
- **Recommendation:** Tom records dependencies at the split (they fall out of the clustering he already does); `overview.md` Features table gains a `Depends on` column; a batch mode (`louie-feature --batch` or the split-gate offering it) approves N plans at the agreement gate, then runs independent feature chains concurrently as subagent pipelines, dependency-ordered where not. Sequential fallback: dependency-ordered queue.
- **Detail:** `parallelism.md` § Across-Feature Parallel Runs
- **Touches:** `analyst.md` (Step 4a), `overview.md` scaffold + `feature-template.md` Metadata, `louie-feature.md`, `louie-continue.md` (multiple in-flight), branch-mode interaction
- **Progress:** applied 2026-07-02. Dependency capture in `analyst.md` 4a/5b; `Depends on` column added to overview scaffold + written by setup/import/Tom; `feature.md` Metadata `Dependencies:` made load-bearing; `louie-feature` § Batch Mode + `--batch`; dispatch rules in `execution-guidelines.md` § Across-feature parallel runs (cap 3–4, aggregate-`Files:` disjointness, sequential merges under `ask` branch mode); `louie-continue` batch resume; E-05 hook = `louie-doc` reconcile column (channel 4).

### P-05 — Parallel read/analysis fan-out

- **Tier:** Suggestion · **Status:** pending
- **Gap:** agents' "Context (Read First)" lists are presented as sequential steps; `louie-evaluate` and `louie-import` scan whole codebases as one linear pass.
- **Why it matters:** cheapest latency win, zero risk — reads can't conflict. On large codebases (see S-04) fan-out is what makes whole-repo scans feasible at all.
- **Recommendation:** one line in each agent's Context section ("these reads are independent — batch or parallelize them if your runtime allows"); `louie-evaluate`/`louie-import` gain a fan-out note: on capable runtimes, scan per top-level directory (or per category) concurrently, then merge findings before ID assignment.
- **Detail:** `parallelism.md` § Read Fan-Out
- **Touches:** all agent Context sections, `louie-evaluate.md` (step 5), `louie-import.md`

### P-06 — Auto-pilot is the gate model for parallel execution

- **Tier:** Should Fix · **Status:** applied
- **Gap:** parallel dispatch and blocking gates are incompatible — two concurrent chains both raising a structured choice is chaos; a subagent on most runtimes can't converse with the user at all.
- **Why it matters:** without a written composition rule, parallelism would either break the gate system (the framework's core safety mechanism) or deadlock on it.
- **Recommendation:** codify: **parallel execution happens only inside unattended stretches** — i.e. under auto-pilot semantics, after the agreement gate, before the pre-merge summary. Gates serialize; the deviation tripwire in a parallel branch pauses *that branch* (the subagent returns a "paused: material deviation" result; the orchestrator surfaces it while sibling branches continue or finish). Manual mode = sequential, always.
- **Detail:** `parallelism.md` § Gate Composition
- **Touches:** execution guideline (P-02), `autopilot.md` internals, `louie-feature.md` § Auto-Pilot
- **Progress:** applied 2026-07-02 with P-03. Containment codified in `execution-guidelines.md` § Gate Composition (manual = sequential always; per-branch tripwire pause with `paused:` return, siblings finish, no new dispatch until resolved; narration per package; no new setting — runbook `parallel:` toggle reserved but deferred). Mirrored in `autopilot.md` § Composition with parallel execution and `louie-feature.md` § Auto-Pilot.

### P-07 — Overlap Max's review and Ava's test writing

- **Tier:** Suggestion · **Status:** pending
- **Gap:** Max → Ava is serial; both only read after Nina finishes. Ava's only true input from Max is the "Key concerns for testing" handoff.
- **Why it matters:** modest wall-clock win on every feature; both agents are read-only against source.
- **Recommendation:** on capable runtimes under auto-pilot, dispatch Max and Ava concurrently after Nina; Ava starts from `feature.md` + `requirements.md`; when Max's verdict lands, Ava folds "Key concerns" into a targeted second pass. If Max requires changes, Ava's tests are re-validated after Nina's fix round (same as a cap-hit today). Keep serial as the default and in manual mode.
- **Detail:** `parallelism.md` § Reviewer/Tester Overlap
- **Touches:** `reviewer.md`, `tester.md`, `louie-feature.md` (steps 11–12)

---

## Scaling

### S-01 — Partition `architecture.md` into a slim index + per-domain docs

- **Tier:** Critical · **Status:** applied
- **Gap:** `architecture.md` is a single file that every chain agent reads in full on every task. On a 100k+ LOC system it becomes a multi-thousand-line brick — the same failure `implementations/overview.md` had before the per-feature split, one level up.
- **Why it matters:** it's the most-read artifact in the framework; if it doesn't scale, nothing downstream does. Violates the lazy-loading principle at exactly the scale the maintainer targets.
- **Recommendation:** above a trigger (~400 lines or ~6+ domains, Sophie proposes), split to `architecture.md` (slim: system diagram, domain list with one-liners, cross-cutting concerns, dependency rules between domains) + `_LOUIE-output/architecture/<domain>.md` (internal patterns, data flow, folder structure per domain). Agents read the index always, the relevant domain doc(s) only. Mirrors the proven overview.md move.
- **Detail:** `scaling.md` § Partitioned Architecture
- **Touches:** `architect.md`, `architecture-template.md` (+ new domain template), every agent Context section, `louie-evaluate.md` (LOUIE-mode lens), `louie-migrate.md` or a new split flow, `core.md` internals
- **Progress:** applied 2026-07-02. Threshold rule in the template; Sophie's subsequent-run step 7 size check (always-material, pauses under auto-pilot); `architecture-domain-template.md`; split implemented as `louie-migrate architecture` (folded into migrate per the design's recommendation, not a new command); per-domain evaluate lens; reader rule lives in § Context Discipline (S-05), not per-agent.

### S-02 — First-class, maintained codebase map for large projects

- **Tier:** Critical · **Status:** applied
- **Gap:** the concept already exists — `louie-evaluate` non-LOUIE mode has Sophie produce a throwaway `codebase-map.md` — but LOUIE projects have nothing that answers "where in 100k lines is X?" without scanning. `architecture.md` describes intent, not the actual file landscape.
- **Why it matters:** at scale, agents burn most of their context *finding* code. A maintained map (domain → paths → owning features → entry points → size signals) converts repo-wide scans into two targeted reads.
- **Recommendation:** promote to a canonical `_LOUIE-output/codebase-map.md`: Sophie creates it at setup/import when the project is large (or on first threshold crossing), Nina appends when she adds modules/top-level paths, `louie-doc`'s reconcile pass regenerates the size signals. Strictly an index — no prose, no architecture duplication.
- **Detail:** `scaling.md` § The Codebase Map
- **Touches:** new template, `architect.md`, `coder.md` (step 4), `louie-doc.md`, `louie-import.md`, `louie-evaluate.md` (reuse in LOUIE mode), agent Context sections
- **Progress:** applied 2026-07-02. `codebase-map-template.md` (strict index, no prose); Sophie creates at import-when-large / first-run-when-large / with the split proposal; Nina row-upkeep in coder step 4 (sizes are louie-doc's job); `louie-doc` 4b reconcile (regen Size, flag dead paths, check domain-name parity); evaluate LOUIE mode hands the map to Max, non-LOUIE mode's throwaway map uses the same template and is promotable on import; bootstrap via update-framework step 5 (E-05 channel 2).

### S-03 — `overview.md` index scaling: domain grouping + `Retired` status

- **Tier:** Should Fix · **Status:** applied
- **Gap:** the Features table is flat; at 100+ features it's past the "brick" threshold `scaling.md` itself identified. There is also no terminal state — retired features sit in the table forever (open BACKLOG item).
- **Why it matters:** the overview is the primary triage index (`louie-continue`, Tom, Ivy all anchor on it). A 150-row flat table defeats its purpose.
- **Recommendation:** group the Features table by domain section (same domain names as S-01/S-02) once past ~30 features; add a `Retired` status (with a one-line `louie-roadmap-change`-style command or a `louie-doc` step) that moves rows to a collapsed "Retired" section at the bottom. Past ~100 features: per-domain overview files + a top index, same pattern as everything else.
- **Detail:** `scaling.md` § Index Scaling
- **Touches:** `overview.md` scaffold, `analyst.md` (5b), `louie-feature.md` (13), `louie-doc.md` reconcile, `louie-continue.md`
- **Progress:** applied 2026-07-02. Three size-triggered stages + `Retired` in `louie-doc`'s reconcile pass; scaffold status legend + grouping note; `feature.md` template Retired marker; `louie-continue` skips Retired. Retirement is set via `louie-doc` (the design's either/or — chose the doc-step over a new one-liner command to avoid conflating features with roadmap epics). E-05: the reconcile pass is itself the migration (channel 4).

### S-04 — Incremental, chunked `louie-evaluate` + smart-merge on rescan

- **Tier:** Should Fix · **Status:** applied
- **Gap:** `louie-evaluate` assumes the whole repo fits one scan, and rescans discard all statuses (the smart-merge BACKLOG item was deferred "until users feel the re-triage pain"). At 100k+ LOC both assumptions fail: a single pass overflows any context, and re-triaging hundreds of findings is prohibitive.
- **Why it matters:** evaluate is the maintainer's main audit tool; it must work at the scale target. The deferral condition ("users feel the pain") is met by definition once the scale goal is adopted.
- **Recommendation:** (1) chunked scanning — evaluate per top-level directory / domain (from the S-02 map), each chunk a self-contained pass, merged into one findings set before ID assignment; parallel fan-out where the runtime allows (P-05). (2) Promote smart-merge from BACKLOG: carry status forward on file + normalized-signature match (nearest enclosing function as anchor); unmatched old findings → `resolved`, new → `pending`.
- **Detail:** `scaling.md` § Evaluate at Scale
- **Touches:** `louie-evaluate.md`, `evaluate.md` internals, `BACKLOG.md` (absorb entry)
- **Progress:** applied 2026-07-02. Chunked scan (per domain/dir, merge-then-assign-IDs, concurrent via P-05 on capable runtimes, chunk list in `summary.md`); smart-merge on rescan (file + function-anchored normalized signature; matched carry status + ID, unmatched-old → `resolved` for one run, new → `pending`); `archive` stays the clean-slate path; chunk-aligned `louie-evaluate <domain>` re-runs merge in without scope-mismatch. `evaluate.md` internals § Scanning at Scale added, Future-Considerations smart-merge removed, BACKLOG entry marked DONE.

### S-05 — Context-read discipline for agents at scale

- **Tier:** Should Fix · **Status:** applied
- **Gap:** every agent's Context section says "read architecture.md / runbook / feature folder" unconditionally. Fine at 5k LOC; at 100k+ those instructions order agents to flood their own context before work starts.
- **Why it matters:** context is the scarce resource; the framework's own lazy-loading principle stops one level too high (it governs which *framework* files load, not how much *project* artifact each agent loads).
- **Recommendation:** single-source a short "Context Discipline" ruleset (per the language-setting precedent: one home, all agents point at it — e.g. in the new execution guideline or `agent-handoffs.md`): index-first (overview / architecture index / codebase map before any full doc), read only the relevant domain doc(s), Grep before Read on source, line-range reads on big files, never bulk-load feature folders.
- **Detail:** `scaling.md` § Read Discipline
- **Touches:** one new guideline section + a one-line pointer in each agent's Context list
- **Progress:** applied 2026-07-02. § Context Discipline in `execution-guidelines.md` (the P-02 home, as designed): index-first, partition reads, Grep-before-Read with line ranges, skim caps (runbook/tech-stack full, rest selective), fix-stale-indexes-don't-compensate. All seven agents point at it with one tailored line.

### S-06 — Monorepo / multi-package story

- **Tier:** Suggestion · **Status:** pending
- **Gap:** open BACKLOG item; one `_LOUIE-output/` per install, no story for backend/frontend/mobile splits.
- **Why it matters:** most 100k+ LOC systems are monorepos; without a convention, users improvise divergent layouts.
- **Recommendation:** stay single-install: one root `_LOUIE-output/`, domains (S-01/S-02/S-03) carry the partitioning, and `tech-stack.md` gains a per-package section (build/test commands per package — Nina and Ava need this). Per-subproject `_LOUIE-output/` only for genuinely independent products in one repo. Document the decision rule; don't build machinery yet.
- **Detail:** `scaling.md` § Monorepo Direction
- **Touches:** `core.md` internals, `tech-stack-template.md`, `project-setup.md`

### S-07 — `louie-status` aggregation command

- **Tier:** Suggestion · **Status:** applied
- **Gap:** open BACKLOG item ("Where am I?"). At 100+ features the absence turns into real navigation cost; `louie-continue` answers "what was I doing," not "what's the state of everything."
- **Why it matters:** the bigger the project, the more sessions start with orientation; today that's manual grepping.
- **Recommendation:** implement as specified in BACKLOG (read-only, no agent, pure aggregation): features by status, aggregated Open Questions, stale in-development docs, recent bugfixes, roadmap deltas. Group output by domain once S-03 lands.
- **Detail:** `scaling.md` § Status Command
- **Touches:** new `louie-status.md` command + registrations (use E-02's generator/lint when adding)
- **Progress:** applied 2026-07-02. `louie-status` — read-only, no agent, pure aggregation (features by status, aggregated Open Questions, stale In-Development docs, recent bugfix rows, roadmap deltas; grouped by domain; index-first + `feature.md`-headers-only per S-05). Registered on all 17 surfaces; lint confirms 24 commands. BACKLOG "Where am I?" absorbed.

---

## Efficiency / Mechanics

### E-01 — Agents ship subagent frontmatter but are never installed or used as subagents

- **Tier:** Critical · **Status:** applied
- **Gap:** every agent file carries Claude Code subagent frontmatter (`name: nina-the-coder`, `tools: …`, `model: sonnet`), but `claude-init.sh` only installs commands to `.claude/commands/` — agents are read inline ("read and follow `coder.md`"), so the entire chain runs in one ever-growing main context.
- **Why it matters:** double loss today. (1) *Context:* by the time Ava runs, the main session carries Tom's interview + Sophie's eval + Nina's whole implementation trail — the top scaling constraint in practice. Subagents give each stage a fresh context seeded by exactly the artifacts LOUIE already produces (the handoff-file design is *already* subagent-shaped). (2) *Capability:* subagent installation is the mechanical prerequisite for every parallel finding (P-03/P-04/P-07).
- **Recommendation:** `claude-init.sh/.bat` additionally copies `_LOUIE_/agents/*.md` to `.claude/agents/`. Dispatch rule (in the P-02 guideline): interactive stages (Tom's interview; Sophie's/Leo's proposal gates in manual mode) stay in the main loop; work stages (Nina, Max, Ava — and Sophie/Leo in auto-pilot no-change/minimal mode) run as subagents during unattended stretches. Inline read-and-follow remains the universal fallback and the manual-mode default, so nothing changes on other runtimes.
- **Detail:** `efficiency.md` § E-01 (and `parallelism.md` § Runtime Layer)
- **Touches:** `claude-init.sh/.bat`, `louie-update-framework.md` (step 4), execution guideline, agent frontmatter review (E-04)
- **Progress:** applied 2026-07-02. `claude-init.sh/.bat` install `_LOUIE_/agents/*.md` → `.claude/agents/` (idempotent; step-4 re-run refreshes automatically; temp-dir verified). Frontmatter review done: Ava gains `Edit, Write, Bash`; Max stays read-only with the orchestrating command owning the fix loop (the design's recommended option); Sophie stays read-only (eval-mode subagent returns changes, orchestrator applies — the flagged watch item, resolved in the dispatch table). Dispatch rules live in `execution-guidelines.md`.

### E-02 — Single-source generation / consistency lint for init scripts + command tables (live bug)

- **Tier:** Should Fix · **Status:** applied
- **Gap:** every command addition hand-edits ~17 surfaces (6 `.sh` + 6 `.bat` init scripts, plus command tables in `CLAUDE.md`, `README.md`, `ai-workflow.md`, `project-setup.md`, root `CLAUDE.md`). The changelog already records one drift bug (swallowed newline from the `louie-continue` rollout); a **second live instance exists right now**: all six `.sh` scripts emit a malformed Key Files bullet — `…how to ask the user to choose- `_LOUIE_/agents/` — agent definitions` (two bullets merged, plus a stray blank line above; e.g. `claude-init.sh:82`).
- **Why it matters:** O(commands × surfaces) hand-editing is the framework's top maintenance tax and its most reliable bug generator; every finding in this evaluation that adds a command pays it again.
- **Recommendation:** a framework-dev-only generator: `_LOUIE-internals/tools/` script that renders the init scripts' command tables + Key Files blocks and the doc command-tables from one manifest (or parses `_LOUIE_/commands/*.md` headers directly). Minimum viable alternative: a `check-consistency.sh` lint that diffs command lists across all 17 surfaces and validates referenced paths exist. Fix the merged-bullet bug either way (check `.bat` variants when fixing — the grep only confirmed `.sh`).
- **Detail:** `efficiency.md` § E-02
- **Touches:** new internals tool, all 12 init scripts (bug fix), `_LOUIE-internals/README.md` (authoring rule: run the lint before committing)
- **Progress:** the live merged-bullet bug was fixed in all 12 scripts on 2026-07-02 (`.sh`: heredoc newline restored; `.bat`: glued `echo` split; stray blank line removed; `claude-init.sh` functionally verified). **Applied 2026-07-02:** consistency lint shipped (`_LOUIE-internals/tools/check-consistency.sh` — see `tools/README.md`); maintainer chose the lint over the generator (generator parked in `BACKLOG.md`). The lint's first run caught further live drift, fixed in the same batch: `/louie-update-framework` absent from all 12 embedded command tables, `louie-evaluate`/`louie-recipe` absent from `project-setup.md` Quick Reference.

### E-03 — Framework versioning: VERSION stamp, cut releases, update-framework delta

- **Tier:** Should Fix · **Status:** applied
- **Gap:** `CHANGELOG.md` has a single ever-growing `## Unreleased` section and nothing else; downstream projects have no version marker at all. `louie-update-framework` step 5 ("show what changed") has no basis for a delta — it can only eyeball diffs. The BACKLOG's template-versioning item has the same root cause.
- **Why it matters:** as downstream projects accumulate, "what changed since I installed" becomes unanswerable; breaking changes (like the per-feature-folder migration) can't be gated on "you're coming from < X."
- **Recommendation:** add `_LOUIE_/VERSION` (semver; ships with the copy), cut the Unreleased section into dated releases, and have `louie-update-framework` compare local vs. pulled VERSION and print the CHANGELOG slice in between — plus trigger version-gated migrations (the old-layout detection becomes "version < 2.0" instead of filesystem heuristics). Bump via the E-02 tooling.
- **Detail:** `efficiency.md` § E-03
- **Touches:** new `_LOUIE_/VERSION`, `CHANGELOG.md` restructure, `louie-update-framework.md`, `core.md` internals (release process)
- **Progress:** applied 2026-07-02. `_LOUIE_/VERSION` = `1.0.0` (maintainer chose fresh semver over continuing the historical `v05.x` tag scheme); first CHANGELOG release section cut; `louie-update-framework` steps 1/2/3/5/6/7 made version-aware with an explicit pre-VERSION fallback; lint check 5 = bump discipline; process in `core.md` § Versioning & Release Process. Remaining manual step: tag `v1.0.0` on `main` at merge.

### E-04 — Remove or justify the `model: sonnet` pin in agent frontmatter

- **Tier:** Suggestion · **Status:** applied
- **Gap:** all seven agents pin `model: sonnet`. Today it's dead metadata (E-01); the moment agents install as subagents it becomes live — and silently downgrades users running stronger session models, while hardcoding a model name that will age.
- **Why it matters:** a user on a top-tier model would get sonnet-quality architecture decisions from Sophie without ever being told.
- **Recommendation:** default to *inherit* (drop the `model:` key). If tiering is wanted, do it deliberately and document it in `core.md` (e.g. keep a cheaper tier for mechanical stages only), and revisit on every framework release (E-03 gives the hook).
- **Detail:** `efficiency.md` § E-04
- **Touches:** all seven `_LOUIE_/agents/*.md` frontmatter, `core.md` internals
- **Progress:** applied 2026-07-02 with E-01 (frontmatter touched once, per the design). `model:` key dropped from all seven agents — inherit the session model; the deliberate-tiering escape hatch and per-release review hook are documented in `core.md` § Agents as Subagents.

### E-05 — Downstream migration path: propagate shape-changing findings through the existing update channels

- **Tier:** Should Fix · **Status:** applied
- **Gap:** the scaling/parallelism findings change artifact shapes (annotated plans, split architecture, new codebase map, new overview column), but nothing specifies how *existing* downstream projects get there. `louie-update-framework` never touches `_LOUIE-output/` by design, so without an explicit path, updated framework behavior meets un-migrated project artifacts.
- **Why it matters:** the framework already has the right propagation channels — wholesale `_LOUIE_/` replace, the step-5 new-canonical-output bootstrap (runbook precedent), the step-6 detect-and-offer-migration hook (`louie-migrate`), and `louie-doc`'s reconcile pass (legacy-overview precedent). Each shape-changing finding must name its channel, or implementers will improvise per-finding and existing projects will drift.
- **Recommendation:** codify the channel mapping and the two rules: (1) **lazy backfill for P-01** — absent annotations degrade to sequential execution (today's exact behavior); completed features are never annotated retroactively, in-flight ones get annotated on next touch (same "no heuristic backfill" principle as the layout migration); (2) **version-gated migrations via E-03** — extend `louie-update-framework` step 6's detection list (architecture.md over threshold → offer split), add the architecture-split case to `louie-migrate`, add the `Depends on` column to `louie-doc`'s reconcile, and bootstrap `codebase-map.md` through step 5.
- **Detail:** `efficiency.md` § E-05
- **Touches:** `louie-update-framework.md` (steps 5–6), `louie-migrate.md`, `louie-doc.md` (reconcile), the P-01 spec (degradation rule), E-03 (version gating)
- **Progress:** applied 2026-07-02 — not a batch of its own; its channel mapping shipped inside each shape-changing finding, as designed. P-01 lazy-backfill/degradation rule written into the feature-template spec (batch 3). E-03 version-gating in `update-framework` (batch 2). S-01 architecture split via `louie-migrate architecture` + step-6 detection; S-02 codebase-map bootstrap via step 5 (batch 6). P-04 `Depends on` reconcile column in `louie-doc` (batch 7). S-03 grouping/`Retired` is the `louie-doc` reconcile pass itself (batch 8). All four channels exercised; nothing left open.
