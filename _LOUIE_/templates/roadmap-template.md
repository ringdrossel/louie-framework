# Project Roadmap

Last Updated: YYYY-MM-DD

> **What this is:** a triage list of the project's **bigger changes / epics**, pre-feature-folder. **Not a per-feature tracker** — every-feature status lives in `_LOUIE-output/implementations/overview.md`. Think epics: larger pieces of work you want to remember and shepherd from idea to done. **Not a timeline.** Don't add Priority, Owner, or Dependencies — those belong on a feature doc once an idea is promoted.
>
> **Lifecycle:** ideas land under `## Captured` (manually via `louie-roadmap add`, or via the save step at the end of `louie-ideate`). When an idea is built, `louie-feature --from-roadmap <id>` moves it to `## Promoted` with a back-link to the feature folder. The per-entry `Status` field tracks the finer lifecycle (`Captured` → `In Progress` → `Done`, plus `Deferred` / `Dropped`); change it with `louie-roadmap-change`. `louie-feature` keeps it in sync for roadmap-linked work. This file is created at `louie-setup` (and on `louie-import` / `louie-migrate`) so it always exists.
>
> **Where this is not:** `_LOUIE-output/implementations/overview.md` "Planned" rows are for features that already have a folder, requirements, and architecture evaluation. Captured ideas live here until they earn that.

## Captured

<!-- Entries go here, newest first. Schema:

### R-001: Short title

- Created: YYYY-MM-DD
- Status: Captured | Deferred | Dropped
- Source: ideate | manual | feature-work | bugfix
- Effort: S | M | L         (optional — only if the user supplied one)
- Notes:

  Free text. When captured from Ivy, her full idea card goes here verbatim
  (what / why / effort / builds-on / fits-architecture).

-->

_No ideas captured yet._

## Promoted

<!-- Entries move here when `louie-feature --from-roadmap <id>` runs. Format:

### R-001: Short title

- Created: YYYY-MM-DD
- Status: In Progress | Done | Dropped
- Promoted: YYYY-MM-DD → `_LOUIE-output/implementations/<feature>/`
- Notes: [original notes preserved verbatim]

-->

_No ideas promoted yet._
