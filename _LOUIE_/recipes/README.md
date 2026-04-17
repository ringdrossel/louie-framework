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

## How Recipes Interact With the Agent Chain

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
- [ ] Requirements Seed is stack-agnostic or clearly notes its assumptions.
- [ ] Architecture Notes flag anything Sophie must validate.
- [ ] Implementation Guidance avoids hardcoding a specific framework unless the recipe is framework-specific by design.
- [ ] No references to `_LOUIE-internals/` (it's not distributed).
- [ ] `_LOUIE-internals/CHANGELOG.md` has an entry for the new recipe.
