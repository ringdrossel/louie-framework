# Framework Changelog

Internal version log for the LOUIE framework. Tracks meaningful changes to the framework itself — not user project artifacts. Entries here inform what `louie-update-framework` users see when they pull a new version.

Format: reverse chronological, date + short description + affected areas.

## Unreleased

- **Internals docs scaffolding** — added `_LOUIE-internals/` with `README.md`, `core.md`, `recipes.md`, `CHANGELOG.md`. Not distributed. Added pointer from this repo's `CLAUDE.md`.
- **Recipe system designed** — design locked in `recipes.md`. See that file for dispatcher rules, folder layout, and name-resolution algorithm.
- **Recipe system implemented** — added `_LOUIE_/commands/louie-recipe.md` (dispatcher) and `_LOUIE_/recipes/README.md` (authoring guide). Registered `louie-recipe` in this repo's `CLAUDE.md`, `README.md`, `_LOUIE_/workflow/ai-workflow.md`, and all six init scripts (claude/cursor/codex × sh/bat). Recipe sections are not yet populated — first recipe pending user input.
