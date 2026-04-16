# Project Setup with LOUIE

## Overview

This guide walks you through deploying the LOUIE framework into a new project and running your first agent sequence.

## Step 1: Copy the Framework

Copy both `_LOUIE_/` and `_LOUIE-output/` into your project root:

```
your-project/
├── _LOUIE_/              ← the framework (tool)
├── _LOUIE-output/        ← pre-created output directories (work)
│   ├── requirements/
│   └── implementations/
├── src/                  ← your source code
└── README.md
```

Both directories are included in the repo — no manual setup needed. `_LOUIE-output/` comes with the right folder structure so agents can write their artifacts immediately.

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

1. **Manual bootstrap:** Tell your AI assistant "Read `_LOUIE_/README.md` to understand the LOUIE framework" at the start of each session. After that, `louie-*` commands will work.
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
2. **Sophie (Architect)** defines architecture and tech stack
3. Both are shown for your **confirmation** before any code is written

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

1. Copy both `_LOUIE_/` and `_LOUIE-output/` into the project root
2. Run Sophie (Architect) to document your existing architecture and tech stack
4. From now on, follow the standard workflow for new features

You don't need to retroactively create requirements or feature docs for existing code — just use LOUIE going forward.

## Updating LOUIE

To update the framework:

1. Replace the `_LOUIE_/` directory with the new version
2. Your `_LOUIE-output/` artifacts are untouched — they live separately by design
3. Review the changelog for any changes to agent behavior or templates

## Quick Reference

| What you want | Command |
|---------------|---------|
| Start a new project | `louie-setup` |
| Add a feature | `louie-feature` |
| Extend a feature | `louie-extend` |
| Quick small change | `louie-update` |
| Fix a bug | `louie-bugfix` |
| Review code | `louie-review` |
| Review + fix + update docs | `louie-review-doc` |
| Write tests | `louie-test` |
| Update documentation | `louie-doc` |
| Brainstorm ideas | `louie-ideate` |
