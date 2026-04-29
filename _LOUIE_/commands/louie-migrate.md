# louie-migrate

When the user says **`louie-migrate`**, follow this procedure to migrate an existing LOUIE project from the **old flat layout** (`implementations/<feature>.md` + `requirements/<feature>-requirements.md`) to the **new per-feature folder layout** (`implementations/<feature>/feature.md` + `requirements.md` + `decisions.md` + `bugfixes/`).

The migration is **one-way**. There is no built-in revert — rely on git to back out if needed.

Design background: `_LOUIE-internals/scaling.md`.

## When to Use

Run `louie-migrate` when:

- An existing LOUIE project is on the old flat layout.
- The user pulled a framework update that introduced the new layout.
- `louie-update-framework` detected the old layout and recommended migration.

`louie-migrate` is a no-op for already-migrated projects (it detects the new layout and exits cleanly).

## Procedure

### 1. Read framework context

- Read `_LOUIE-internals/scaling.md` is **not** distributed — do not require it. Read the design rationale only if available.
- Read `_LOUIE_/templates/bugfixes-overview-template.md` — the bugfix index will be bootstrapped from this.
- Read `_LOUIE_/templates/feature-template.md` — for cross-reference rewrite patterns.

### 2. Detect the layout

Inspect `_LOUIE-output/`:

- **Old layout** if any of these are true:
  - At least one `*.md` file directly in `_LOUIE-output/implementations/` other than `overview.md`
  - The directory `_LOUIE-output/requirements/` exists (regardless of whether it has files)
- **New layout** if `_LOUIE-output/implementations/` contains only `overview.md` and subdirectories (per-feature folders).
- **Mixed** if both signals are present (e.g., a previous partial migration). Abort with a clear message asking the user to resolve manually — do not silently merge.

If new-layout detection succeeds, tell the user "Project is already on the new layout — nothing to migrate." and stop.

### 3. Pre-flight checks

Migration restructures `_LOUIE-output/`. Before touching anything:

- Verify the project is in a git repository. If not, abort with: "louie-migrate requires a git repo so the user can revert if needed. Initialize git or run from a versioned project."
- Verify the working tree is clean (`git status` shows no uncommitted changes in `_LOUIE-output/`). If not, abort with: "Commit or stash your changes in `_LOUIE-output/` first. Migration restructures this directory and you'll want a clean baseline to revert to."
- List every feature found at the top level of `implementations/` and every `requirements/` file.
- Pair each implementation file with its matching `requirements/<name>-requirements.md` if present. Flag any orphans.
- Print the planned moves to the user as a tree diff (before → after).
- Wait for explicit confirmation before any file is moved.

### 4. Per-feature move

For each `<feature>.md` directly in `_LOUIE-output/implementations/` (excluding `overview.md`):

1. Create `_LOUIE-output/implementations/<feature>/`.
2. `git mv _LOUIE-output/implementations/<feature>.md _LOUIE-output/implementations/<feature>/feature.md`
3. If `_LOUIE-output/requirements/<feature>-requirements.md` exists:
   `git mv _LOUIE-output/requirements/<feature>-requirements.md _LOUIE-output/implementations/<feature>/requirements.md`
4. Create the empty bugfixes folder: `_LOUIE-output/implementations/<feature>/bugfixes/.gitkeep`.
5. Do **not** create `decisions.md` — leave it absent until a real ADR is added later.

Use `git mv` (not plain `mv`) so history is preserved.

### 5. Orphan requirements

For any `_LOUIE-output/requirements/<name>-requirements.md` with no matching implementation file:

- Ask the user per orphan: "Found orphan `requirements/<name>-requirements.md` with no matching implementation. Options: (a) create `implementations/<name>/requirements.md` with no `feature.md` (preserves the requirements for future work), (b) leave it in place (will block migration completion), (c) delete it. Which?"
- Default suggestion is (a). Apply the chosen option per orphan.

### 6. Cross-reference rewrite

Many docs reference the old paths. After moves complete, rewrite path references inside these files:

- `_LOUIE-output/architecture.md`
- `_LOUIE-output/tech-stack.md`
- `_LOUIE-output/runbook.md`
- `_LOUIE-output/implementations/overview.md`
- Every newly-moved `feature.md` and `requirements.md`

Patterns to rewrite (apply in order):

| Old | New |
|-----|-----|
| `_LOUIE-output/requirements/<x>-requirements.md` | `_LOUIE-output/implementations/<x>/requirements.md` |
| `_LOUIE-output/implementations/<x>.md` | `_LOUIE-output/implementations/<x>/feature.md` |
| `requirements/<x>-requirements.md` | `implementations/<x>/requirements.md` |
| `implementations/<x>.md` | `implementations/<x>/feature.md` |
| `_LOUIE-output/requirements/` (bare directory references) | (warn — likely intentional; flag for manual review rather than auto-replace) |

Only rewrite inside `_LOUIE-output/`. Do not modify anything under `_LOUIE_/` or any source code — those reference paths intentionally and the framework files are managed by `louie-update-framework`.

### 7. Slim the overview

Update `_LOUIE-output/implementations/overview.md`:

- Update every Document column link to point at `implementations/<feature>/feature.md` (handled by the cross-reference rewrite above, but verify).
- If the Description column contains paragraph-length descriptions, rewrite them to one-line summaries — the per-feature `feature.md` is now the canonical home for detail. Ask the user before condensing if descriptions look intentional.

### 8. Bootstrap the bugfix index

If `_LOUIE-output/bugfixes/overview.md` doesn't exist:

- Create `_LOUIE-output/bugfixes/` (with `.gitkeep`).
- Copy `_LOUIE_/templates/bugfixes-overview-template.md` to `_LOUIE-output/bugfixes/overview.md`. Leave the tables empty — we do **not** backfill from feature-doc Change History (heuristic, noisy).
- Tell the user: "I created an empty bugfix index. Past bugs remain readable in each feature's Change History. Going forward, `louie-bugfix` will create per-fix docs that land in this index."

### 9. Cleanup

- Delete the now-empty `_LOUIE-output/requirements/` directory: `git rm -r _LOUIE-output/requirements/`. Only do this if it's actually empty after the orphan step.

### 10. Show the result and recommend a commit

- Display the resulting tree under `_LOUIE-output/`.
- Show the user the list of files modified by cross-reference rewrites (so they can spot-check).
- Recommend committing the migration as a single commit:
  ```
  refactor(louie): migrate to per-feature folder layout
  ```
- Do **not** auto-commit. The user owns the commit.

## Idempotence

- Already-migrated features are skipped (target `<feature>/feature.md` exists).
- A mixed-state project (some features migrated, some not) requires manual resolution — `louie-migrate` aborts to avoid silently merging.
- Running `louie-migrate` on a fully-migrated project prints "Already migrated" and exits.

## Constraints

- **Never modify source code.** Migration is documentation-only.
- **Never auto-commit.** The user must review and commit themselves.
- **Use `git mv`** for moves so file history follows the rename.
- **Never overwrite without confirmation.** If a target file already exists (e.g., a partial prior migration left a `<feature>/feature.md` behind), abort and ask.

## Usage

```
louie-migrate
```

There are no arguments. The command auto-detects state and migrates if applicable.
