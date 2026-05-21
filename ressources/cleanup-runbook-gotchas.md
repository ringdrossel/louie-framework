# LOUIE runbook cleanup — drain the Common Gotchas section

Paste-ready prompt for retrofitting a LOUIE-using project to the new runbook policy: the runbook is operational-only; the accumulating `Common Gotchas` section is removed; existing entries are reclassified to the right home (inline operational notes, code-local `// WHY` comments, per-feature `bugfixes/<slug>.md` Detect/Avoid sections, or simply deleted).

## Usage

1. Open a Claude session inside the target project (the one whose `_LOUIE-output/runbook.md` you want cleaned, not the framework repo).
2. Paste the prompt below verbatim.
3. Review the reclassification proposal at Step 2 before approving — for many entries there's a judgment call between "still operational" and "really just a dev-time learning, delete or move to bugfix-doc".
4. The prompt does **not** open a PR or merge — review the branch diff first.

### Optional loosening

If the project's `Common Gotchas` is short and you trust the agent's classification, change Step 2's last line to `Proceed without per-entry approval; show me the final tally at the end.` to skip the gate.

---

## The prompt

```
Please clean up this project's `_LOUIE-output/runbook.md` to match the new
LOUIE policy: the runbook is operational reference only — ports, env vars,
external services, common commands, first-check debugging. The
accumulating `Common Gotchas` section is removed. Existing entries get
reclassified to the right home, not just deleted.

Work on a new branch named `chore/runbook-drop-gotchas` so nothing lands
on main directly. Do NOT change runtime behaviour; this is a docs +
comments pass.

## Step 0 — Sync the framework

If this project vendors `_LOUIE_/` (the framework dir), update it to the
latest version on the framework repo's `main`. If unsure, ask me before
overwriting. If `_LOUIE_/` is missing or symlinked to a shared install,
skip this step.

Confirm the runbook template at `_LOUIE_/templates/runbook-template.md`
no longer has a `## Common Gotchas` section. If it still does, the
framework update didn't land — stop and surface that.

## Step 1 — Inventory

Open `_LOUIE-output/runbook.md` and list every entry under `## Common
Gotchas` (including any nested "Resolved" subsection). Number them. For
each entry capture: date, title, the symptom/detect text, the
avoid/fix text, and which feature folder (if any) it relates to —
infer from the wording or git-blame the line if needed.

If the project has no `## Common Gotchas` section, stop and tell me —
nothing to clean up.

## Step 2 — Reclassify (proposal, then wait for approval)

For each entry, propose one of four destinations:

A. **Inline operational note in the runbook.** Keep the fact but move it
   to a parenthetical in the Notes column / bullet sub-note next to the
   port / env var / external service / command it affects. Use this for:
   port collisions, env vars that silently default, services that only
   accept HTTP, container restart-policy reminders — facts that an
   operator needs while running or deploying the system.

B. **Per-feature `bugfixes/<slug>.md` Detect/Avoid section.** Use this
   for entries that originated as bugfix learnings ("framework caches
   X — must invalidate after Y", "API returns 200 with an error body
   in the JSON"). If the entry already corresponds to an existing
   bugfix doc in `_LOUIE-output/implementations/<feature>/bugfixes/`,
   merge the wording into that doc's `## Detect / Avoid` section
   (create the section using `_LOUIE_/templates/bugfix-template.md` if
   it predates the new template). If no bugfix doc exists but the
   learning is feature-specific and worth preserving, create a new
   `_LOUIE-output/implementations/<feature>/bugfixes/<original-date>-<slug>.md`
   from the bugfix template, fill in what we can reconstruct, and add
   a row to `_LOUIE-output/bugfixes/overview.md`.

C. **Code-local `// WHY` comment.** Use this for entries that describe
   a code-shape pitfall a future editor needs to see while editing the
   affected file ("don't await this in a loop — the SDK serialises
   internally", "this field is intentionally not validated here, see
   ADR-007"). Locate the affected file(s) and add a one-line comment.
   If the entry is operational AND code-relevant, do both A and C.

D. **Delete.** Use this for entries that no longer apply (resolved
   bugs, retired dependencies, obsolete deploy patterns) OR that were
   never high-value to begin with ("I learned the form-resolver
   pattern", "remember to commit before pushing").

Output the proposal as a numbered table:

| # | Title | Destination | Target file/section | Rationale |
|---|-------|-------------|---------------------|-----------|

Wait for my approval before executing. I may overrule individual
destinations.

## Step 3 — Execute (after approval)

For each entry, apply the approved destination. Track exactly what
you wrote where:

- A entries: edit `runbook.md` in place. Note the Notes-column /
  bullet line you appended to.
- B entries: edit the bugfix doc (or create it). Make the new
  `## Detect / Avoid` section the canonical wording — terse, one
  short paragraph. If creating a new bugfix doc, add it to
  `bugfixes/overview.md`.
- C entries: add one short comment line next to the affected code.
  Do NOT change executable code.
- D entries: just delete from the runbook; nothing to add elsewhere.

After processing every entry, delete the entire `## Common Gotchas`
section header from `runbook.md`. The Debugging table stays — but if
it has more than 10 rows, propose which rows to prune (symptoms now
caught by tests/monitoring, or obsolete). Wait for approval on that
prune list before deleting rows.

Update `runbook.md`'s Maintainers section to match the current
template's wording (the rule about not deleting old gotchas is gone).

Bump the `Last Updated` line at the top of `runbook.md` to today.

## Step 4 — Verify and hand back

- Re-read the new `runbook.md` top to bottom; confirm no entries that
  are really implementation learnings remain in the operational
  sections.
- Run the project's typecheck / lint / tests; the changes should be
  docs + comments only, but verify nothing broke.
- Show me a summary table: total entries reclassified, breakdown by
  destination (A/B/C/D), final runbook line count before vs. after,
  count of bugfix docs touched/created, count of code-local comments
  added.
- Commit on `chore/runbook-drop-gotchas` with one focused commit per
  logical step (reclassify-to-A, reclassify-to-B, reclassify-to-C,
  delete-D-and-section, prune-debugging). Push and merge the branch.
```
