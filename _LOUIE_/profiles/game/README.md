# Game Profile

Optional LOUIE profile for story-driven game projects. It is **inert unless** `_LOUIE-output/runbook.md` § Project Profile says `game` — set it with `louie-profile`. In a `standard` project nothing in this folder is read or installed.

The profile is engine-agnostic. Engine-, addon-, and tool-specific setup lives in the `game:` recipes (`louie-recipe list game`), never here.

## Layout

```
_LOUIE_/profiles/game/
  README.md      ← this file
  agents/        ← game-only agents (installed to .claude/agents/ only when the profile is game)
  overlays/      ← per-agent additions; an existing agent reads its overlay only when the profile is game
  templates/     ← skeletons for _LOUIE-output/game-design/, _LOUIE-output/story/, and game sections of the foundation docs
```

## Agents

| Agent | Owns | Maintains | Tools |
|-------|------|-----------|-------|
| **Kai** — Game Designer (`agents/game-designer.md`) | Core loop, mechanics and rules, formulas, balancing, progression, difficulty, map/level design | `_LOUIE-output/game-design/` (`overview.md`, `gdd.md`, `balancing.md`, `systems/<system>.md`, `levels/<map>.md`) and per-feature `mechanics.md` | Read, Glob, Grep |
| **Mira** — Narrative Designer (`agents/narrative-designer.md`) | World, plot, characters and their voices, chapter scripts, dialogue, support / romance arcs, branching consistency | `_LOUIE-output/story/` (`overview.md`, `story-bible.md`, `characters/<name>.md`, `chapters/<nn>-<slug>.md`, `relationships.md`, `flags.md`) and dialogue files in the declared content paths | Read, Glob, Grep, Edit, Write |

Both write specs and content, never engine code; `story/flags.md` is the contract between story and code; creative and balance forks pause even under auto-pilot (and halt agentic runs with `status: needs-human`).

## Overlays

Each existing agent has one conditional line in its Context section that loads its overlay only when the profile is `game`. Ivy has none.

| Overlay | Changes |
|---------|---------|
| `overlays/analyst.md` (Tom) | Game interview topics; splits work into systems features vs content |
| `overlays/architect.md` (Sophie) | Engine-centric architecture incl. the load-bearing `## Content Pipeline`; game tech-stack section; run/export/test runbook |
| `overlays/designer.md` (Leo) | Game UI/UX: input-first navigation, resolution scaling, game accessibility, scene/node trees |
| `overlays/coder.md` (Nina) | `mechanics.md` as rule source of truth, data over literals, logic/presentation split, seeded RNG, flag registry |
| `overlays/reviewer.md` (Max) | Engine anti-patterns, determinism, data/contract consistency; web security only for online features |
| `overlays/tester.md` (Ava) | Determinism, save/load round-trips, content integrity, balancing simulations; manual playtest checklist instead of E2E |

## Templates

`templates/`: `gdd`, `system`, `level`, `balancing`, `mechanics`, `game-design-overview` (Kai); `story-bible`, `character`, `chapter`, `relationships`, `flags`, `story-overview` (Mira); `playtest-checklist` (Ava); `tech-stack-game-section` (Sophie). `louie-profile` seeds the overview, gdd, balancing, story-bible, relationships, and flags skeletons on a switch to `game`.

## Content status

Chapters, characters, supports, and levels move `Planned` → `Outlined` → `Drafted` → `Checked` (consistency check passed) → `Final` (set by the user only).

## Install

- **Claude Code:** `_LOUIE_/setup/claude-init.sh/.bat` reads the profile from the runbook. On `game` it copies `agents/*.md` into `.claude/agents/`; on `standard` it removes them again. `louie-profile`, `louie-setup`, and `louie-update-framework` re-run it, so the installed agents always match the runbook.
- **Other runtimes:** agents run via read-and-follow; no install step.
