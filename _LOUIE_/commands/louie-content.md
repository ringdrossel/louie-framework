# louie-content

When the user says **`louie-content`**, follow this procedure to produce game content — story, characters, chapters, dialogue, support conversations, maps, levels, balancing passes — with Mira (Narrative Designer) or Kai (Game Designer).

**Content is not a feature.** Systems (the combat code, the dialogue runtime, the support system) go through `louie-feature` / `louie-extend`. This command writes what those systems play: story documents in `_LOUIE-output/story/` and `_LOUIE-output/game-design/`, plus content files in the content paths `_LOUIE-output/architecture.md` § Content Pipeline declares. It never writes code. The agreed brief at the proposal gate stands in for the feature-doc gate — which is exactly why writes are limited to declared content paths.

> **Agentic:** invoked with `--agentic`? Read `_LOUIE_/workflow/agentic-mode.md` first and see `## Agentic` at the bottom.

## Procedure

Throughout the run: every stop that ends a turn closes with a **phase breadcrumb** and refreshes `_LOUIE-output/checkpoint.md` (task: `louie-content <target>`); the final step deletes the checkpoint. Both rules: `_LOUIE_/guidelines/interaction-guidelines.md` § Phase breadcrumb and § Checkpoint.

1. **Check the project profile first:**
   - Look up only the `## Project Profile` section of `_LOUIE-output/runbook.md` (absent section or file = `standard`).
   - **If it is not `game`**, stop with one polite line and read nothing else: "`louie-content` is part of LOUIE's game profile, and this project uses the `standard` profile. Run `louie-profile game` if this is a game project." Do not read any file under `_LOUIE_/profiles/`.

2. **Read project context and check prerequisites:**
   - Read `_LOUIE-output/architecture.md` (§ Content Pipeline and § Localization) and `_LOUIE-output/tech-stack.md`. If either is missing, stop: "No architecture yet — run `louie-setup` or `louie-import` first." (Critical Rule 2.)
   - Read `_LOUIE-output/story/overview.md` and `_LOUIE-output/game-design/overview.md`. If they are missing, offer `louie-profile game` (a repair pass that seeds missing skeletons) and stop.
   - If `architecture.md` has no `## Content Pipeline` section, or it declares no path for the kind of content requested, this run may write **planning documents only** (`story/`, `game-design/`), no content files. Say so up front and suggest `louie-extend` / `louie-feature` so Sophie declares the pipeline.

3. **Resolve the brief:**
   - If the user gave a brief with the command, use it.
   - Otherwise, if the overviews have `Planned` rows, offer them as a structured choice (plus "something else").
   - Otherwise ask: "What content should we work on? A chapter, a character, a support conversation, a map, a balancing pass — a sentence or two is enough."

4. **Route and scope:**
   - **Mira** (`_LOUIE_/profiles/game/agents/narrative-designer.md`, Mode C): story bible, characters, chapters, scenes and dialogue, support / romance conversations, flags.
   - **Kai** (`_LOUIE_/profiles/game/agents/game-designer.md`, Mode C): maps and levels, enemy rosters, balancing passes, stat data.
   - **Both:** a chapter with a battle — Mira first (story, scenes, flags), then Kai (map, roster, events), each with their own proposal gate; Kai's level doc references Mira's chapter doc.
   - **One unit per run:** one chapter, one character, one support pair, one map, or one balancing pass. A larger brief ("write act one") becomes a list of units: present it, add the units as `Planned` rows in the overview, and take the first one through this run — the same idea as Tom's scope split.
   - **Not content → reroute:** if the brief needs something the systems can't do (a new dialogue command or condition type, a new mechanic, a new UI), stop and name the right command (`louie-feature` / `louie-extend` / `louie-update`). Never work around a missing system inside content.

5. **Proposal gate** (the agent's Proposal & Discussion Gate — two-turn rule, content first):
   - The agent presents the proposal in chat and ends the turn. Loop until the user explicitly approves.
   - **Creative and balance forks** (plot turns, character deaths, romance outcomes, difficulty or progression changes) are decided by the user, always — `--auto` does not change that.
   - On approval: set the unit's status to `Outlined` in the overview.

6. **Write:**
   - The agent writes the planning documents (from the templates in `_LOUIE_/profiles/game/templates/`) and — only into declared content paths, in the declared format — the content files.
   - New flags are registered in `_LOUIE-output/story/flags.md` **before** content uses them.
   - Set the unit's status to `Drafted`.

7. **Consistency check:**
   - The agent runs its consistency check (narrative-designer.md / game-designer.md § Process): flags against `flags.md`, character presence and voice, emotion tags, branch reachability, continuity against `story-bible.md` and earlier chapters; for levels, balancing references, reachable win/lose conditions, and the progression curve.
   - Fixable issues: the agent fixes them and re-checks (at most two rounds). Anything left over is presented to the user, never silently accepted.
   - A clean check sets the status to `Checked`, and new continuity facts are appended to `story-bible.md` § Continuity Facts. Only the user sets `Final`.

8. **Optional content-integrity tests (Ava):**
   - If `tech-stack.md` defines a content-validation or headless test command, offer (structured choice, in its own response): **Run content-integrity tests** / **Skip**. With `--auto`, run them without asking.
   - On run: read and follow `_LOUIE_/agents/tester.md` (the game overlay applies) in its content-integrity mode, scoped to the touched content. A failing test sends the unit back to step 7.

9. **Update the indexes and wrap up:**
   - Update `story/overview.md` and/or `game-design/overview.md` (status, doc link, one-line summary), and the `Last Updated` line of every planning document touched.
   - Summarize: what was written (files), flags added, the check result, and the remaining `Planned` units.
   - Generate a commit message:
     ```
     feat(content): <unit> — <brief description>
     ```
   - **Delete `_LOUIE-output/checkpoint.md`** if present. Close with the next action (the next `Planned` unit via `louie-content`, or `louie-status`).

## Auto-Pilot

`louie-content` has no persistent auto-pilot setting. `louie-content --auto` lets steps 6–9 run without stopping once the proposal is approved: the agent writes, checks, runs Ava's tests if a command exists, and stops at the wrap-up. The proposal gate itself always stops, creative and balance forks always pause, and an unresolved consistency issue always stops.

## Agentic

When invoked with `--agentic`, an autonomous agent is driving. Full contract: `_LOUIE_/workflow/agentic-mode.md`.

- The profile check and prerequisites (steps 1–2) end the run with a run report `status: blocked` instead of a chat message.
- The brief must name one unit unambiguously; otherwise `status: needs-human` with the candidates.
- The proposal gate becomes evidential: the agent writes the proposal into the run report and continues only if it follows directly from the brief. **Any creative or balance fork halts the run** with `status: needs-human` and the fork as the pending decision. Unresolved consistency issues halt the same way.
- The run report goes to `_LOUIE-output/story/run-report.md` (Mira) or `_LOUIE-output/game-design/run-report.md` (Kai), using `_LOUIE_/templates/run-report-template.md` with its header unchanged and the per-agent sections replaced by one Mira or Kai section (proposal, files written, flags, consistency-check result). Committing stays the human's decision.

## Usage

```
louie-content
```

```
louie-content chapter 03 — the village ambush; Lyra meets Bram for the first time
louie-content character bram
louie-content support lyra x bram, C to A
louie-content map 03-village
louie-content --auto support lyra x bram, B
```
