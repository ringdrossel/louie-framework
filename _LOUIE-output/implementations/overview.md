# Project Overview

Last Updated: YYYY-MM-DD

> **Layout:** every feature lives in its own folder under `_LOUIE-output/implementations/<feature>/` containing `feature.md`, `requirements.md`, `decisions.md`, and `bugfixes/`. This file is a **slim index only** — one-line descriptions, status, and a link. Feature detail belongs in the feature's own `feature.md`. The cross-project bug-fix index lives in `_LOUIE-output/bugfixes/overview.md`. Pre-feature-folder ideas (captured but not yet committed) live in `_LOUIE-output/roadmap.md`.

## Project Context

[Brief description of the project — filled in during `louie-setup`]

**Goal:** [Main project goal]
**Status:** In Development

## Features

| Feature | Status | Priority | Depends on | Document | Description |
|---------|--------|----------|------------|----------|-------------|
| — | — | — | — | — | No features yet |

> **Status values:** `Planned` → `In Development` → `Implemented` → `Tested`, plus terminal `Retired`. The active states **mirror the feature's own `feature.md` checkboxes** — `louie-feature` advances them as work moves through the chain (`Planned` on add → `In Development` when coding starts → `Implemented`/`Tested` when it ships), and `louie-doc` reconciles any drift back to the `feature.md` truth.
> **`Retired`:** terminal status for a feature that's been removed or superseded. Set via `louie-doc` (or `louie-roadmap-change`-style one-liner); the row moves to a collapsed `### Retired` section at the bottom with a one-line reason. The feature folder stays on disk (history + bugfix docs remain searchable); agents skip Retired rows when scanning for context.
> **Depends on column convention:** other feature slugs this feature needs built first, or `—` for none (mirrors the feature's `feature.md` Metadata `Dependencies:`). Set by Tom at a scope split; it makes the inter-feature graph readable without opening folders and drives across-feature run ordering (see `_LOUIE_/guidelines/execution-guidelines.md` § Across-feature parallel runs).
> **Document column convention:** link to `implementations/<feature>/feature.md`.
> **Description column convention:** one short line. Don't write paragraphs here — the per-feature `feature.md` is the canonical home for detail.
>
> **Index scaling (applied by `louie-doc`'s reconcile pass, size-triggered):** below ~30 features, one flat table (this default). At ~30–100, group the table into one `### <domain>` section per domain (same domain names as `architecture.md` / `codebase-map.md`), each with the same columns. Past ~100, split to per-domain files `implementations/overview/<domain>.md` with this file as a top index (domain names + counts + in-flight items). Same slim-index-plus-partition move as everything else at scale.
