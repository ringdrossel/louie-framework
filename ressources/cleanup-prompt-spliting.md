# LOUIE cleanup + segmentation prompt

Paste-ready prompt for triggering a per-capability re-split and a verbosity trim in any LOUIE-using project after the framework has been updated to the version that enforces these rules (Tom's Scope Split Gate + brevity directives).

## Usage

1. Open a Claude session inside the target project (the one whose `_LOUIE-output/` you want cleaned, not the framework repo).
2. Paste the prompt below verbatim.
3. Review the split proposal at Step 1 before approving — the agent's grouping may differ from how you'd cluster the capabilities.
4. The prompt does **not** open a PR or merge — review the branch diff first.

### Optional tightening

If you already know how you want the project split, append one line to short-circuit Step 1, e.g.:

> Use this split as the starting proposal: auth / data-core / list-ui / import / external-lookups / ai-features / admin-settings / pwa-offline.

### Optional loosening

If you want the agent to also clean up obvious dead code (not just comments), change Step 4's last line from `Do NOT change executable code in this pass. Comment-only edits.` to `Comment edits plus obvious dead-code removal allowed; nothing that changes runtime behaviour.`

---

## The prompt

```
Please audit this project's LOUIE setup and fix two specific anti-patterns.
Work on a new branch named `chore/louie-cleanup` so nothing lands on main
directly. Do NOT modify application source code in this pass — only the
LOUIE artifacts under `_LOUIE-output/` and over-long comments in source.

## Step 0 — Sync the framework

If this project vendors `_LOUIE_/` (the framework dir), update it to the
latest version on the framework repo's `main`. If unsure, ask me before
overwriting. If `_LOUIE_/` is missing or symlinked to a shared install,
skip this step.

## Step 1 — Diagnose segmentation

Look at `_LOUIE-output/implementations/`. List every feature folder and
its `requirements.md` + `feature.md` line counts. Flag any folder where:

- `feature.md` > 500 lines, OR
- `requirements.md` > 250 lines, OR
- the folder name is generic ("mvp", "v1", "core", "main", "library-mvp",
  "app", etc.) rather than naming one capability, OR
- the user-story list spans more than ~8 stories or visibly mixes
  capabilities (auth + UI + persistence + integrations + AI + admin + PWA
  in one doc is the smell).

For each flagged folder, propose a split into per-capability folders.
Typical split shapes for a web app are auth / data-core / list-or-shelf-UI
/ import / external-lookups / ai-features / admin-settings / pwa-offline,
but derive yours from the actual stories, not from this list. Present the
proposed split to me as a numbered list with the stories assigned to each
new folder. Wait for my approval before moving anything.

Design-refresh "extensions" or follow-up scope tweaks attached to an
existing feature (e.g. visual redesign of an already-shipped shelf) do
NOT become new feature folders — they become an ADR in the existing
folder's `decisions.md`. Call those out separately.

## Step 2 — Execute the split (after approval)

For each new feature folder:

1. Create `_LOUIE-output/implementations/<new-feature>/` with its own
   `requirements.md` containing only the stories that belong to this
   capability. Use `_LOUIE_/templates/requirements-template.md` and the
   length budget in its header (~150 lines target, ~250 hard cap).
2. Carve out the matching slice of the old `feature.md` into the new
   folder's `feature.md`. Keep only the implementation plan + code
   structure relevant to this capability. Use the feature template's
   length budget (~250 lines target, ~500 hard cap).
3. If implementation has already happened, set the Status checkboxes
   honestly based on what's in the codebase.
4. Move existing ADRs from the old `decisions.md` into whichever new
   folder they belong to.
5. Move bugfix docs from `bugfixes/` into the new owning feature's
   `bugfixes/` subfolder where they apply.

After the split, update `_LOUIE-output/implementations/overview.md`:
every new feature listed in implementation order, old umbrella folder
removed.

Delete the old umbrella folder once everything's been migrated. Do not
leave a redirect stub.

## Step 3 — Trim verbose docs

Re-read each `requirements.md` and `feature.md` against the brevity
rules in `_LOUIE_/templates/*-template.md`:

- Bullets > paragraphs.
- No rationale prose — push that to `decisions.md` as ADRs.
- No "design discussion" sections.
- Change History: one line per entry, ≤120 chars, no narrative.

Trim aggressively. Treat any sentence that doesn't change downstream
behaviour as deletable.

## Step 4 — Trim verbose code comments

Scan source files for the patterns the new
`_LOUIE_/guidelines/coding-guidelines.md` § Comments forbids:

- Multi-line comment blocks / paragraph-long docstrings.
- ASCII-art section headers ("// === SECTION ===").
- Comments restating WHAT the code does ("// loops over users").
- Comments referencing tickets / phases / past callers ("// added in
  Phase 4 for the shelf").
- Commented-out code.

For each match, either delete the comment (default) or collapse it to
one short line if it captures a genuinely non-obvious WHY (hidden
constraint, workaround for a specific bug, subtle invariant).

Do NOT change executable code in this pass. Comment-only edits.

## Step 5 — Verify and hand back

- Run the project's typecheck / lint / tests to confirm nothing broke.
- Show me a summary: feature folders before vs. after, line-count
  delta on docs, number of comments removed/trimmed.
- Commit on `chore/louie-cleanup` with one focused commit per logical
  step (split, trim docs, trim comments). Push the branch. Do NOT
  open a PR or merge — I'll review the diff first.
```
