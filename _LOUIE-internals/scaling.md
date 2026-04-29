# Scaling the Artifact Layout

How LOUIE structures `_LOUIE-output/` so it stays usable beyond ~20 features and 100s of bug fixes. Read this before changing the on-disk shape of artifacts, the templates that produce them, or any command that reads/writes `_LOUIE-output/`.

## Why It Exists

The flat layout — every feature as `implementations/<feature>.md`, every requirements doc as `requirements/<feature>-requirements.md`, no first-class home for bug fixes — works fine up to ~20 features. Beyond that, three failure modes show up:

1. **`implementations/` becomes a wall of files.** No grouping, no co-location, file pickers and `ls` output stop being useful.
2. **`overview.md` becomes a brick.** It must list every feature with description and status. Past ~100 entries it's too long for an agent to load efficiently, violating the lazy-loading principle (`core.md`).
3. **Bug fixes have no first-class home.** They live in feature-doc `Change History` tails and runbook `Common Gotchas`. There's no central index, no way to ask "what did we fix this quarter?", no visibility into cross-cutting bug patterns.

The fix is structural: introduce a per-feature folder shape that scales linearly, give bug fixes a real home, and slim `overview.md` back to a pure index.

## The New Layout

**Universal — applies to every project regardless of size.** No threshold, no conditional switching. One mental model for new projects and large ones alike. The small-project overhead is one extra directory; the long-tail benefit is removing the "we'll restructure later" cliff.

```
_LOUIE-output/
├── architecture.md                       (top-level, unchanged)
├── tech-stack.md                         (top-level, unchanged)
├── runbook.md                            (top-level, unchanged)
├── implementations/
│   ├── overview.md                       (slim index — feature name, status, link)
│   ├── <feature>/
│   │   ├── feature.md                    (the implementation doc, was implementations/<feature>.md)
│   │   ├── requirements.md               (was requirements/<feature>-requirements.md)
│   │   ├── decisions.md                  (optional — ADRs scoped to this feature)
│   │   └── bugfixes/
│   │       ├── YYYY-MM-DD-<slug>.md      (one per fix; date-prefixed for chrono sort)
│   │       └── ...
│   └── <other-feature>/
│       └── ...
└── bugfixes/
    └── overview.md                       (cross-cutting bugfix index — links per-feature bugfixes plus standalone cross-cutting fixes)
```

Drops:

- Top-level `_LOUIE-output/requirements/` directory — moved into per-feature folders.

Adds:

- `_LOUIE-output/bugfixes/overview.md` — index for cross-feature search and any bugfix that touches multiple features.

## File and Naming Conventions

| Element | Choice | Rationale |
|---------|--------|-----------|
| Feature folder name | `<feature-slug>` (lowercase-kebab) | Matches existing slug convention from `core.md`. |
| Implementation doc | `feature.md` | Fixed name. `<slug>/<slug>.md` is redundant; `index.md` invites web-routing confusion. |
| Requirements doc | `requirements.md` | Inside the feature folder — true co-location. Drops the `<feature>-requirements.md` redundant prefix. |
| Decisions doc | `decisions.md` | Single file with stacked ADRs. Splits to `decisions/<date>-<slug>.md` if it ever grows past ~10 ADRs (per-feature ADR count is usually small). |
| Bug fix doc | `bugfixes/YYYY-MM-DD-<slug>.md` | Date-prefixed for chronological sort and to avoid name collisions when the same area is fixed twice. |
| Cross-cutting bug fix | `_LOUIE-output/bugfixes/YYYY-MM-DD-<slug>.md` (top-level) | Lives outside per-feature folders when the fix legitimately touches multiple features. The per-feature `bugfixes/overview.md` indexes link to it. |

Inside `implementations/overview.md`, the Document column links to `<feature>/feature.md`, not `<feature>.md`.

## Where Bug Fixes Live

Default: a bug fix is per-feature. Nina creates `implementations/<feature>/bugfixes/YYYY-MM-DD-<slug>.md` during `louie-bugfix`, with sections for symptoms, root cause, fix, and regression test reference.

Exceptions: a fix that legitimately touches multiple features lives at `_LOUIE-output/bugfixes/<date>-<slug>.md` (top-level). Each affected feature's `bugfixes/` folder gets a stub link pointing to the top-level doc rather than duplicating content.

`_LOUIE-output/bugfixes/overview.md` is the cross-cutting index — chronological list of every bug fix in the project, per-feature and top-level alike. This replaces the loose tracking that today lives in feature-doc `Change History` tails.

The runbook's `Common Gotchas` stays — it's the user-facing operational view ("when this breaks, here's what to check"), distinct from the bugfix log ("what we fixed and why").

## Migration Strategy

Existing LOUIE projects need to migrate from the flat layout. Migration is **one-way** — there's no design for reversing it.

### Trigger

Migration is offered by `louie-update-framework` when it detects the old layout. It can also be invoked directly via a new `louie-migrate` command for users who want to migrate without pulling a framework update.

### Old-layout detection

A project is on the old layout if **any** of these are true:

- Any `*.md` file directly in `_LOUIE-output/implementations/` other than `overview.md`
- The directory `_LOUIE-output/requirements/` exists and contains at least one file

### Algorithm

1. **Pre-flight checks:**
   - Verify the project is in a git repo and the working tree is clean. If not, abort with: "Commit or stash your changes first — migration restructures `_LOUIE-output/`."
   - Show the user the discovered features and the planned moves. Get explicit confirmation before any file is touched.

2. **Per-feature move:**
   For each `<feature>.md` directly in `implementations/` (excluding `overview.md`):
   - Create `implementations/<feature>/`.
   - Move `implementations/<feature>.md` → `implementations/<feature>/feature.md`.
   - If `requirements/<feature>-requirements.md` exists → move to `implementations/<feature>/requirements.md`.
   - Create empty `implementations/<feature>/bugfixes/` (with `.gitkeep`).

3. **Orphan requirements:**
   For any `requirements/<name>-requirements.md` with no matching implementation:
   - Ask the user whether to (a) create `implementations/<name>/requirements.md` (with no `feature.md` yet), (b) leave it in place, or (c) delete it.
   - Default suggestion is (a) — preserves the requirements doc and lets future work fill in `feature.md`.

4. **Cross-reference rewrite:**
   - Search and update path references inside `architecture.md`, `tech-stack.md`, `runbook.md`, `implementations/overview.md`, every newly-moved `feature.md` and `requirements.md`.
   - Patterns to rewrite:
     - `requirements/<x>-requirements.md` → `implementations/<x>/requirements.md`
     - `implementations/<x>.md` → `implementations/<x>/feature.md`
     - `_LOUIE-output/requirements/` → (no replacement; warn if found)

5. **Overview slim:**
   - Update `implementations/overview.md` to point Document-column links at the new paths.
   - Drop the verbose Description column if it's still being used as a long-form description rather than a one-liner — short descriptions are fine, but the per-feature `feature.md` is now the canonical home for detail. (Open question — see below.)

6. **Bug-fix index bootstrap:**
   - Create `_LOUIE-output/bugfixes/overview.md` from a new template (an empty cross-cutting index).
   - Optionally — and only on user request — scan existing feature-doc `Change History` sections for entries that read like bug fixes and offer to backfill them as `bugfixes/<date>-<slug>.md` files. Default off; this is a heuristic, not a clean migration.

7. **Cleanup:**
   - Delete the now-empty `_LOUIE-output/requirements/` directory.
   - Show the user the resulting tree and the modified files. Recommend committing the migration as a single commit with a clear message.

### Idempotence

- If a feature is already migrated (target `implementations/<feature>/feature.md` exists), skip it.
- If a feature has both old and new layouts present (e.g., a partial prior run), abort and ask the user to resolve manually — never silently merge.

### Reversibility

Migration does not provide a built-in revert. The pre-flight requirement that the working tree be clean ensures `git revert` of the migration commit is always available.

## Touch Points

A complete implementation has to update:

- **Templates:** `feature-template.md` stays largely the same but adds a "Bug Fixes" section pointing at `bugfixes/`. New templates: `bugfix-template.md` (already exists for the prompt; needs a doc version), `decisions-template.md` (lightweight ADR), `bugfixes-overview-template.md`.
- **Commands that write to `_LOUIE-output/`:** `louie-setup`, `louie-import`, `louie-feature`, `louie-extend`, `louie-update`, `louie-bugfix`, `louie-recipe`, `louie-doc`. Every path reference inside these files needs updating.
- **Agents:** `analyst.md` (Tom now writes `requirements.md` inside the feature folder), `architect.md` (Sophie reads from the new location), `coder.md` (Nina writes `bugfixes/<date>-<slug>.md` and updates the bugfix overview), `reviewer.md` (Max reads decisions doc), `tester.md` (Ava reads from the new location).
- **`louie-update-framework`:** Add the migration step.
- **New command:** `louie-migrate` for standalone migration.
- **Workflow doc:** `ai-workflow.md` directory tree at the bottom needs updating.
- **README and project-setup:** path references.
- **CLAUDE.md:** Key References section.
- **CHANGELOG:** entry under Unreleased.

This is the largest structural change since the framework was built. Worth a separate feature branch with thorough review before merging.

## Open Questions

- **`overview.md` description column.** Today it's a paragraph-ish description. With per-feature `feature.md` as the canonical home, should the overview keep a one-liner only, or drop descriptions entirely and rely on the link? Leaning one-liner for skimmability, but it's a judgement call.
- **Backfill of existing bug fixes from Change History.** Default off (heuristic, noisy). Worth offering as an opt-in step in `louie-migrate`?
- **`decisions.md` vs `decisions/` folder.** Single file is simpler; folder scales better past ~10 ADRs per feature. Single file with a documented split-when-needed rule seems right, but worth confirming.
- **Bugfix template ownership.** A new `_LOUIE_/templates/bugfix-template.md` is needed (the existing `bugfix-prompt-template.md` is for prompting, not for output). Naming: `bugfix-template.md` (parallel to feature-template) or `bugfix-output-template.md` (disambiguates from the prompt one)? Leaning the former and renaming the prompt one to `bugfix-prompt-template.md` is already its name — so `bugfix-template.md` is free.
- **Where does `louie-import` produce per-feature folders?** The new layout becomes the default for cold imports too. v1-docs imports should also produce the new layout, not preserve v1's flat shape.
- **Multi-repo / monorepo interaction.** The scaling layout doesn't address monorepo by itself. That remains a separate backlog item — but the per-feature folder model is at least friendly to it (each subproject can have its own `_LOUIE-output/`).
