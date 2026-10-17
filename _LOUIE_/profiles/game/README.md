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

## Install

- **Claude Code:** `_LOUIE_/setup/claude-init.sh/.bat` reads the profile from the runbook. On `game` it copies `agents/*.md` into `.claude/agents/`; on `standard` it removes them again. `louie-profile`, `louie-setup`, and `louie-update-framework` re-run it, so the installed agents always match the runbook.
- **Other runtimes:** agents run via read-and-follow; no install step.
