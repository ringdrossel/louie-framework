# Core Mechanics

How LOUIE works under the hood. Read this before changing anything cross-cutting.

## Three Directories

LOUIE uses three top-level directories in the framework repository. Only two of them ship.

| Directory | Purpose | Distributed? |
|-----------|---------|--------------|
| `_LOUIE_/` | The framework: agents, commands, templates, guidelines, workflow, setup scripts, recipes | Yes — copied into downstream projects |
| `_LOUIE-output/` | Agent-produced artifacts: requirements, architecture, implementations | Yes — copied empty, filled per project |
| `_LOUIE-internals/` | Framework-dev docs (this folder) | **No** — stays in the framework repo only |

The underscore/dash prefixes make all three sort to the top of file explorers. Downstream users see only `_LOUIE_/` and `_LOUIE-output/`; the presence of `_LOUIE-internals/` in this repo is invisible to them.

## Lazy-Loading Principle

**Only `CLAUDE.md` auto-loads every request.** Everything else in `_LOUIE_/` is read on demand — when a command is invoked, when an agent is summoned, when a template is opened.

This is the core performance and signal-to-noise mechanism. It means:

- `CLAUDE.md` must stay small. It's a loader, not a spec.
- Commands (`_LOUIE_/commands/*.md`) are dormant until the user types `louie-*`.
- Agent definitions (`_LOUIE_/agents/*.md`) are dormant until invoked.
- Templates are dormant until an agent fills one in.
- Internal docs (`_LOUIE-internals/`) are dormant until framework-dev work is happening.

When adding a new file: default to dormant. Only add a `CLAUDE.md` reference if it must be in context for *every* user request. If in doubt, leave it out — Claude can always read it on demand.

## Distribution Model

Downstream installation flow (see `_LOUIE_/setup/project-setup.md`):

1. User copies `_LOUIE_/` and `_LOUIE-output/` into their project root.
2. User runs `_LOUIE_/setup/<tool>-init.sh/.bat` for their AI tool.

What the init scripts do:

- `claude-init.sh/.bat` → copies `_LOUIE_/commands/louie-*.md` into `.claude/commands/` and appends a LOUIE section to the downstream `CLAUDE.md`.
- `cursor-init.sh/.bat` → appends a LOUIE section to the downstream `.cursorrules`.
- `codex-init.sh/.bat` → appends a LOUIE section to the downstream `AGENTS.md`.

**None of the init scripts do a blanket copy of `_LOUIE_/`.** They operate on specific paths. Anything outside those paths (e.g. `_LOUIE-internals/`) is automatically not-distributed as long as the user follows the Step 1 copy instruction.

When adding a new file that should ship: put it under `_LOUIE_/`. When adding a file that should *not* ship: put it under `_LOUIE-internals/`.

## Confirmation Gates

LOUIE enforces two gates in the full feature chain:

1. **Architecture gate** — no feature work begins until `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md` are approved by the user.
2. **Feature doc gate** — no implementation begins until the feature document in `_LOUIE-output/implementations/[feature].md` is approved.

These are load-bearing. They catch mistakes before expensive work happens. Any new command or flow that produces code **must** respect them, either by running through the existing chain or by re-asserting the gates explicitly.

Additionally, a third rule (added later): **no merge to `main` without explicit user approval** after Max reviews and Ava tests pass. This is a git-time gate, not a chain-time gate.

## Naming Conventions

### Files

- **Lowercase-kebab-case** for all filenames: `louie-feature.md`, `build-push.md`, `user-authentication-requirements.md`.
- **Never** use spaces, underscores inside names, or camelCase in filenames (the leading `_` on directories is the exception).
- Reason: cross-platform case handling. Linux is case-sensitive; macOS/Windows are not. Lowercase-kebab eliminates divergence.

### Commands

- All user-invocable commands start with `louie-` (e.g. `louie-feature`, `louie-recipe`).
- The file `_LOUIE_/commands/<name>.md` defines `louie-<name>`. The `louie-` prefix is baked into the filename — don't strip it.

### Agents

- One file per agent: `_LOUIE_/agents/<role>.md` (e.g. `analyst.md`, `coder.md`). No name prefix on files.
- Each agent has a persona with a first-name (Tom, Sophie, Leo, Nina, Max, Ava, Ivy) and a Voice section. New agents follow the same shape.

### Artifacts

- Requirements: `_LOUIE-output/requirements/<feature>-requirements.md`
- Implementations: `_LOUIE-output/implementations/<feature>.md`

## Cross-Platform Constraints

LOUIE must work identically on macOS, Linux, and Windows.

### Path Separators

Use forward slashes `/` in all documentation, command references, and agent instructions. Windows APIs accept forward slashes; backslashes don't work on Mac/Linux. Never document a backslash path.

### Case Sensitivity

- **Filenames:** enforce lowercase-kebab-case so the same path works on case-sensitive (Linux) and case-insensitive (Mac/Windows) filesystems.
- **User input:** when a command dispatcher matches on a user-supplied name (e.g. `louie-recipe Build-Push`), do a case-insensitive match as a fallback so users don't get Linux-only failures.

### Line Endings

Init scripts exist as both `.sh` (Mac/Linux) and `.bat` (Windows). When adding a new init script, add both. Keep them behaviorally identical.

## Handoff Conventions

Agents hand off by ending their response with a structured handoff block (see `_LOUIE_/workflow/agent-handoffs.md`). When adding a new agent, follow the same shape: a summary, what was produced, and the next agent to invoke.

## What To Read When

| You're adding... | Read first |
|------------------|-----------|
| A new `louie-*` command | Existing `_LOUIE_/commands/` files for shape; `core.md` for naming/lazy-loading |
| A new agent | Existing `_LOUIE_/agents/` files for Voice + handoff shape |
| A recipe | `recipes.md` |
| A template | Existing `_LOUIE_/templates/` files |
| A cross-cutting rule | This file |
