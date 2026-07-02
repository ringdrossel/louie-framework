# LOUIE Internals

**Audience:** AI assistants working on the LOUIE framework itself, and the framework maintainer.

**Scope:** Design notes, conventions, and mechanics that explain *how LOUIE works internally*. Read these when extending the framework — adding a command, agent, recipe, template, or changing cross-cutting behavior.

## Not Distributed

This folder exists only in the framework's source repository. It is **not** copied into downstream projects when LOUIE is installed. Init scripts (`_LOUIE_/setup/*-init.sh/.bat`) never touch it. User-facing docs (`README.md`, `_LOUIE_/setup/project-setup.md`) never mention it.

If you're adding content here, keep it framework-internal. Nothing in this folder should be referenced from a distributed file.

## Index

| File | Topic |
|------|-------|
| `core.md` | Core mechanics — lazy loading, directory split, gates, naming, cross-platform |
| `recipes.md` | Recipe system design — dispatcher rules, folder layout, name resolution |
| `runbook.md` | Runbook system design — operational doc separate from architecture |
| `review-mode.md` | Review-mode setting design — manual / auto-fix modes, storage, loop |
| `branch-mode.md` | Branch-mode setting design — current / ask modes, default flip away from branch-per-feature |
| `autopilot.md` | Auto-pilot setting design — gate-at-agreement, per-command modes, deviation tripwire, review-mode composition |
| `language.md` | Language setting design — Conversation/Documents keys, auto-detect-and-persist, BMAD prior art, single-source-of-truth placement |
| `continue.md` | `louie-continue` design — artifact+git resume, no stored progress, why not chat-recovery |
| `adapters.md` | Source-adapter layer — public interface + `louie-from-source`, public/private split, concept handoff |
| `import.md` | Import system design — cold + v1-docs modes, init-script detection, agent reuse |
| `evaluate.md` | Evaluate system design — LOUIE/non-LOUIE modes, output schema, apply-loop routing, distinction from `louie-review` |
| `scaling.md` | Artifact-layout scaling design — per-feature folders, bugfix home, migration path |
| `BACKLOG.md` | Open ideas, gaps, and feature suggestions for the framework |
| `CHANGELOG.md` | Framework version log |
| `framework-evaluation/` | Evaluate-style self-assessment of the framework — persistent findings (parallelism, scaling, efficiency) with statuses; start at `framework-evaluation/summary.md` |

## When to Read What

- **Adding a `louie-*` command** → `core.md` (naming, lazy-loading)
- **Adding an agent** → `core.md` (handoff conventions)
- **Adding a recipe or changing the recipe system** → `recipes.md`
- **Changing `louie-evaluate` or its output schema** → `evaluate.md`
- **Changing anything that ships downstream** → `core.md` (distribution model)

## Authoring Rules For This Folder

- Write for AI readers. Be precise about paths, names, and mechanics.
- Keep each file focused on one topic. Split rather than append when a file grows past ~200 lines.
- When a design decision is made, record the *why*, not just the *what* — future sessions need the reasoning to extend correctly.
- No emoji, no screenshots, no marketing prose.
