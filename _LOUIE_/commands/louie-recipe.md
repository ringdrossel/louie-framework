# louie-recipe

When the user says **`louie-recipe`**, follow this procedure to browse or load a LOUIE recipe — a reusable, pre-baked spec for a recurring app concern (settings, auth, Docker build/push, logging, etc.).

## Recipes Location

Recipes live in `_LOUIE_/recipes/`, organized by section:

```
_LOUIE_/recipes/
  README.md                   ← authoring guide (skip when resolving)
  <section>/
    README.md                 ← section description (first line = one-liner)
    <recipe-name>.md          ← recipe (first line = one-liner)
```

If `_LOUIE_/recipes/` does not exist or contains no sections, tell the user no recipes are installed and stop.

## Argument Parsing

The user's argument — everything after `louie-recipe` — determines the mode.

| Argument | Mode |
|----------|------|
| *(empty)* or `list` | **Browse mode** — list sections |
| `list <section>` | **Browse mode** — list recipes in a section |
| Contains `:` or `/` (e.g. `docker:build-push`, `docker/build-push`) | **Explicit load** |
| Bare name (e.g. `build-push`) | **Lookup mode** — search across sections |

Lowercase the argument before matching. Filenames are lowercase-kebab-case; be forgiving about user casing.

## Procedure

### Mode 1: Browse sections (`louie-recipe` or `louie-recipe list`)

1. Glob `_LOUIE_/recipes/*/` (immediate subdirectories only — skip the top-level `README.md`).
2. For each section folder, read the first line of its `README.md` (if present) as the description. Strip a leading `#` and any heading markers.
3. Print a list:
   ```
   Available recipe sections:
     <section-a>  — <first line of recipes/<section-a>/README.md>
     <section-b>  — <first line of recipes/<section-b>/README.md>
     ...
   
   Use `louie-recipe list <section>` to see recipes, or `louie-recipe <name>` to load one.
   ```
4. Include sections without a `README.md` — just omit the description.
5. Stop.

### Mode 2: Browse recipes in a section (`louie-recipe list <section>`)

1. Validate `_LOUIE_/recipes/<section>/` exists. If not, list available sections and suggest the closest name.
2. Glob `_LOUIE_/recipes/<section>/*.md` and exclude `README.md`.
3. For each recipe file, read the first line as its description.
4. Print a list:
   ```
   Recipes in <section>:
     <section>:<recipe-a>  — <first line of recipe-a.md>
     <section>:<recipe-b>  — <first line of recipe-b.md>
     ...
   
   Load one with `louie-recipe <name>` or `louie-recipe <section>:<name>`.
   ```
5. Stop.

### Mode 3: Explicit load (`louie-recipe <section>:<name>` or `louie-recipe <section>/<name>`)

1. Split the argument on `:` or `/` into `<section>` and `<name>`.
2. Build the path `_LOUIE_/recipes/<section>/<name>.md`.
3. If the file does not exist, do a case-insensitive retry by globbing `_LOUIE_/recipes/<section>/*.md` and matching on lowercased stem. If still nothing, tell the user the recipe wasn't found and suggest the closest name from that section.
4. Read the file and proceed to **Execution** below.

### Mode 4: Lookup by bare name (`louie-recipe <name>`)

1. Glob `_LOUIE_/recipes/**/<name>.md` (case-insensitive). Exclude any `README.md` matches.
2. Resolve:
   - **1 match** → confirm with the user: `Loading <section>:<name> — ok?` If yes, read the file and proceed to Execution. If no, stop.
   - **>1 match** → list matches as `<section>:<name>` pairs and ask which to load.
   - **0 matches** → fall through to prefix search.
3. **Prefix search** (only if zero exact matches): glob `_LOUIE_/recipes/**/<name>*.md`.
   - **1 match** → confirm-and-load as above.
   - **>1 matches** → list candidates.
   - **0 matches** → tell the user no recipe matched and suggest running `louie-recipe list` to browse. Stop.

## Execution — After a Recipe Is Loaded

A recipe is a **seed for the standard agent chain**, not a bypass. After reading the recipe file:

1. **Read project context first:**
   - `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md` (if they exist)
   - `_LOUIE-output/implementations/overview.md` (if it exists)
   - `_LOUIE_/guidelines/coding-guidelines.md`

2. **If no architecture exists yet:** stop and tell the user. Recipes require a confirmed architecture (Critical Rule 2). Suggest running `louie-setup` (new project), `louie-import` (existing project), or `louie-feature` first — all of those establish architecture before touching code.

3. **Summarize the recipe to the user** in 3–5 lines: what it builds, key assumptions, and how it will adapt to their project.

4. **Invoke Tom (Analyst)** per `_LOUIE_/agents/analyst.md`, seeded with the recipe's Requirements Seed block. Tom adapts the seeded requirements to the current project — filling gaps via interview, resolving conflicts with existing features, and producing `_LOUIE-output/implementations/<feature>/requirements.md` (creating the feature folder).

5. **Invoke Sophie (Architect)** per `_LOUIE_/agents/architect.md` to validate the recipe's architectural assumptions against the project's tech stack. If Sophie needs to amend architecture, the architecture confirmation gate fires.

6. **Create the feature document** at `_LOUIE-output/implementations/<feature>/feature.md` using `_LOUIE_/templates/feature-template.md`, seeded with the recipe's Implementation Guidance.

7. **Feature doc gate:** show the feature doc to the user and wait for confirmation before coding.

8. **Standard chain:** Leo (if UI) → Nina → Max → Ava.

**Gates are load-bearing.** A recipe never skips the architecture gate or the feature-doc gate. If the recipe's assumptions conflict with the project's tech stack, Sophie reconciles and the user approves the reconciled feature doc.

## Usage

Browse:
```
louie-recipe
louie-recipe list
louie-recipe list docker
```

Load:
```
louie-recipe build-push
louie-recipe docker:build-push
louie-recipe docker/build-push
```

## Notes for the Dispatcher

- The user may call this command many times in one session. Do not re-read static framework files (guidelines, architecture) if you already have them in context — just re-check that the recipe file itself is current.
- If the user types `louie-recipe` with no argument, always show the section list. Don't assume intent.
- Case-insensitive matching is a fallback, not the default — prefer exact lowercase matches, retry insensitively only if the exact match fails.
