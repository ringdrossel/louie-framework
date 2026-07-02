# louie-evaluate

When the user says **`louie-evaluate`**, follow this procedure to assess an existing codebase against LOUIE's coding standards (code quality, dead code, DRY violations, over-engineering, security baseline) and produce persistent markdown findings that can drive a step-by-step correction loop.

This is a **read-only assessment** by default. Source code is only modified during the optional Phase 2 apply loop, and only when the user approves each change (or chooses apply-all upfront).

## When to Use

- You're handed a codebase from another developer or AI and want to know if it meets LOUIE's standards before adopting it.
- You suspect a project has accumulated dead code, duplication, or needless abstractions.
- You want a triaged list of issues you can work through later (the findings persist across sessions).

`louie-evaluate` is **not** the same as `louie-review`:

| | `louie-review` | `louie-evaluate` |
|---|---|---|
| Scope | one feature in a LOUIE project | whole codebase (or a specified subpath) |
| Output | session-time chat findings | persistent files in `_LOUIE-output/evaluation/` |
| Apply loop | no | yes (optional) |
| Works on non-LOUIE projects | no | yes |

## Procedure

### 1. Detect mode

- **LOUIE project** if `_LOUIE-output/architecture.md` exists. Use the project's own `architecture.md`, `tech-stack.md`, `runbook.md`, and `_LOUIE_/guidelines/coding-guidelines.md` as the standards lens. If the architecture is partitioned (`_LOUIE-output/architecture/` exists), architecture-compliance checks run **per domain against the domain doc**, with the index supplying the cross-domain dependency rules. If `_LOUIE-output/codebase-map.md` exists, hand it to Max as orientation — no re-scan needed for layout/size context.
- **Non-LOUIE project** otherwise. Use `_LOUIE_/guidelines/coding-guidelines.md` as the standards lens. Sophie does a light structural pass first (next step).

Tell the user which mode was detected and continue.

### 2. Handle existing evaluation

If `_LOUIE-output/evaluation/summary.md` already exists:

- Read it and tally findings by status (`pending`, `applied`, `skipped`, `deferred`, `modified`).
- Ask the user:
  ```
  Existing evaluation found at _LOUIE-output/evaluation/ (from <date>).
    <N> findings: <X> applied, <Y> skipped, <Z> deferred, <P> pending.

  What would you like to do?
    [c]ontinue   skip scan, resume apply phase using existing findings
    [r]escan     re-analyze codebase, smart-merge onto existing statuses
    [a]rchive    move existing to evaluation/archive/<YYYY-MM-DD>/, then rescan fresh
    [q]uit
  ```
- Default = `continue` if there are `pending` or `deferred` findings, otherwise `rescan`.
- If the user picks `archive`, move the existing files (excluding any prior `archive/` folder) into `_LOUIE-output/evaluation/archive/<YYYY-MM-DD>/` then proceed to scan **fresh** (no merge — the archive is the clean-slate option).
- If the user picks `continue`, jump to Step 6.

**Smart-merge on rescan.** `rescan` no longer discards triage decisions. After the new scan produces raw findings (Step 5), match each against the prior findings set **before** assigning IDs:

- **Match key:** `file` + a normalized signature (category + the offending construct's text, whitespace-collapsed, anchored to the nearest enclosing function/class name so line drift doesn't break the match). Matching runs per-chunk, so it stays tractable at scale.
- **Matched** → carry the prior status forward (`applied` / `skipped` / `deferred` / `modified`), keeping the prior ID.
- **Unmatched old** (in prior set, not re-found) → status `resolved`; keep in a `## Resolved` section for one run, then drop on the following rescan.
- **New** (re-found, no prior match) → `pending`, fresh ID appended after the highest existing.

This means a re-run on a 100k-LOC repo re-triages only genuinely new findings, not hundreds of already-decided ones.

### 3. Determine scope

- If the user passed a path (e.g. `louie-evaluate src/api`), evaluate only that path. Record it in `summary.md` so future runs can detect a scope mismatch.
- **Domain re-scan (chunk-aligned):** if the passed path matches a **chunk** recorded in `summary.md`'s chunk list (e.g. `louie-evaluate <domain>` or a top-level dir the last whole-repo run scanned), treat it as a targeted re-scan of that chunk and **smart-merge its findings into the existing whole-repo set** — don't warn about scope mismatch, and don't touch other chunks' findings. This is the cheap "I just refactored auth, re-check only auth" path.
- If a previous evaluation had a genuinely different scope (not a chunk of it) and the user picked `rescan`/`archive`, warn explicitly before proceeding — don't silently mix scopes.
- Otherwise evaluate the whole repo, excluding obvious ignore paths (`node_modules/`, `.git/`, `dist/`, `build/`, `target/`, `vendor/`, `.next/`, `__pycache__/`, etc.).

### 4. Sophie pass (structural — non-LOUIE mode only)

Skip this step in LOUIE mode (the project's own `architecture.md` already covers structure).

In non-LOUIE mode:

- Read and follow `_LOUIE_/agents/architect.md`. Tell Sophie this is **evaluate mode** — she is NOT producing a full architecture document. She is producing a lightweight `_LOUIE-output/evaluation/codebase-map.md` using `_LOUIE_/templates/codebase-map-template.md` (same shape as the canonical map a large LOUIE project maintains), plus the detected stack and external dependencies from manifests.
- This file gives Max enough context to evaluate without re-scanning. If the user later runs `louie-import`, this map can be promoted to `_LOUIE-output/codebase-map.md` as-is.

### 5. Max pass (standards)

**Chunked scanning (large codebases).** Don't assume the whole repo fits one pass. Scope the scan into chunks — **one per domain** (from `_LOUIE-output/codebase-map.md` rows, or `architecture.md` domains) or **per top-level directory** when no map exists. Each chunk is a self-contained Max pass producing raw findings against its slice. On a capable runtime the chunks run **concurrently** (read-only, no conflict — see `_LOUIE_/guidelines/execution-guidelines.md` § Read Fan-Out); otherwise sequentially. Either way the context ceiling per pass is bounded by chunk size, not repo size. **Merge all chunks' raw findings first, then assign IDs once** (IDs must stay stable and dense — never assign per-chunk). Cross-chunk duplicates are rare (the same rule violated in two domains stays per-file) — dedupe only exact file:line repeats. Record the chunk list in `summary.md` so `continue` and rescans reuse the same partition. A small repo is simply one chunk — no behavior change.

Read and follow `_LOUIE_/agents/reviewer.md`. Tell Max this is **evaluate mode**. The standard Max review is the lens; evaluate-mode adds:

- **Cross-codebase categories** (not just per-feature): code quality, dead code, DRY, over-engineering — produced as separate output files (Step 6).
- **No feature-doc context** (in non-LOUIE mode) — Max evaluates against the codebase as-is using `_LOUIE_/guidelines/coding-guidelines.md`.
- **No chat-only constraint** — findings go to files (the storage convention in `reviewer.md` is for `louie-review`; this command produces persistent artifacts on purpose).

Max produces findings in three tiers — **Critical**, **Should Fix**, **Suggestions** — across these categories:

- **Code quality** — naming clarity, function size (>30 lines), file size (>800 lines), magic numbers, comment hygiene, error-handling patterns, readability, complexity hotspots
- **Dead code** — unreferenced exports, unused files, unused dependencies, commented-out code blocks, unreachable branches
- **DRY violations** — duplication clusters with file:line evidence
- **Over-engineering** — needless abstractions, premature flexibility, single-implementation interfaces, unused configuration knobs, speculative generality
- **Security baseline** — hardcoded secrets, missing input validation, unparameterized queries, weak auth flows
- **Architecture compliance** — LOUIE mode only: deviations from `architecture.md`
- **Runbook coverage** — LOUIE mode only: drift between code and `runbook.md` (new ports/env/services not reflected)

For each finding, Max records:
- **Category** (one of the above)
- **Tier** (Critical / Should Fix / Suggestion)
- **File and line(s)**
- **What's wrong** (specific)
- **Why it matters** (impact)
- **Suggested fix** (actionable)
- **Status** — initialized as `pending`

### 6. Write evaluation files

Write to `_LOUIE-output/evaluation/`:

- **`summary.md`** — verdict, tally by tier and category, scope (whole repo or subpath), mode (LOUIE / non-LOUIE), prioritized next-step list. Includes a Status section that survives across runs (counts of pending/applied/skipped/deferred/modified).
- **`findings.md`** — every finding with full detail, sorted by tier then category. Each finding has a stable ID (e.g. `F001`, `F002`) used by the apply loop.
- **`code-quality.md`** — code-quality findings only.
- **`dead-code.md`** — dead-code findings only.
- **`dry-violations.md`** — duplication clusters.
- **`over-engineering.md`** — over-engineering findings only.
- **`codebase-map.md`** — non-LOUIE mode only (from Sophie's pass).

**Per-category file rule:** the four high-volume categories (**code quality**, **dead code**, **DRY violations**, **over-engineering**) get dedicated files because they're the categories that typically accumulate dozens of findings on a real codebase, and lazy-loading one of them in a follow-up session is genuinely useful. The lower-volume categories (**security**, **architecture compliance**, **runbook coverage**) live only in `findings.md` — splitting them out tends to produce near-empty files. If a real project ever generates 30+ findings in one of those low-volume categories, split that file out at evaluation time; don't write a stub file by default.

**Small-project collapse:** if total findings are below ~15, write a single `evaluation.md` instead of the split files. `summary.md` still exists pointing at it.

**File size cap:** if any of the per-category files would exceed 800 lines, split by directory or feature within that file (don't violate Max's own checklist).

### 7. Phase 2 prompt — choose apply mode

Once files are written, **ask as a structured choice** — use your runtime's structured-choice tool if it has one, otherwise a lettered list (see `_LOUIE_/guidelines/interaction-guidelines.md`). Put the count **inside the question itself** — a dialog hides any text sharing its response, so a count reported "before" the ask is never seen. Question: "Apply now? (`<N>` findings: `<C>` Critical, `<S>` Should Fix, `<U>` Suggestions)" Options:

- `walkthrough` — step-by-step approval *(default)*
- `apply-all` — apply every finding without per-finding prompts (Critical + Should Fix + Suggestions)
- `no` — exit, files saved, decide later

Default = `walkthrough`. If the user picks `no`, exit cleanly — they can resume later by running `louie-evaluate` again and choosing `continue`.

### 8a. Walkthrough loop

For each finding in `pending` or `deferred` status, sorted by tier (Critical → Should Fix → Suggestions) then by file:

- Show the finding and ask in **one plain-text message with a lettered list** — in this loop, prefer the lettered fallback even on runtimes with a structured-choice tool: a dialog would hide the finding it asks about, and a two-turn gate per finding doubles every round-trip (see `_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second — plain text hides nothing). Only use the structured-choice tool if the finding was presented in a *previous* response:
  ```
  [<i>/<N>] <Tier> · <Category> · <file:line>
    Issue: <what's wrong>
    Why:   <impact>
    Fix:   <suggested fix>
  ```
  Options: `apply` / `modify` / `skip` / `defer` / `quit`.
- **apply** → route per the "Routing applied changes" section below. On success, set status to `applied` and update `summary.md`.
- **modify** → ask "What variation?" Re-present the proposed fix, then re-prompt. Once accepted, route as apply, but record status as `modified` with a one-line note of the variation in `findings.md`.
- **skip** → set status to `skipped`. Decision is final unless rescan.
- **defer** → leave status as `pending` or move to `deferred`. Picked up on the next run.
- **quit** → save progress (status updates already persisted), exit.

Persist status changes to `findings.md` and the per-category file as you go (so a crash or quit doesn't lose progress).

After the loop ends, update `summary.md` with the latest status tally and append a "Run history" entry: `<date>: walkthrough — <X> applied, <Y> skipped, <Z> deferred, <M> modified`.

### 8b. Apply-all loop

Same iteration order, but no per-finding prompt. For each `pending`/`deferred` finding:

- Route per the "Routing applied changes" section below.
- On success, mark `applied`.
- On failure (build break, test failure, cannot-determine fix), pause and ask:
  ```
  Apply failed for finding <id>: <error>.
    [r]etry with modification  [s]kip  [q]uit
  ```

After the loop, update `summary.md` with the run-history entry and a single end-of-run report.

### 9. Routing applied changes

The apply step does NOT bypass LOUIE's gates. Route by mode:

**LOUIE mode:**

- **Real bug** (code is incorrect, not just stylistically poor) → drop into `louie-bugfix`. Nina creates the per-fix doc, updates the runbook (gotcha), updates `bugfixes/overview.md`, and adds the Change History entry on `feature.md`. Reference the evaluation finding ID in the bugfix doc's Symptoms section.
- **Code-quality cleanup** under 50 lines and contained in one feature → drop into `louie-update`. Nina implements, runs lint/build, appends a Change History entry referencing the evaluation finding ID.
- **Code-quality cleanup over 50 lines** or touching multiple features → escalate per `louie-update`'s rules: stop and recommend `louie-extend` (or split the finding into smaller ones the user can apply separately). In **apply-all** mode there is no stop — apply directly, run lint/build, and append a Change History entry to every affected `feature.md` referencing the evaluation finding ID.
- **Cross-cutting refactor** (rename, dependency removal, structural change touching multiple features) → apply directly, run lint/build, and append a Change History entry to every affected `feature.md`. No per-finding confirmation in either walkthrough or apply-all (walkthrough already gates per-finding; apply-all is opted-in unattended).

**Non-LOUIE mode:**

- Warn once at the start of the apply phase:
  > "This project isn't a LOUIE project, so applied changes won't produce feature docs / bugfix records. For full tracking, run `louie-import` first to onboard the project. Continue without import?"
- If the user continues, apply changes directly (lint and build after each apply if available). No LOUIE artifact updates because there are no LOUIE artifacts.
- After the apply phase, recommend `louie-import` again as a follow-up so future work is tracked.

### 10. Wrap up

- Tell the user where the evaluation lives and what's next.
- If any findings remain `pending` or `deferred`, remind the user they can resume with `louie-evaluate` (`continue` mode).
- If LOUIE-mode and all Critical findings are resolved, mention they can now run `louie-review` per-feature for a deeper feature-by-feature pass.
- If non-LOUIE-mode and findings were applied without import, surface the import recommendation again.

## Constraints

- **No source code modifications outside the apply loop.** Phase 1 is pure analysis.
- **No silent overwrite of existing evaluation files.** Always ask (`continue` / `rescan` / `archive`).
- **No new agent.** Sophie + Max + Nina (apply-time only) are reused.
- **No new LOUIE-output category outside `evaluation/`.** All artifacts live there.
- **Every applied finding routes through an existing flow** (`louie-bugfix`, `louie-update`, or direct edit in non-LOUIE mode). The Three Critical Rules stay intact.
- **Apply-all does not skip routing.** It only skips the per-finding prompt — Nina, the lint/build step, and the gate routing all still happen. Failures still pause for `[r]etry / [s]kip / [q]uit`.

## Usage

```
louie-evaluate
```

Restrict scope to a subpath:

```
louie-evaluate src/api
louie-evaluate packages/core/src
```

Resume an in-progress evaluation:

```
louie-evaluate
# (existing files detected — pick [c]ontinue at the prompt)
```

Force a fresh scan and archive the prior run:

```
louie-evaluate
# (existing files detected — pick [a]rchive at the prompt)
```
