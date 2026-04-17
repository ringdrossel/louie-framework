# Recipe System

Design doc for the LOUIE recipe system. Read this before touching `_LOUIE_/recipes/` or `_LOUIE_/commands/louie-recipe.md`.

## Status

**Designed, not yet implemented.** This document captures the locked-in design so implementation can happen without re-deriving decisions. See `CHANGELOG.md` for implementation status.

## Motivation

Recurring application concerns (settings management, auth scaffolding, Docker build-and-push, logging setup, etc.) get reinvented on every project. A recipe is a reusable, pre-baked spec that seeds the standard agent chain — Tom still adapts it to the project, Sophie still validates architectural fit, Nina still implements against *this* codebase. Recipes accelerate; they don't bypass the gates.

## Location

```
_LOUIE_/
  commands/
    louie-recipe.md          ← dispatcher (single command)
  recipes/
    README.md                 ← authoring guide for recipe authors
    <section>/
      README.md               ← section description (first line = one-liner)
      <recipe-name>.md        ← individual recipe (first line = one-liner)
```

Recipes live **inside** `_LOUIE_/recipes/` so they ship with the framework. Downstream projects get them on install.

## Dispatcher: `louie-recipe`

One command — `louie-recipe` — handles all recipe interactions. The dispatcher file is `_LOUIE_/commands/louie-recipe.md`, lazy-loaded like every other command.

### User Surface

| Input | Behavior |
|-------|----------|
| `louie-recipe` (no arg) | Show section tree: list each subfolder of `recipes/` with its one-line description |
| `louie-recipe list` | Same as above (alias) |
| `louie-recipe list <section>` | List recipes in that section with one-line descriptions |
| `louie-recipe <name>` | Glob `recipes/**/<name>.md`; load on 1 match, disambiguate on >1, suggest on 0 |
| `louie-recipe <section>:<name>` | Explicit: read `recipes/<section>/<name>.md` directly |
| `louie-recipe <section>/<name>` | Accepted silently (path form); same behavior as `:` |
| `louie-recipe <prefix>` | Prefix match: glob `recipes/**/<prefix>*.md`; same 1/>1/0 resolution |

### Name Resolution Algorithm

The dispatcher instructions tell the AI to:

1. If arg is empty or `list` → list top-level sections from `recipes/*/README.md`, using first line of each README as the description. Include sections without README.md (just no description).
2. If arg starts with `list ` → treat remainder as `<section>`, glob `recipes/<section>/*.md` (exclude `README.md`), list each with first line as description.
3. If arg contains `:` or `/` → split into `<section>` and `<name>`, read `recipes/<section>/<name>.md` directly. Error if file missing.
4. Otherwise (bare name or prefix):
   - Exact match: glob `recipes/**/<name>.md` (case-insensitive fallback).
   - If exactly 1 match → confirm with user (`Loading <section>:<name> — ok?`) then load.
   - If >1 match → list matches as `<section>:<name>` pairs, ask user which to load.
   - If 0 exact matches → try prefix glob `recipes/**/<arg>*.md`.
     - If exactly 1 prefix match → confirm-and-load.
     - If >1 → list.
     - If 0 → suggest closest names (Levenshtein or substring) and stop.

### Case Handling

- Recipe filenames **must** be lowercase-kebab-case (`build-push.md`, never `BuildPush.md`). Enforced by convention, documented in `_LOUIE_/recipes/README.md`.
- Dispatcher does a case-insensitive match as a fallback so users don't hit Linux-only failures. See `core.md` → Cross-Platform Constraints.

## Section Structure

Each section is a subfolder of `_LOUIE_/recipes/` (e.g. `admin/`, `docker/`, `tools/`).

- Section folder must contain a `README.md` whose **first line** is a short description of the section. The dispatcher uses that first line in `louie-recipe list` output.
- Recipes in the section are peer `.md` files. Each recipe's **first line** is its own one-line description, used by `louie-recipe list <section>`.

Example:

```
recipes/
  docker/
    README.md              ← first line: "Docker build, push, and compose recipes"
    build-push.md          ← first line: "Build a multi-arch image and push to a registry"
    compose-dev.md         ← first line: "Local dev environment with hot reload"
  admin/
    README.md              ← first line: "Admin-facing features: settings, users, audit"
    settings.md            ← first line: "Project settings store with typed keys and UI"
```

No central registry. The filesystem *is* the registry.

## Recipe File Shape

A recipe file is a self-contained spec. It should contain:

1. **First line** — one-line description (used by `louie-recipe list`).
2. **Overview** — what this recipe builds, when to use it, when not to use it.
3. **Requirements seed** — a pre-drafted requirements block that Tom adapts to the current project.
4. **Architecture notes** — tech-stack assumptions, integration points, things Sophie should validate.
5. **Implementation guidance** — key files, patterns, pitfalls for Nina.
6. **Test guidance** — what Ava should cover.
7. **Variations** — optional toggles or common variants.

A template for recipe authors lives at `_LOUIE_/recipes/README.md` (the recipe-authoring guide, distinct from per-section READMEs).

## Integration with the Agent Chain

Recipes are **inputs**, not bypasses. Loading a recipe via `louie-recipe <name>` seeds Tom with a pre-drafted requirements block instead of starting from scratch. From there, the standard flow applies:

- Tom adapts requirements to the current project (still interactive, still interviews where gaps exist).
- Sophie validates fit against `_LOUIE-output/architecture.md` / `tech-stack.md` — may reject or adapt the recipe's architectural assumptions.
- **Both confirmation gates still fire.** Architecture gate if Sophie needs to amend architecture; feature-doc gate before implementation.
- Leo/Nina/Max/Ava run normally.

A recipe never short-circuits a gate. If a recipe's assumptions conflict with the project's tech stack, Sophie reconciles and the user approves the reconciled feature doc.

## Why Not a Separate Command Per Recipe

Early alternative considered: `louie-settings`, `louie-auth`, `louie-logging` each as a separate `louie-*` command.

Rejected because:
- Command table in `CLAUDE.md` would grow linearly with every recipe.
- Mixes workflow commands (`louie-feature`, `louie-review`) with library recipes in the same namespace.
- Adding a recipe would require editing distributed files (`CLAUDE.md` template, `README.md`).

A single `louie-recipe` dispatcher + filesystem-as-registry keeps the command surface stable while the recipe library grows freely.

## Why `:` Over `/` As The Documented Form

- `:` reads as a namespace (compare `npm` scopes, `k8s` resource kinds), not a filesystem path.
- Keeps section folders as an implementation detail — users think "docker recipes" not "docker folder."
- Avoids confusion when a recipe is mentioned in prose alongside real file paths.

Both `:` and `/` are accepted by the dispatcher at zero cost. Docs and examples use `:`.

## Open Questions

None currently blocking implementation. Future considerations:

- **Recipe versioning** — once recipes get deployed into multiple projects, a recipe update might conflict with downstream customizations. Not urgent; defer until a real conflict appears.
- **Recipe composition** — a recipe that pulls in another recipe (e.g. `admin:settings` uses `core:typed-config`). Defer until needed.
- **Recipe parameters** — some recipes naturally take inputs (e.g. `docker:build-push` wants a registry URL). For now, recipes ask via Tom's interview. A parametrized form can come later if pain justifies it.
