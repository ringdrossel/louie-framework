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
- `gemini-init.sh/.bat` → appends a LOUIE section to the downstream `GEMINI.md`.
- `opencode-init.sh/.bat` → appends a LOUIE section to the downstream `AGENTS.md` (opencode's native convention; functionally equivalent to the Codex script but kept separate for discoverability).
- `pi-init.sh/.bat` → appends a LOUIE section to the downstream `AGENTS.md` (pi.dev's native convention; functionally equivalent to the Codex script but kept separate for discoverability).

**None of the init scripts do a blanket copy of `_LOUIE_/`.** They operate on specific paths. Anything outside those paths (e.g. `_LOUIE-internals/`) is automatically not-distributed as long as the user follows the Step 1 copy instruction.

When adding a new file that should ship: put it under `_LOUIE_/`. When adding a file that should *not* ship: put it under `_LOUIE-internals/`.

## Confirmation Gates

LOUIE enforces two gates in the full feature chain:

1. **Architecture gate** — no feature work begins until `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md` are approved by the user.
2. **Feature doc gate** — no implementation begins until the feature document in `_LOUIE-output/implementations/[feature]/feature.md` is approved.

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

- Per-feature folder: `_LOUIE-output/implementations/<feature>/`
- Implementation doc: `_LOUIE-output/implementations/<feature>/feature.md`
- Requirements: `_LOUIE-output/implementations/<feature>/requirements.md`
- Decisions (feature-scoped ADRs): `_LOUIE-output/implementations/<feature>/decisions.md`
- Per-feature bug fixes: `_LOUIE-output/implementations/<feature>/bugfixes/<YYYY-MM-DD>-<slug>.md`
- Cross-cutting bug fixes: `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>.md`
- Bug-fix index: `_LOUIE-output/bugfixes/overview.md`
- Feature index: `_LOUIE-output/implementations/overview.md` (slim — one-line description per feature)
- Partitioned architecture (large projects, threshold-triggered): `_LOUIE-output/architecture.md` (slim index) + `_LOUIE-output/architecture/<domain>.md`
- Codebase map (large projects): `_LOUIE-output/codebase-map.md` — descriptive index (domain → paths → entry points → owning features → size); sibling of the architecture split, same threshold

See `_LOUIE-internals/scaling.md` for the design rationale (universal per-feature folders, lazy-loading-friendly, AI-efficiency criterion). The scale pattern is always the same move: slim index up top, partitioned detail below, lazy-load the partition you need. **Domain names are the partition vocabulary** — defined once in the architecture index, reused by the codebase map, overview grouping, and evaluate chunks. Read discipline for agents at scale is single-sourced in `_LOUIE_/guidelines/execution-guidelines.md` § Context Discipline.

## Cross-Platform Constraints

LOUIE must work identically on macOS, Linux, and Windows.

### Path Separators

Use forward slashes `/` in all documentation, command references, and agent instructions. Windows APIs accept forward slashes; backslashes don't work on Mac/Linux. Never document a backslash path.

### Case Sensitivity

- **Filenames:** enforce lowercase-kebab-case so the same path works on case-sensitive (Linux) and case-insensitive (Mac/Windows) filesystems.
- **User input:** when a command dispatcher matches on a user-supplied name (e.g. `louie-recipe Build-Push`), do a case-insensitive match as a fallback so users don't get Linux-only failures.

### Line Endings

Init scripts exist as both `.sh` (Mac/Linux) and `.bat` (Windows). When adding a new init script, add both. Keep them behaviorally identical.

## Versioning & Release Process

The framework carries a semver stamp in `_LOUIE_/VERSION` (single line). Because it lives inside `_LOUIE_/`, every downstream copy is stamped automatically, and `louie-update-framework`'s wholesale replace propagates new versions with no extra machinery.

Semantics:

- **Major** — breaking artifact-shape changes (the flat→per-feature layout change would have been a major). These are the versions migrations gate on: `louie-update-framework` runs a migration when its trigger version falls in the local→pulled gap.
- **Minor** — new commands, agents, recipes, settings, or behavior.
- **Patch** — fixes and doc corrections.

Cutting a release (do this when merging accumulated work to `main`):

1. In `_LOUIE-internals/CHANGELOG.md`, move the `## Unreleased` content under a new `## <version> — <YYYY-MM-DD>` header (newest release directly below `## Unreleased`).
2. Set `_LOUIE_/VERSION` to the same version, in the same commit.
3. Run `bash _LOUIE-internals/tools/check-consistency.sh` — its check 5 fails on a release header without a matching VERSION and vice versa, so a half-done cut can't land.
4. Tag the merge commit on `main` as `v<version>`.

`louie-update-framework` reads the changelog from its temp clone (the file is in `_LOUIE-internals/`, which is never installed downstream) and prints the sections between the project's version and the pulled one. Projects installed before versioning have no `_LOUIE_/VERSION`; the command detects that and falls back to file-diff reporting and filesystem-based migration detection.

Historical note: releases before 1.0.0 (2026-07-02) were tagged `v05.x` with no VERSION file; those tags remain as history and play no role in the version-gating logic.

## Monorepo Direction

Decision rule for a repo containing multiple packages (backend/frontend/mobile, or several services). No machinery — this is a documented convention, not a new flow.

- **Default: one `_LOUIE-output/` per repo, even for monorepos.** The domain partitioning (`architecture.md` split, `codebase-map.md`, overview grouping — all S-01/S-02/S-03) carries the backend/frontend/mobile structure. Features regularly span packages — an API + UI feature is *one* feature — and a per-package `_LOUIE-output/` would force cross-cutting features into two half-artifacts. `tech-stack.md` gains a **Per-Package Commands** table (install/lint/test/build per package) so Nina and Ava know which package's commands to run for a given path; the work-package `Files:` scopes map each change to its package mechanically.
- **Exception: genuinely independent products in one repo** (separate deploys, separate users, near-zero shared code) → a per-product `_LOUIE-output/` in each product root. Commands operate on the nearest `_LOUIE-output/` above the working path.

The test is shared-code and shared-features, not directory count: if features cross the package boundary, it's one install; if the products never share a feature, split them.

## Handoff Conventions

Agents hand off by ending their response with a structured handoff block (see `_LOUIE_/workflow/agent-handoffs.md`). When adding a new agent, follow the same shape: a summary, what was produced, and the next agent to invoke.

## Agents as Subagents

Every `_LOUIE_/agents/*.md` file carries Claude Code subagent frontmatter (`name`, `description`, `tools`). `claude-init.sh/.bat` installs them to `.claude/agents/`, making them natively dispatchable; on every other runtime (and in manual mode everywhere) agents run via inline "read and follow" — the universal fallback. Which stage may run as a subagent is defined in `_LOUIE_/guidelines/execution-guidelines.md` (interactive stages never; work stages during unattended stretches).

Frontmatter rules:

- **No `model:` key — deliberate.** Subagents inherit the session model. A pinned model silently downgrades users running a stronger model on the most judgment-heavy stages (Sophie, Max), and a hardcoded model name ages with no owner. If cost-tiering is ever wanted, do it deliberately: document here which stages tolerate a cheaper tier, and revisit at every release cut.
- **`tools:` reflects what the agent does when dispatched.** Nina and Ava have `Edit, Write, Bash` (they write code/tests and run commands). Tom, Sophie, Leo, Max, Ivy stay read-only: conversational stages run in the main loop anyway, and read-only subagents (Sophie's eval, Max's review) *return* their doc changes/verdicts for the orchestrator to apply — see the dispatch table in `execution-guidelines.md`.

## What To Read When

| You're adding... | Read first |
|------------------|-----------|
| A new `louie-*` command | Existing `_LOUIE_/commands/` files for shape; `core.md` for naming/lazy-loading |
| A new agent | Existing `_LOUIE_/agents/` files for Voice + handoff shape |
| A recipe | `recipes.md` |
| A template | Existing `_LOUIE_/templates/` files |
| A cross-cutting rule | This file |
