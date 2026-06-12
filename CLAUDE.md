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
| `louie-continue` | `_LOUIE_/commands/louie-continue.md` | Resume in-progress work after a break (reconstruct from artifacts + git) |
| `louie-review` | `_LOUIE_/commands/louie-review.md` | Code review by Max |
| `louie-review-doc` | `_LOUIE_/commands/louie-review-doc.md` | Review + fix + update docs |
| `louie-evaluate` | `_LOUIE_/commands/louie-evaluate.md` | Whole-codebase standards assessment with persistent findings + optional step-by-step apply loop |
| `louie-review-mode` | `_LOUIE_/commands/louie-review-mode.md` | View or change the project review mode (manual / auto-fix-critical / auto-fix-all) |
| `louie-branch-mode` | `_LOUIE_/commands/louie-branch-mode.md` | View or change the project branch mode (current / ask) |
| `louie-autopilot-mode` | `_LOUIE_/commands/louie-autopilot-mode.md` | View or change the per-command auto-pilot mode (run the chain unattended after plan approval) |
| `louie-test` | `_LOUIE_/commands/louie-test.md` | Write or improve tests with Ava |
| `louie-doc` | `_LOUIE_/commands/louie-doc.md` | Update documentation + commit message |
| `louie-ideate` | `_LOUIE_/commands/louie-ideate.md` | Brainstorm ideas with Ivy |
| `louie-roadmap` | `_LOUIE_/commands/louie-roadmap.md` | Capture / promote bigger changes (epics) in `_LOUIE-output/roadmap.md` |
| `louie-roadmap-change` | `_LOUIE_/commands/louie-roadmap-change.md` | Change a roadmap entry (status / notes / effort; defer / drop) |
| `louie-recipe` | `_LOUIE_/commands/louie-recipe.md` | Browse or load a reusable recipe |
| `louie-update-framework` | `_LOUIE_/commands/louie-update-framework.md` | Update LOUIE to the latest version |
| `louie-from-source` | `_LOUIE_/commands/louie-from-source.md` | Fetch a task from a source adapter and route it to the right command |

## Critical Rules

1. **Never implement directly** — create a feature document and get user confirmation first.
2. **Never start feature work** without a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
3. **Never merge to `main`** without explicit user approval after Max's review and Ava's tests pass. (This gate applies when work is on a feature branch; see Branch Mode below.)
4. **Branching is governed by Branch Mode** (`_LOUIE-output/runbook.md` § Branch Mode, `_LOUIE_/commands/louie-branch-mode.md`). Default `current` — work on the current branch, including `main`; LOUIE never creates a branch on its own and only branches when you ask or under `ask` mode. There is no "never commit to `main`" rule. When a merge from a branch produces new SHAs (e.g. a squashed PR), sync local main with `git fetch origin && git reset --hard origin/main` to avoid stop-hook "unpushed commits on main" warnings.
5. **Never write implementation learnings to `_LOUIE-output/runbook.md`.** The runbook is operational reference only (ports, env vars, external services, commands, first-check debugging). Framework quirks, cache rules, "I learned X during Phase 4" → code-local `// WHY` comments + per-feature `bugfixes/<slug>.md` § Detect / Avoid. There is no `## Common Gotchas` section; do not create one. This applies on every edit path, including ad-hoc "update the specs" requests that don't route through a `louie-*` command.

## Key References

- `README.md` — framework overview
- `_LOUIE_/workflow/ai-workflow.md` — full workflow with scenarios
- `_LOUIE_/guidelines/coding-guidelines.md` — coding rules all agents follow
- `_LOUIE_/guidelines/interaction-guidelines.md` — how to ask the user to choose (structured choice / lettered fallback)
- `_LOUIE_/agents/` — agent definitions (read when invoking an agent)
- `_LOUIE-output/` — agent-produced artifacts (requirements, architecture, tech stack, runbook, feature docs)

## Framework-Dev Only

This repository is the LOUIE framework itself. When working on *extending the framework* (adding commands, agents, recipes, templates, or cross-cutting rules), read `_LOUIE-internals/README.md` on demand for internal architecture and conventions.

`_LOUIE-internals/` is **not** part of the distributed framework — it stays in this repo and must never be referenced from user-facing docs or generated downstream files. Do not preload it.
<!-- /LOUIE-FRAMEWORK -->
