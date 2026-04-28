# Framework Changelog

Internal version log for the LOUIE framework. Tracks meaningful changes to the framework itself — not user project artifacts. Entries here inform what `louie-update-framework` users see when they pull a new version.

Format: reverse chronological, date + short description + affected areas.

## Unreleased

- **Internals docs scaffolding** — added `_LOUIE-internals/` with `README.md`, `core.md`, `recipes.md`, `CHANGELOG.md`. Not distributed. Added pointer from this repo's `CLAUDE.md`.
- **Recipe system designed** — design locked in `recipes.md`. See that file for dispatcher rules, folder layout, and name-resolution algorithm.
- **Recipe system implemented** — added `_LOUIE_/commands/louie-recipe.md` (dispatcher) and `_LOUIE_/recipes/README.md` (authoring guide). Registered `louie-recipe` in this repo's `CLAUDE.md`, `README.md`, `_LOUIE_/workflow/ai-workflow.md`, and all six init scripts (claude/cursor/codex × sh/bat).
- **First recipe: `admin:settings`** — DB-backed settings store with section+key composite, typed values (string/number/boolean/json), full admin UI (table, section filter, type-ahead search, edit dialog, delete confirm). Stack-agnostic — server-side search required when an API exists. Added `_LOUIE_/recipes/admin/README.md` + `_LOUIE_/recipes/admin/settings.md`.
- **Runbook system added** — new canonical output `_LOUIE-output/runbook.md` for runtime/operational content (deployment model, ports, commands, env vars, gotchas, debugging). Distinct from architecture (design-time) and tech-stack (build-time). Filled a category-wide gap in AI dev frameworks (verified vs. SpecKit and BMAD V4/V6). Six-section template at `_LOUIE_/templates/runbook-template.md`. Lifecycle: Sophie creates at setup, Nina appends during feature work and bugfixes (mandatory for bugfixes — they're the highest-value entries), Max verifies during review. No new agent. Updated `architect.md`, `coder.md`, `reviewer.md`, all relevant commands (`louie-setup`, `louie-feature`, `louie-extend`, `louie-bugfix`, `louie-review`, `louie-review-doc`), workflow doc, all six init scripts, README, project-setup, this repo's CLAUDE.md. Design rationale + comparison to BMAD/SpecKit in `_LOUIE-internals/runbook.md`.
- **`louie-update-framework` gaps closed** — added `_LOUIE_/recipes/` to the update list (was missing — recipes were added after this command was written). Added a new step that checks for newly-required `_LOUIE-output/` artifacts (e.g. `runbook.md`) and offers to bootstrap them rather than silently creating files.
