# Evaluate System Design

How LOUIE assesses an existing codebase against its standards and produces a persistent, actionable findings set. Read this when changing `louie-evaluate`, the evaluation output schema, or the apply-loop routing.

## Why It Exists

`louie-review` only works *inside* a LOUIE project, *per feature*, with chat-only output. That's the right shape for a merge-time gate, but it doesn't cover the case the maintainer hits often:

> "I have a codebase from another dev or AI. Does it meet my standards? Where would I start fixing it?"

That's a **whole-codebase triage** with **persistent output** that drives a **step-by-step correction loop**. It's a different task with a different shape — hence a separate command instead of a `louie-review` flag.

## Distinction from `louie-review`

| | `louie-review` | `louie-evaluate` |
|---|---|---|
| Project requirement | LOUIE project | LOUIE or non-LOUIE |
| Scope | one feature | whole codebase or subpath |
| Standards lens | project's `architecture.md` + `coding-guidelines.md` | `coding-guidelines.md` (+ `architecture.md` if LOUIE) |
| Output | session-time chat | persistent files in `_LOUIE-output/evaluation/` |
| Apply loop | no (separate Nina invocation) | yes (built-in) |
| Re-runnable | not applicable (chat) | yes (preserves status) |
| Gates | gate before merge | gate per finding |

The two commands deliberately don't share output — review files are not re-introduced via `louie-evaluate`. The reviewer.md "Storage convention" block (no standalone review files) still holds for `louie-review`. `louie-evaluate` produces persistent files because **its job is producing persistent files** — they're the artifact the user wanted in the first place.

## Two Modes

### LOUIE Mode

`_LOUIE-output/architecture.md` exists. The project is already onboarded into LOUIE.

- Sophie's structural pass is **skipped** — `architecture.md` and `runbook.md` are the source of truth for structure.
- Max evaluates against `architecture.md` (compliance), `runbook.md` (drift), `tech-stack.md` (toolchain), and `coding-guidelines.md` (quality).
- Apply phase routes through `louie-bugfix` (bugs) or `louie-update` (small cleanups). Each applied finding produces proper LOUIE artifacts (bugfix doc, runbook update, Change History entry).
- The `louie-import` recommendation is **not** surfaced (the project is already a LOUIE project).

### Non-LOUIE Mode

No `_LOUIE-output/architecture.md`. The project is unknown to LOUIE.

- Sophie's structural pass produces `_LOUIE-output/evaluation/codebase-map.md` — a lightweight stack/layout/entry-point/size snapshot. Just enough context for Max.
- Max evaluates against `coding-guidelines.md` only — no architecture-compliance category, no runbook-drift category.
- Apply phase warns once that changes won't produce LOUIE artifacts and recommends `louie-import` for tracking.
- Findings still produce the same files; they just have fewer category buckets populated.

The mode dispatch is on `_LOUIE-output/architecture.md` presence, not `_LOUIE_/` presence — a project may have the framework copied in (init script ran) without having gone through `louie-setup` or `louie-import` yet. In that state, `louie-evaluate` should still run; it just runs in non-LOUIE mode and recommends import as the follow-up.

## Output Schema

```
_LOUIE-output/evaluation/
├── summary.md              verdict, scope, mode, tally, prioritized next-steps, run history, status
├── findings.md             every finding with full detail, sorted by tier then category, stable IDs (F001+)
├── code-quality.md         code-quality findings only
├── dead-code.md            dead-code findings only
├── dry-violations.md       duplication clusters
├── over-engineering.md     over-engineering findings only
├── codebase-map.md         non-LOUIE mode only — Sophie's structural snapshot
└── archive/                optional, populated when user picks [a]rchive on rescan
    └── <YYYY-MM-DD>/
        └── (prior run's files)
```

### Why Multiple Files

- **Lazy-loading.** A follow-up session can read just `summary.md` and pull `dry-violations.md` only if acting on duplication. The whole evaluation never enters context unless the user is acting on the whole evaluation.
- **Different consumers.** The maintainer reads `summary.md` for the verdict; an AI in the apply loop reads `findings.md` for status and IDs; a refactor session might read `dry-violations.md` exclusively.
- **AI-efficiency criterion** (per `_LOUIE-internals/scaling.md`).

### Which Categories Get Their Own File

Only the four high-volume categories — **code quality**, **dead code**, **DRY violations**, **over-engineering** — get dedicated per-category files. The lower-volume categories (**security**, **architecture compliance**, **runbook coverage**) live in `findings.md` only. The lazy-loading benefit only justifies a split when the file actually contains volume; near-empty per-category files are noise. If a real project ever generates 30+ findings in one of the low-volume categories at scan time, split it out then. Don't write stub files by default.

### Small-Project Collapse

For codebases with < ~15 findings, the per-category split is overkill — collapse to a single `evaluation.md` with `summary.md` pointing at it. The threshold is heuristic; pick what reads better.

### Stable Finding IDs

Each finding gets `F001`, `F002`, … assigned at scan time. IDs are **stable across files** — the same finding in `findings.md` and `code-quality.md` shares the ID. Apply-loop status updates reference the ID. On rescan with overwrite, IDs are reassigned (no merge in v1; see "Future Considerations" below).

### Status Lifecycle

```
pending  ──► applied
         ──► modified  (variation accepted, then applied)
         ──► skipped   (final unless rescan)
         ──► deferred  (re-surfaces on next continue)
```

`pending` and `deferred` are the only states the apply loop iterates over. `applied`, `skipped`, `modified` are stable.

## Re-Run Behavior

When `_LOUIE-output/evaluation/summary.md` exists:

- **continue** — skip scan, jump straight to the apply loop using existing findings. This is how the user picks up deferred items or finishes a walkthrough they paused.
- **rescan** — overwrite all files. **All status is lost** in v1 (see Future Considerations for smart-merge). The `archive` option exists precisely so the user can preserve a prior run before redoing.
- **archive** — move existing files into `archive/<YYYY-MM-DD>/`, then rescan fresh.
- **quit** — exit without doing anything.

Default is `continue` if there's pending/deferred work, `rescan` otherwise. The default is informational, not prescriptive — show counts so the user can decide.

### Scope Mismatch

If the prior run was scoped (e.g. `louie-evaluate src/api`) and the new run targets a different scope, prompt explicitly. Don't silently mix scopes. The scope is recorded in `summary.md` for this check.

## Phase 2 — Apply Modes

Three options at the apply prompt:

- **walkthrough** (default) — per-finding apply/modify/skip/defer/quit. Highest control, slowest.
- **apply-all** — apply every pending/deferred finding (all three tiers, including Suggestions) without per-finding prompts. The user explicitly opted in upfront, so Suggestions are included; there's no "all-tiers-plus" variant.
- **no** — exit. Files are saved. User can resume later.

### Apply-all and Suggestions

Suggestions are included in apply-all by design (user choice). The user opted into unattended application; the only safety net is the **failure pause** — any apply that fails (build break, test fail) pauses and asks `[r]etry / [s]kip / [q]uit` before continuing. Cross-cutting refactors are NOT specially gated in apply-all; the upfront opt-in covers them.

### Apply Routing

Applying a finding does **not** bypass LOUIE's Three Critical Rules. The routing matrix:

| Mode | Finding type | Route |
|---|---|---|
| LOUIE | Real bug | `louie-bugfix` flow |
| LOUIE | Code-quality cleanup, < 50 lines, single feature | `louie-update` flow |
| LOUIE | Code-quality cleanup, > 50 lines or multi-feature | escalate per `louie-update` rules (stop, recommend `louie-extend`) |
| LOUIE | Cross-cutting refactor (multi-feature) | direct edit + Change History entry on every affected `feature.md` |
| Non-LOUIE | Any | direct edit + lint/build (warn once about no LOUIE tracking) |

The apply step is the gate. Each applied change passes through the existing gated flow that produces the right artifacts. The evaluation finding ID is referenced in the bugfix doc / Change History entry so the trail is preserved.

## Agent Reuse

`louie-evaluate` reuses **Sophie**, **Max**, and **Nina** (the latter only at apply-time). No new agent. Reasons:

- Sophie's structural-inference skill (used in `louie-import`) is exactly what evaluate-mode needs; the prompt variant just narrows the output to `codebase-map.md`.
- Max's review checklist *is* the standards lens. The categories (code quality, dead code, DRY, over-engineering, security) all live in `coding-guidelines.md` already.
- Nina applies fixes the same way she does for bugfixes and updates.
- Adding an "Evaluator" agent would force every downstream surface (handoffs, init scripts, README) to grow a row for a behavior that's a prompt variant, not a role.

The command is responsible for telling each agent it's in evaluate-mode and pointing them at the right outputs.

## Confirmation Gates

`louie-evaluate` doesn't introduce new gates. The architecture confirmation gate doesn't apply (no architecture is being produced). The feature-doc gate doesn't apply (no feature work is starting).

The apply phase **inherits** the gates of the flows it routes through (`louie-bugfix`, `louie-update`). In walkthrough mode, the per-finding prompt is itself a gate — every change is user-approved.

In apply-all mode, the upfront opt-in is the gate. The user explicitly chose unattended application; the failure pause is the only safety net.

## What Evaluate Does NOT Do

- Does not produce architecture, tech-stack, or runbook docs (that's `louie-import`'s job).
- Does not modify source code in Phase 1.
- Does not silently overwrite prior evaluations.
- Does not produce per-feature `feature.md` files in non-LOUIE mode.
- Does not run Leo, Ava, Tom, or Ivy. None apply to assessment work.

## Future Considerations

- **Smart merge on rescan.** Carry status forward when a finding's file:line + signature matches a prior finding. New findings start `pending`. Findings no longer present move to `resolved`. Real work — added to `BACKLOG.md`.
- **Custom standards source.** Today the lens is always `_LOUIE_/guidelines/coding-guidelines.md`. A `--standards <path>` flag for non-LOUIE projects with their own standards. Defer until requested.
- **Severity scoring vs. tier tally.** Only tier counts for now. Numeric scores invite arguing about formulas.
- **Cross-LOUIE-project comparison.** When a user has multiple LOUIE projects, an aggregate "which project needs work first?" view. Not the current command's job; would be a `louie-portfolio` or similar.
- **Test-coverage signal.** Today the evaluation only reads source. Pulling coverage data (per Ava) would surface untested hotspots. Out of scope for v1.
