<!-- LOUIE-FRAMEWORK -->
# LOUIE Framework

This project uses **LOUIE** (Lean Orchestration for Unified Intelligent Engineering) for AI-assisted development.

## Commands

When the user types a `louie-*` command, read the matching file from `_LOUIE_/commands/` and follow the instructions in it.

| Command | File | Description |
|---------|------|-------------|
| `louie-setup` | `_LOUIE_/commands/louie-setup.md` | Initialize a new project |
| `louie-import` | `_LOUIE_/commands/louie-import.md` | Import an existing project (cold or v1 docs) into LOUIE |
| `louie-migrate` | `_LOUIE_/commands/louie-migrate.md` | Migrate an old-layout LOUIE project to the per-feature folder layout |
| `louie-feature` | `_LOUIE_/commands/louie-feature.md` | Add a new feature (full agent chain) |
| `louie-extend` | `_LOUIE_/commands/louie-extend.md` | Extend an existing feature |
| `louie-update` | `_LOUIE_/commands/louie-update.md` | Quick change (< 50 lines) |
| `louie-bugfix` | `_LOUIE_/commands/louie-bugfix.md` | Diagnose and fix a bug |
| `louie-review` | `_LOUIE_/commands/louie-review.md` | Code review by Max |
| `louie-review-doc` | `_LOUIE_/commands/louie-review-doc.md` | Review + fix + update docs |
| `louie-test` | `_LOUIE_/commands/louie-test.md` | Write or improve tests with Ava |
| `louie-doc` | `_LOUIE_/commands/louie-doc.md` | Update documentation + commit message |
| `louie-ideate` | `_LOUIE_/commands/louie-ideate.md` | Brainstorm ideas with Ivy |
| `louie-roadmap` | `_LOUIE_/commands/louie-roadmap.md` | Capture / promote pre-feature ideas in `_LOUIE-output/roadmap.md` |
| `louie-recipe` | `_LOUIE_/commands/louie-recipe.md` | Browse or load a reusable recipe |
| `louie-update-framework` | `_LOUIE_/commands/louie-update-framework.md` | Update LOUIE to the latest version |

## Critical Rules

1. **Never implement directly** — create a feature document and get user confirmation first.
2. **Never start feature work** without a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
3. **Never merge to `main`** without explicit user approval after Max's review and Ava's tests pass.
4. **Never touch local `main` directly.** Do not check it out to merge, fast-forward, or commit. All work happens on a feature branch; merges to `main` go through a PR (GitHub API merge if branch protection blocks direct pushes). After a PR merges — which rebases/squashes and produces new SHAs — sync local main with `git fetch origin && git reset --hard origin/main`. This keeps local `main` identical to `origin/main` and avoids stop-hook "unpushed commits on main" warnings caused by SHA divergence.

## Key References

- `README.md` — framework overview
- `_LOUIE_/workflow/ai-workflow.md` — full workflow with scenarios
- `_LOUIE_/guidelines/coding-guidelines.md` — coding rules all agents follow
- `_LOUIE_/agents/` — agent definitions (read when invoking an agent)
- `_LOUIE-output/` — agent-produced artifacts (requirements, architecture, tech stack, runbook, feature docs)

## Framework-Dev Only

This repository is the LOUIE framework itself. When working on *extending the framework* (adding commands, agents, recipes, templates, or cross-cutting rules), read `_LOUIE-internals/README.md` on demand for internal architecture and conventions.

`_LOUIE-internals/` is **not** part of the distributed framework — it stays in this repo and must never be referenced from user-facing docs or generated downstream files. Do not preload it.
<!-- /LOUIE-FRAMEWORK -->
