# louie-profile

When the user says **`louie-profile`**, view or change the project-wide profile that decides whether LOUIE runs as a **standard** project (application development — the default) or a **game** project.

## What this controls

| Profile | What LOUIE does |
|---------|-----------------|
| `standard` *(default)* | Application development, exactly as without this setting. No game agent, overlay, template, or recipe behavior is active, and no file under `_LOUIE_/profiles/` is read. |
| `game` | Adds the game profile: Kai the Game Designer and Mira the Narrative Designer join the chain, the existing agents load their game overlays, `_LOUIE-output/game-design/` and `_LOUIE-output/story/` hold the game-design and story bible, and `louie-content` handles story, dialogue, and level content. Profile overview: `_LOUIE_/profiles/game/README.md`. |

The setting is **project-wide**, stored in `_LOUIE-output/runbook.md` under the `## Project Profile` section. **A missing section means `standard`** — projects created before this setting existed need no migration.

## Procedure

1. **Read the current setting:**
   - If `_LOUIE-output/runbook.md` does not exist, there is no LOUIE project yet. Tell the user: "No runbook yet — run `louie-setup` (new project) or `louie-import` (existing code) first; both record the profile." Stop.
   - Look for a `## Project Profile` section and parse `Profile:`. If the section is absent, treat the profile as `standard` and tell the user it hasn't been set explicitly yet.

2. **Show the current state and ask what to change:**
   - If the user passed a value with the command (`louie-profile game` / `louie-profile standard`), use it and skip the question.
   - Otherwise present the current state (and when it was set, if recorded), e.g. "Project profile: `standard` (set 2026-10-17)." Then **present the change as a structured choice** — use your runtime's structured-choice tool if it has one, otherwise a lettered list (see `_LOUIE_/guidelines/interaction-guidelines.md`):
     - `standard` — application development (default)
     - `game` — game profile: game-design and narrative agents, game overlays, `louie-content`
     - keep current
   - If the chosen value equals the current one, or the user picks "keep current," don't touch the runbook. For `standard`, print a one-line confirmation and stop. For `game`, still run steps 4–5 as a repair pass (re-sync the installed agents, seed only skeletons that are missing), then confirm. The command is idempotent.

3. **Update the runbook:**
   - Update the `## Project Profile` section of `_LOUIE-output/runbook.md` in place: set `Profile:` to the chosen value and bump `Set:` to today's date. Write the value bare, exactly `**Profile:** game` or `**Profile:** standard` — the init scripts read this line.
   - If the section does not exist yet, create it (place it after `## Language`, before `## Debugging`) using the shape in `_LOUIE_/templates/runbook-template.md`.
   - Do not touch any other part of the runbook.

4. **Sync the installed agents (Claude Code only):**
   - If the project has a `.claude/` directory, re-run the Claude Code init script: `bash _LOUIE_/setup/claude-init.sh` (Windows: `_LOUIE_\setup\claude-init.bat`). It reads the profile from the runbook and makes `.claude/agents/` match it: on `game` it installs the game-profile agents, on `standard` it removes them. It is idempotent and leaves the LOUIE section of `CLAUDE.md` alone. Report only its agent line to the user; ignore its generic next-step hints.
   - Other runtimes (Cursor, Codex, Gemini, opencode, pi) read agent files on demand and need no install step.

5. **On a switch to `game` — seed the game artifacts:**
   - Copy each skeleton below from `_LOUIE_/profiles/game/templates/` into `_LOUIE-output/` **only if the target file does not exist yet**. Never overwrite — an earlier `game` period may have left real content behind. Set each copied file's `Last Updated` line to today.

     | Template (in `_LOUIE_/profiles/game/templates/`) | Target |
     |------------------------------------------------|--------|
     | `game-design-overview-template.md` | `_LOUIE-output/game-design/overview.md` |
     | `gdd-template.md` | `_LOUIE-output/game-design/gdd.md` |
     | `balancing-template.md` | `_LOUIE-output/game-design/balancing.md` |
     | `story-overview-template.md` | `_LOUIE-output/story/overview.md` |
     | `story-bible-template.md` | `_LOUIE-output/story/story-bible.md` |
     | `relationships-template.md` | `_LOUIE-output/story/relationships.md` |
     | `flags-template.md` | `_LOUIE-output/story/flags.md` |

   - Create the empty folders `_LOUIE-output/game-design/systems/`, `_LOUIE-output/game-design/levels/`, `_LOUIE-output/story/characters/`, and `_LOUIE-output/story/chapters/`, each with a `.gitkeep`, if they don't exist.
   - Tell the user which files were seeded and which already existed and were kept.

6. **On a switch to `standard` — keep everything:**
   - **Never delete artifacts.** `_LOUIE-output/game-design/`, `_LOUIE-output/story/`, per-feature `mechanics.md` files, and content files stay where they are. In a `standard` project nothing reads them; switching back to `game` picks them up again.
   - Only the installed agents change (step 4).

7. **Confirm the change:**
   - Print a one-line confirmation, e.g. `Project profile set to: game.`
   - On a switch to `game` in a project whose `_LOUIE-output/architecture.md` already exists: add one line that the architecture has no game sections yet (engine and scene structure, content pipeline, save format) and that Sophie proposes them, with her overlay, the next time she evaluates a feature (`louie-feature` / `louie-extend`). `louie-content` refuses to write content files until `architecture.md` declares the content paths.

## Usage

```
louie-profile
```

```
louie-profile game
louie-profile standard
```

## Related

- `_LOUIE_/templates/runbook-template.md` — the `## Project Profile` section
- `_LOUIE_/setup/claude-init.sh/.bat` — installs or removes the game-profile agents to match the runbook
- `_LOUIE_/profiles/game/README.md` — what the game profile adds
- `_LOUIE_/commands/louie-setup.md` / `_LOUIE_/commands/louie-import.md` — record the profile at project bootstrap
