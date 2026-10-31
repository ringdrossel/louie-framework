# Project Profiles

**Audience:** AI assistants working on the LOUIE framework. Design notes for project profiles — an optional, per-project specialization of the agent team — and the first profile, `game`.

## Problem

LOUIE assumed application development. For a story-driven game (first use case: a Fire Emblem-style tactics RPG with story, supports, and romance, built in Godot) that assumption shows up everywhere:

- Leo designs mobile-first against WCAG 2.1 AA and ARIA and outputs component trees with props; HUDs, menus, gamepad navigation, and game mechanics have no owner.
- Nobody owns story, characters, dialogue, or relationship arcs.
- Ava prioritizes auth, input validation, and injection; a game needs determinism, save/load integrity, content integrity, and balancing.
- Content (chapters, characters, maps) doesn't fit the per-feature chain Tom → Sophie → Leo → Nina → Max → Ava.
- The tech-stack and runbook templates assume backend/frontend/database and ports/endpoints.

**Hard requirement:** the game material must be completely inert in non-game projects. A standard project behaves as in 1.2.1; the only visible differences are the new runbook setting, the new commands, and one dormant line per affected agent.

## Design

| Piece | Where | Why |
|-------|-------|-----|
| Setting | `_LOUIE-output/runbook.md` § Project Profile (`Profile: standard \| game`, `Set:`) | Same pattern as Review / Branch / Auto-Pilot mode and Language (see `review-mode.md`, `language.md`): per-project, tool-agnostic, already in agents' context. **Absent = `standard`**, so no migration. |
| Command | `louie-profile` | Views/changes the setting; seeds artifacts on a switch to `game`; never deletes on a switch back. Modeled on `louie-language`. |
| Profile material | `_LOUIE_/profiles/game/` (`agents/`, `overlays/`, `templates/`, `README.md`) | Never in `_LOUIE_/agents/`: `claude-init` installs every file there as a subagent, which would put Kai and Mira into every project. |
| New agents | Kai (Game Designer, read-only), Mira (Narrative Designer, Edit/Write) | The two missing owners: rules/numbers/levels, and world/characters/dialogue. |
| Overlays | Tom, Sophie, Leo, Nina, Max, Ava | Game-specific replacements for the parts of each base agent that assume an app. Ivy needs none. |
| Content flow | `louie-content` | Content is not a feature (below). |
| Engine specifics | `_LOUIE_/recipes/game/` | Agents, overlays, and guidelines stay engine-agnostic. |

### Why overlays instead of forked agents

Forking `designer.md` into `game-designer-leo.md` (and so on for five agents) would duplicate the voice, gates, auto-pilot, agentic, and handoff rules — the parts that change most often across releases — and every later change to a base agent would have to be made twice or drift. An overlay states only the delta ("replace Responsibilities with …", "the checklist's § 5 applies only to online features"), so the base agent stays the single source of truth for everything else. The cost is that an overlay must name what it overrides precisely; each one opens with "where the two conflict, this file wins" and lists what stays unchanged.

### Why a separate folder

`claude-init.sh/.bat` copies `_LOUIE_/agents/*.md` into `.claude/agents/` unconditionally. Putting Kai and Mira there would make them installed — and dispatchable by description — in every project. `_LOUIE_/profiles/<profile>/` keeps everything a profile adds in one place, invisible to the unconditional install and to lazy loading, and gives future profiles an obvious home.

### Why content is not a feature

A chapter or a support conversation has no requirements interview, architecture evaluation, implementation plan, or code review — running it through Tom → Sophie → feature doc → Nina → Max → Ava is all ceremony. `louie-content` is a short flow: brief → proposal gate → write → consistency check → optional Ava content-integrity tests → overview update. Its gate replaces the feature-doc gate, which is only safe because **content writes are limited to the paths `architecture.md` § Content Pipeline declares** and never touch code (Critical Rule 1 still holds for code). A brief that needs a system change is rerouted to `louie-feature` / `louie-extend` / `louie-update`.

## Gating

Three mechanisms, each with one owner:

1. **Install (Claude Code):** `claude-init.sh/.bat` read the runbook's `Profile:` line (bare value, optional backticks, CRLF-tolerant) and converge `.claude/agents/` to it — copy `profiles/game/agents/*.md` on `game`, remove exactly those files (only when the frontmatter `name:` matches ours) otherwise. `louie-profile`, `louie-setup`, `louie-import`, and `louie-update-framework` re-run the init script instead of copying agents themselves, so there is one install path to keep correct and testable. Other runtimes use read-and-follow and have no install step.
2. **Agents:** each affected base agent has exactly one line in its Context section: *if the project profile is `game` (as passed by the invoking command, else the runbook; absent = `standard`), also read the overlay.* The "as passed" clause exists because Tom, Leo, and Ava don't otherwise read the runbook; the chain commands resolve the profile once and pass it on, so a standard run gains no extra read.
3. **Commands:** every command that can involve a game agent resolves the profile once (it usually reads the runbook already) and keeps all game steps in blocks headed "Only if the profile is `game`". `louie-update` and `louie-status` don't otherwise read the runbook; they look up only the Project Profile section. `louie-content` checks first and refuses in one line; `louie-recipe` warns when a recipe's `**Requires profile:**` line differs from the project profile.

**Enforcement:** `tools/check-consistency.sh` check 6 fails on any reference to `_LOUIE_/profiles/` in files that load for every project (root `CLAUDE.md`, agents, commands, workflow, guidelines, templates, init scripts) that isn't behind a profile check on the same line or in its enclosing block. `louie-profile` and `louie-content` are exempt by design.

**Setup without a question.** Asking "is this a game?" in every `louie-setup` would be a visible change for every standard user. Setup asks only when the idea clearly describes a game; import asks only when it finds `project.godot`, `ProjectSettings/`, or `*.uproject`. Otherwise the profile is silently `standard`, like the other defaults. The runbook doesn't exist yet when Tom starts, so the answer is held for the run (and in the checkpoint) and written at step 5g / 10f.

**Lazy loading holds.** Root and downstream `CLAUDE.md` gained only the two command rows. `ai-workflow.md` and `agent-handoffs.md` — read by standard runs — carry one guarded pointer each; the game scenario and handoffs live in `_LOUIE_/profiles/game/README.md`.

## Decisions taken with the user

- **Kai writes data, Mira writes dialogue — both only into declared content paths.** Kai stays read-only as a subagent (the orchestrator applies his output).
- **Mira joins `louie-feature` before the feature-doc gate** (not after it), so the user approves a feature's content schema with the plan.
- **Nina has an overlay too** (six overlays, not five): without one she'd be the only implementation-path agent working from web assumptions.
- **No persistent auto-pilot key for `louie-content`** — a new `content:` key would appear in every standard runbook. `--auto` per call covers the post-approval stretch; the proposal gate and creative forks always stop.
- **Content status** `Planned → Outlined → Drafted → Checked → Final`; only the user sets `Final`.
- **Creative and balance forks pause even under auto-pilot**; under `--agentic` they halt with `status: needs-human`. That is the only agentic-mode addition.
- **Recipes:** Dialogue Manager 4 (Godot 4.6+); Coding-Solo/godot-mcp as the default MCP server, an editor-bridge server as a variation; engine-project markers added to all twelve init scripts' "existing project" detection (it pointed Godot projects at `louie-setup` instead of `louie-import`).

## Adding a future profile

A new profile `<p>` plugs in without touching the gating design:

1. Create `_LOUIE_/profiles/<p>/` with `README.md` and whichever of `agents/`, `overlays/`, `templates/` it needs.
2. Add `<p>` as a value in `louie-profile.md` and the runbook template's valid values; extend the seed table if it has skeletons.
3. Generalize the init scripts' convergence from `profiles/game/agents` to `profiles/<active>/agents` plus removal of every other profile's agents (today the code is written for one profile — make it a loop when the second one arrives, not before).
4. Overlay hooks: extend each base agent's single line to "read `_LOUIE_/profiles/<profile>/overlays/<agent>.md` if it exists" rather than adding a second line per profile.
5. Commands: guarded blocks per profile; extend check 6's guard phrases.
6. Recipes declare `**Requires profile:** <p>`.

Profiles are mutually exclusive by design (one `Profile:` value). Combining them (a game with an online backend) is handled inside a profile's overlays (e.g. Max's game overlay re-enables web security checks for online features), not by stacking profiles.

## Files touched

Distributed: `_LOUIE_/commands/louie-profile.md` and `louie-content.md` (new); `_LOUIE_/profiles/game/**` (new); `_LOUIE_/recipes/game/**` (new); `_LOUIE_/templates/runbook-template.md`; `_LOUIE_/agents/{analyst,architect,designer,coder,reviewer,tester}.md` (one line each); `_LOUIE_/commands/{louie-setup,louie-import,louie-feature,louie-extend,louie-update,louie-bugfix,louie-continue,louie-status,louie-evaluate,louie-update-framework,louie-recipe}.md`; `_LOUIE_/recipes/README.md`; `_LOUIE_/workflow/{ai-workflow,agent-handoffs}.md`; all twelve `_LOUIE_/setup/*-init.sh/.bat`; `_LOUIE_/setup/project-setup.md`; root `CLAUDE.md`, `README.md`, `QUICKSTART.md`.

Internals: this file; `README.md` index; `core.md`; `recipes.md`; `tools/check-consistency.sh` + `tools/README.md` (check 6); `CHANGELOG.md`.
