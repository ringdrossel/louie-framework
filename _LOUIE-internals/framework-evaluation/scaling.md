# Scaling to 100k+ LOC — Deep Design (S-01 … S-07)

How LOUIE's artifact layer keeps working when the codebase is large. Target scenario (agreed with the maintainer): **solo/small team driving LOUIE on a big repo** — not multi-human enterprise process. The recurring move throughout: the same one that already fixed `implementations/` — *slim index up top, partitioned detail below, lazy-load the partition you need.*

## The Scale Failure Modes

At ~100k LOC / ~100+ features, four things break, all rooted in "artifact = one file that fits in context":

1. `architecture.md` becomes a multi-thousand-line brick every agent is told to read in full (S-01).
2. Nothing maps intent to code — agents *find* code by scanning, burning context before work starts (S-02).
3. The `overview.md` Features table stops being a usable index (S-03).
4. `louie-evaluate` can't scan the repo in one pass, and rescans throw away hundreds of triage decisions (S-04).

Plus a behavioral one: agents are instructed to read everything regardless of size (S-05).

## Partitioned Architecture (S-01)

### Shape

```
_LOUIE-output/
├── architecture.md              slim index (always read)
└── architecture/
    ├── <domain>.md              per-domain detail (read when working in that domain)
    └── ...
```

- **Index keeps:** the system-level mermaid diagram, the domain list (one line each: name, responsibility, path roots, link), cross-domain dependency rules (what may call what), cross-cutting concerns (auth, logging, error handling, config), deployment topology, system-level ADR pointers.
- **Domain doc keeps:** internal layers/patterns, data flow, folder structure, domain-scoped ADRs, integration points with other domains (named, so the reader knows which *other* domain doc matters).
- **Domain = the partition key everywhere.** The same domain names organize `architecture/`, the codebase map (S-02), the overview grouping (S-03), and evaluate chunks (S-04). One vocabulary, defined once in the architecture index.

### Trigger and mechanics

- Universal-from-day-one is wrong here (unlike per-feature folders): a 5k-LOC project's architecture genuinely is one file, and a forced folder adds list-then-read cost. So: **threshold-triggered, Sophie-proposed.** When `architecture.md` crosses ~400 lines or ~6 domains, Sophie proposes the split on her next run (subsequent-run step 3 gains a size check). It's a mechanical restructure — content moves, nothing is rewritten — so under auto-pilot it's still a *material* change (new file shape) and pauses for approval.
- Splitting is one-way, like `louie-migrate`. Cross-reference rewrite follows the migrate algorithm (it's the same job one level up); consider folding into `louie-migrate` as a second detection case rather than a new command.
- **Reader updates:** every agent Context list changes from "read `architecture.md`" to "read `architecture.md`; if an `architecture/` folder exists, also read the domain doc(s) for the code you're touching." `louie-evaluate` LOUIE-mode lens: architecture-compliance checks run per-domain against the domain doc.

## The Codebase Map (S-02)

`louie-evaluate` already invented this artifact for non-LOUIE projects (`codebase-map.md`: stack, layout, entry points, size signals) — then throws it away. Large LOUIE projects need it permanently.

### Shape (strictly an index — no prose)

```markdown
# Codebase Map

Last reconciled: YYYY-MM-DD (louie-doc)

| Domain | Path roots | Entry points | Owning features | Size |
|--------|-----------|--------------|-----------------|------|
| auth   | src/auth/**, src/middleware/session.ts | src/auth/index.ts | auth, oauth-login | ~4.2k LOC / 31 files |
| ...    |           |              |                 |      |

## Largest files (top 10)
## External surface (ports, queues, webhooks — pointer to runbook)
```

- **Lifecycle:** Sophie creates it at setup/import when the project is already large, or when proposing the S-01 split (same threshold — the two artifacts are siblings). Nina appends a row/edit when she adds a module or new path root (one line in `coder.md` step 4). `louie-doc`'s reconcile pass regenerates the mechanical columns (size, file counts) and flags rows whose paths no longer exist.
- **Why not fold into architecture.md:** the map is *descriptive* (what is where, measured) and churns with every feature; architecture is *prescriptive* (what should be where, stable). Mixing them makes agents re-read stable content to get volatile facts.
- **Payoff:** "where is X handled?" becomes map-row → domain doc → 2–3 targeted file reads, instead of a repo scan. Also the chunk list for S-04 and the `Owning features` column answers the reverse-traceability question (file → feature) that otherwise needs grepping every `feature.md` Code Structure section.

## Index Scaling (S-03)

Three stages, each triggered by size, applied by `louie-doc`'s reconcile pass (which already owns overview hygiene):

1. **< ~30 features:** today's flat table. No change.
2. **~30–100:** one table per domain (`### auth`, `### billing` sections), same columns + the new `Depends on` column (P-04). Triage reads one section.
3. **> ~100:** per-domain overview files (`implementations/overview/<domain>.md`) + a top `overview.md` listing domains with counts and in-flight items. Same move as everything else.

**`Retired` status** (absorbs the BACKLOG "deprecation path" item): terminal status after `Tested`; the row moves to a collapsed `### Retired` section (stage 2+) with a one-line reason. The feature folder stays on disk (history, bugfix docs remain searchable) but drops out of triage. Set via `louie-doc` or a one-liner in `louie-roadmap-change` style; agents skip Retired rows when scanning for context.

## Evaluate at Scale (S-04)

Two changes, one command:

1. **Chunked scan.** Scope the scan per domain (codebase-map rows) or per top-level directory when no map exists. Each chunk is a self-contained Max pass producing raw findings; the orchestrator merges chunks, dedupes cross-chunk duplicates (same rule violated across domains stays per-file, so dedup is rare), and assigns IDs once, after the merge — IDs must stay stable and dense. On capable runtimes chunks run concurrently (P-05); otherwise sequentially — either way the context ceiling per pass is bounded by chunk size, not repo size. `summary.md` records the chunk list so `continue` and rescans use the same partition.
2. **Smart-merge on rescan** (promote from BACKLOG — the deferral condition "users feel the re-triage pain" is met by definition at this scale). Match old→new findings by `file` + normalized signature (category + the offending construct's text, whitespace-collapsed, anchored to the nearest enclosing function/class name so line drift doesn't break the match). Matched: carry status (`applied`/`skipped`/`deferred`/`modified`) forward. Unmatched old: status `resolved` (kept in a Resolved section for one run, then dropped). New: `pending`. Chunking makes this tractable: matching runs per-chunk, not repo-wide.

Bonus at scale: chunked rescans allow `louie-evaluate <domain>` re-runs that merge into the whole-repo findings set instead of tripping the scope-mismatch warning.

## Read Discipline (S-05)

Single-sourced ruleset (in `execution-guidelines.md` per P-02, or `agent-handoffs.md` § Context if that guideline doesn't land first); each agent's Context section gets a one-line pointer instead of its own copy — the language-setting precedent, chosen deliberately to avoid the scatter-drift bug it fixed.

The rules:

1. **Index-first, always:** `implementations/overview.md`, the architecture index, and the codebase map are read *before* any full document; they tell you which partitions matter.
2. **Partition reads:** read the domain doc(s) and feature folder(s) for the code you're touching — never the whole `architecture/` folder, never multiple feature folders "for context."
3. **Grep before Read** on source: locate by search, then read the located region (line-range reads on files > ~500 lines).
4. **Skim caps:** runbook and tech-stack are read in full (they're capped by design); everything else is read selectively at scale.
5. **When an index is missing or stale, say so** — fix the index (or flag it) rather than compensating with bulk reads every session.

## Monorepo Direction (S-06)

Decision rule to document in `core.md` (design direction only — no machinery yet):

- **Default: one `_LOUIE-output/` per repo**, even for monorepos. Domains (S-01/S-02/S-03) carry the backend/frontend/mobile partitioning; features regularly span packages (an API + UI feature is *one* feature), and a per-package split would force cross-cutting features into two half-artifacts. `tech-stack.md` gains a per-package subsection (build/lint/test commands per package — Nina's step 3 and Ava depend on knowing *which* package's commands to run; work-package `Files:` scopes make the mapping mechanical).
- **Exception: genuinely independent products** sharing a repo (separate deploys, separate users, near-zero shared code) → per-product `_LOUIE-output/` in each product root; commands operate on the nearest `_LOUIE-output/` above the working path. This is the "each subproject can have its own" note from `scaling.md` internals, made into an explicit either/or with a decision rule instead of an open question.

## Status Command (S-07)

Implement per the BACKLOG sketch, unchanged in spirit: read-only, no agent, pure aggregation — features by status, aggregated `Open Questions`, stale `In Development` docs (no Change History entry in N days), recent bugfix rows, roadmap deltas. Two scale-specific additions: group by domain (S-03 vocabulary), and read only indexes + `feature.md` headers (Status/Change History tail) so the command itself respects S-05 and stays cheap at 150 features.

## What's Explicitly Out of Scope

- Multi-human process (artifact ownership, review policy, audit) — different scenario than agreed.
- Numeric context budgets ("max N tokens per read") — unenforceable prompt-level; the discipline rules are the enforceable form.
- Auto-splitting architecture without user approval — the split is one-way and shape-changing; it stays gated.

## Implementation Order

S-05 (cheap, immediate) → S-01 + S-02 together (shared threshold, shared domain vocabulary) → S-03 (needs the vocabulary) → S-04 (needs the map for chunks) → S-07 → S-06 (document the rule when first asked).
