# Project Setup with LOUIE

## Overview

This guide walks you through deploying the LOUIE framework into a new project and running your first agent sequence.

## Step 1: Copy the Framework

Copy both `_LOUIE_/` and `_LOUIE-output/` into your project root:

```
your-project/
├── _LOUIE_/                            ← the framework (tool)
├── _LOUIE-output/                      ← pre-created output structure (work)
│   ├── implementations/
│   │   └── overview.md                 (slim index, populated as features land)
│   └── bugfixes/
│       └── overview.md                 (cross-project bug-fix index)
├── src/                                ← your source code
└── README.md
```

Both directories are included in the repo — no manual setup needed. As features land, agents create per-feature folders under `_LOUIE-output/implementations/<feature>/` containing `feature.md`, `requirements.md`, `decisions.md`, and `bugfixes/`.

## Step 2: Initialize for Your AI Tool

Run the init script for your AI tool to wire up LOUIE commands:

### Claude Code

```bash
# macOS / Linux
bash _LOUIE_/setup/claude-init.sh

# Windows
_LOUIE_\setup\claude-init.bat
```

This creates `CLAUDE.md` (project bootstrap) and copies all `louie-*` commands to `.claude/commands/` so they work as native slash commands (`/louie-setup`, `/louie-feature`, etc.).

### Cursor

```bash
# macOS / Linux
bash _LOUIE_/setup/cursor-init.sh

# Windows
_LOUIE_\setup\cursor-init.bat
```

This creates/updates `.cursorrules` with LOUIE command routing. Type `louie-setup` in Cursor chat and it will read the matching command file.

### Codex (OpenAI)

```bash
# macOS / Linux
bash _LOUIE_/setup/codex-init.sh

# Windows
_LOUIE_\setup\codex-init.bat
```

This creates/updates `AGENTS.md` with LOUIE command routing.

### Other AI Tools

If your tool isn't listed above, you have two options:

1. **Manual bootstrap:** Tell your AI assistant "Read `README.md` to understand the LOUIE framework" at the start of each session. After that, `louie-*` commands will work.
2. **Config file:** If your tool has a project-level instructions file (similar to `CLAUDE.md`), add the command routing section from any of the init scripts above.

> **Note:** All init scripts are idempotent — running them twice won't duplicate the LOUIE section. They detect existing sections and skip if already present.

## Step 3: First-Time Agent Sequence

When starting a brand new project, run the agents in this order:

### 3a. Run `louie-setup`

Type `louie-setup` (or `/louie-setup` in Claude Code) in your AI assistant, optionally followed by your project idea:

```
louie-setup

I want to build a recipe manager where I can save recipes from URLs,
organize them by tags, and plan weekly meals.
```

This kicks off the full setup sequence automatically:

1. **Tom (Analyst)** interviews you and produces requirements
2. **Sophie (Architect)** defines architecture, tech stack, and runbook (deployment model, ports, common commands, env vars, gotchas)
3. All three are shown for your **confirmation** before any code is written

See `_LOUIE_/commands/louie-setup.md` for the full command reference.

### 3b. Proceed with Feature Work

Once architecture is confirmed, use `louie-feature` to add features:

```
louie-feature
Add user authentication with email/password login.
```

This runs the full chain automatically: Tom → Sophie (eval) → feature doc → Leo → Nina → Max → Ava.

See `_LOUIE_/commands/` for all available commands.

## Git Recommendations

Add both directories to version control:

```bash
git add _LOUIE_/ _LOUIE-output/
git commit -m "docs: add LOUIE framework and initial artifacts"
```

Consider adding to `.gitignore` if you don't want to track agent output:

```
# Uncomment if you don't want agent artifacts in version control
# _LOUIE-output/
```

Most teams benefit from tracking `_LOUIE-output/` — it provides a history of requirements and architectural decisions.

## Adding LOUIE to an Existing Project

If your project already has source code but no LOUIE framework:

1. Copy both `_LOUIE_/` and `_LOUIE-output/` into the project root.
2. Run the init script for your AI tool (Step 2 above). The script detects existing source and prints a recommendation to run `louie-import` next.
3. Run `louie-import` in your AI tool. The command auto-detects two modes:
   - **Cold import** — no prior docs. Sophie scans the codebase to infer architecture, tech stack, runbook, and discovered features. Tom interviews to fill gaps.
   - **v1-docs import** — if `docs/implementations/overview.md` plus per-feature `*.md` siblings exist (the LOUIE precursor schema), they are translated into LOUIE format and code-scanned to fill what v1 didn't cover.
4. Confirm the architecture/tech-stack/runbook at the gate. Discovered features are written with status `Implemented` — the running code is the source of truth.
5. From now on, follow the standard workflow (`louie-feature`, `louie-extend`, `louie-bugfix`, etc.).

`louie-import` is a documentation pass only — it never modifies source code.

## Updating LOUIE

To update the framework, run `louie-update-framework` in your AI tool:

1. The command pulls the latest `_LOUIE_/` files (agents, commands, templates, guidelines, workflow, recipes).
2. Your `_LOUIE-output/` artifacts are untouched — they live separately by design.
3. The command checks for new canonical outputs (e.g. `runbook.md`) and offers to bootstrap them rather than silently creating files.
4. The command checks for the **old flat layout** (top-level `*.md` under `implementations/`, or a `requirements/` directory) and offers to run `louie-migrate` to restructure to the per-feature folder layout. Migration is one-way and uses `git mv` to preserve history.

Review the changelog for any changes to agent behavior or templates.

## Quick Reference

| What you want | Command |
|---------------|---------|
| Initialize a new project (Tom interviews, Sophie architects) | `louie-setup` |
| Import an existing project (cold or v1 docs) into LOUIE | `louie-import` |
| Migrate an old-layout LOUIE project to per-feature folders | `louie-migrate` |
| Add a new feature (full chain: Tom → Sophie → Leo → Nina → Max → Ava) | `louie-feature` |
| Extend an existing feature | `louie-extend` |
| Quick change (< 50 lines, auto-escalates to `louie-extend`) | `louie-update` |
| Diagnose and fix a bug | `louie-bugfix` |
| Code review by Max | `louie-review` |
| Review + fix + update docs in one flow | `louie-review-doc` |
| Write or improve tests with Ava | `louie-test` |
| Update documentation and generate a commit message | `louie-doc` |
| Brainstorm ideas with Ivy | `louie-ideate` |
| Update LOUIE to the latest version | `louie-update-framework` |
