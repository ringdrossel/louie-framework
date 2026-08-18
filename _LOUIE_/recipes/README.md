# LOUIE Recipes

Reusable, pre-baked specs for recurring application concerns. A recipe seeds the standard agent chain with an adapted requirements draft, architecture notes, and implementation guidance — saving you from reinventing settings, auth, Docker wiring, logging, etc. on every project.

Recipes are loaded via the `louie-recipe` command. See `_LOUIE_/commands/louie-recipe.md` for the dispatcher and `louie-recipe`'s user surface.

## Folder Layout

```
_LOUIE_/recipes/
  README.md              ← this file (authoring guide)
  <section>/
    README.md            ← section description — first line is a one-liner
    <recipe-name>.md     ← recipe — first line is a one-liner
```

Sections are categories (`admin/`, `docker/`, `tools/`, ...). Pick a section per recipe based on the concern it addresses, not the tech it uses.

## Recipe Types

| Type | What it produces | How it runs |
|------|------------------|-------------|
| **feature** (default) | Working code | Seeds the standard agent chain: Tom → Sophie → feature doc → Leo/Nina/Max/Ava. Both confirmation gates fire. |
| **audit** | Findings + tracked follow-up work | Scans the codebase against one standard, reports, and files entries (usually to `_LOUIE-output/roadmap.md`). Writes no application code, runs no agents. |

A recipe declares a non-default type on a line near the top, right under the one-line description:

```markdown
**Recipe type:** audit
```

**No type line means `feature`.** Existing recipes are unaffected.

An audit recipe does **not** require a confirmed architecture — Critical Rule 2 gates feature work, and an audit builds nothing. It also never fixes what it finds: fixing goes through `louie-roadmap promote` → `louie-feature`, or `louie-update` for small changes. Keep each audit recipe to **one** standard; broad multi-category assessment is `louie-evaluate`'s job.

## Naming Rules

- **Filenames: lowercase-kebab-case.** Examples: `build-push.md`, `typed-settings.md`, `audit-log.md`.
- **Section folders: lowercase-kebab-case.** Examples: `admin/`, `docker/`, `tools/`.
- **No spaces, no underscores, no camelCase.** Linux is case-sensitive; the convention prevents cross-platform breakage.

## Creating a New Section

1. Create the folder: `_LOUIE_/recipes/<section>/`
2. Add `_LOUIE_/recipes/<section>/README.md` whose **first line** is a short description:
   ```
   Docker build, push, and compose recipes for local dev and CI.

   (Optional longer description below.)
   ```
3. Start adding recipes.

The dispatcher auto-discovers sections — no registration, no central index.

## Recipe File Shape

Every recipe is a self-contained spec. The **first line** is the one-line description used by `louie-recipe list <section>`. Everything below is read when the recipe is loaded.

### Feature recipes

Recommended structure:

```markdown
<One-line description — used by `louie-recipe list` output.>

# <Recipe Name>

## Overview

What this recipe builds. When to use it. When *not* to use it. Prerequisites.

## Requirements Seed

A pre-drafted requirements block Tom will adapt to the current project. Include:
- Functional requirements (what it does)
- Non-functional requirements (performance, security, compatibility)
- Out-of-scope items (to prevent scope creep)

## Architecture Notes

Tech-stack assumptions, integration points, data model sketches. Things Sophie
should validate against `_LOUIE-output/architecture.md` / `tech-stack.md`. Call
out anything that might conflict with common stacks.

## Implementation Guidance

Key files, patterns, and pitfalls for Nina. Concrete enough to shortcut
implementation; abstract enough not to hardcode a stack.

## Test Guidance

What Ava should cover: happy path, edge cases, known pitfalls, regression
risks.

## Variations

Optional toggles or common variants (e.g. "with OAuth", "serverless-friendly",
"SQLite vs Postgres").
```

### Audit recipes

Different shape — there is no requirements seed and no chain to hand off to:

```markdown
<One-line description — used by `louie-recipe list` output.>

# <Recipe Name>

**Recipe type:** audit

## Overview

What this audit measures. When to run it. When not to (and which command
covers that case instead). What it explicitly does not do.

## Threshold / Standard

The rule being checked and where it is sourced from — a guideline file, not a
number invented here. State whether the user may override it for a run, and
make clear that an override never edits the source of truth.

## Audit Procedure

Numbered, mechanical: resolve scope → enumerate candidates → filter →
exclude (with reasons) → measure → compare. Concrete enough that two runs on
an unchanged repo produce the same result.

## Findings Report

The exact shape of the report, including counts for scanned / excluded /
violating. Say what a clean result looks like — and that a clean result
writes nothing.

## Outcome

Where findings land (roadmap entry shape, or another artifact), at what
granularity, and — required — how a **re-run** avoids duplicating what a
previous run already filed.

## Follow-Up

Which command turns a finding into actual work. The audit never does it.

## Variations

Threshold changes, warn bands, scoped runs, CI mode.
```

The **re-run** section is not optional. An audit that files a fresh duplicate every time it runs makes the roadmap unusable within three runs.

## How Recipes Interact With the Agent Chain

This section covers **feature** recipes. Audit recipes don't touch the chain at all — see § Recipe Types.

Recipes **seed**, they don't **bypass**. When a recipe is loaded:

1. Tom adapts the Requirements Seed to the current project — still interactive, still asks questions where gaps exist.
2. Sophie validates the recipe's Architecture Notes against the project's architecture/tech-stack. If they don't fit, Sophie reconciles — which may fire the architecture confirmation gate.
3. The feature doc is drafted using the recipe's Implementation Guidance, then shown to the user for approval (feature-doc confirmation gate).
4. Leo (if UI) → Nina → Max → Ava proceed normally.

Both confirmation gates stay in effect. A recipe is an accelerator, not an override.

## Authoring Checklist

Before committing a new recipe:

- [ ] First line is a one-line description (readable as a list entry).
- [ ] Filename is lowercase-kebab-case and matches the recipe's intent.
- [ ] Section README exists and has a first-line description.
- [ ] Type is correct: a `**Recipe type:** audit` line for audits, no type line for feature recipes.

Feature recipes:

- [ ] Requirements Seed is stack-agnostic or clearly notes its assumptions.
- [ ] Architecture Notes flag anything Sophie must validate.
- [ ] Implementation Guidance avoids hardcoding a specific framework unless the recipe is framework-specific by design.

Audit recipes:

- [ ] Checks exactly one standard, sourced from a guideline file rather than a number invented in the recipe.
- [ ] Exclusions are reported with reasons, never silent.
- [ ] A clean result writes nothing.
- [ ] Re-run behavior is specified: no duplicate entries, and resolved findings are offered for closing rather than closed automatically.
- [ ] The recipe never edits application code; Follow-Up names the command that does.

All recipes:
- [ ] No references to `_LOUIE-internals/` (it's not distributed).
- [ ] `_LOUIE-internals/CHANGELOG.md` has an entry for the new recipe.
