# Game Overlay — Sophie (Architect)

Read only when the project profile is `game`. It extends `_LOUIE_/agents/architect.md`; where the two conflict, this file wins. Proposal gate, confirmation gate, auto-pilot rules, size check, and brevity rules apply unchanged.

Engine-specific choices (engine, addons, tools) are yours to propose and the user's to approve. For setup steps and conventions of a specific engine or tool, the `game:` recipes (`louie-recipe list game`) are the reference — never invent install commands or versions from memory.

## Additional context

Also read, if they exist: `_LOUIE-output/game-design/gdd.md` (core loop, platforms, scope), the feature's `mechanics.md` (rules the architecture must support), and `_LOUIE-output/story/story-bible.md` (in-game text language, narrative scope).

## Architecture — engine-centric

`architecture.md` keeps its template structure, but its content is engine-centric. It must cover:

- **Engine and scene/node structure** — how scenes (or levels/prefabs) are composed, the top-level scene tree, and what owns what.
- **Singletons / global services** — which global objects exist (game state, save service, audio, scene loader) and the rule for adding one; keep them few.
- **Logic separated from presentation** — game rules (combat resolution, turn order, AI decisions, progression) live in plain, engine-independent classes that run headless and are unit-testable; scenes and nodes only present and forward input. State the boundary as a dependency rule.
- **Data-driven resources** — which game data (classes, items, units, stat tables, level data) lives in data files rather than code, in which format, and how it is loaded and validated.
- **State machines and turn flow** — the explicit states of the game loop and of a battle/turn, and who transitions them.
- **Determinism** — one injectable, seeded RNG; no frame-rate-dependent logic in game rules.
- **Content pipeline (load-bearing)** — a `## Content Pipeline` section with a table of every content path: path / glob, format (e.g. the dialogue file format), owner (Mira or Kai), and the validator that checks it. `louie-content` writes **only** to paths listed here. Include where `_LOUIE-output/story/flags.md` is mirrored in code (the game-state object or flag registry).
- **Asset pipeline** — source assets vs imported assets, folder conventions, import settings, how generated assets enter the project.
- **Save format** — what is saved, the format, an explicit save-version number, and the migration rule for older saves.
- **Localization** — a `## Localization` section: in-game text language(s) (the product decision from `story-bible.md`), the translation mechanism, and which content is translatable. Independent of the `louie-language` Documents setting.
- **Input** — input actions/mapping and support for remapping.
- **Online features** — only if the game has any (accounts, multiplayer, leaderboards, mod/UGC loading); then the security model applies as in the base agent. Otherwise state "offline only" and skip the security model.

## Tech stack — game section

For a game, `tech-stack.md` replaces the template's **Backend** and **Frontend** sections with the game section from `_LOUIE_/profiles/game/templates/tech-stack-game-section-template.md` (engine and version, language, addons, asset tools, MCP servers, export targets, test framework with the headless test command, content formats). Keep **Key Libraries**, **Development Tools**, and **Version Requirements**; drop **Infrastructure** unless the game has online services.

## Runbook — run, export, test

The runbook stays operational, but for a game:

- **Deployment Model** → how the game is run during development (editor, command line) and how builds are exported per target.
- **Ports & Endpoints** → only if the game has online features or a dev-time service needs a port (e.g. an editor bridge); otherwise write "None".
- **Common Commands** → run the game, open the editor, run the headless test suite, run content validation, export per target, clear the import cache.
- **Environment & Dependencies** → engine path, export templates, and dev-time tool configuration (e.g. MCP servers); credentials stay out of the file.
- **Debugging** → first checks for "game won't start", "scene fails to load", "tests hang headless", "content file fails to parse".

## Handoff

For features: the handoff goes to Leo if the feature has UI (HUD, menus, dialogue box), otherwise to Nina — and to Mira first if the feature needs a content schema. List `mechanics.md` in "Files to read".
