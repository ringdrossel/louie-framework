# Game Overlay — Nina (Coder)

Read only when the project profile is `game`. It extends `_LOUIE_/agents/coder.md`; where the two conflict, this file wins. Process, plan discipline, validation, docs updates, and handoff apply unchanged.

## Context additions

Also read the feature's `mechanics.md` if it exists, the `balancing.md` entries it references, and `_LOUIE-output/story/flags.md` for any flag the feature reads or writes.

## Rules

- **`mechanics.md` is the source of truth for rules.** Implement rules and edge cases exactly as specified. If a rule is ambiguous, contradictory, or doesn't survive contact with the engine, stop and surface it — changing a rule is Kai's call (and a deviation-tripwire hit under auto-pilot), not an implementation detail.
- **Numbers live in data, not code.** Formulas reference `balancing.md` IDs; stat values come from the data files the architecture declares. No magic numbers for tuning values in scripts.
- **Logic separated from presentation.** Game rules go into plain, engine-independent classes that run headless; scenes/nodes only present state and forward input. This is what makes Ava's tests possible.
- **Determinism.** Use the project's injected, seeded RNG for every random roll; never a global unseeded random call in game logic. Game rules never depend on frame rate or frame timing.
- **Flags only through the registry.** Read and write story flags through the game-state object or flag registry the architecture names, using the names in `flags.md`. A flag that isn't in `flags.md` doesn't get created in code — register it first (via Mira).
- **Content is not yours to write.** Dialogue scripts, support scenes, level and stat data in the declared content paths belong to Mira and Kai (`louie-content`). You may add minimal test fixtures; you build the systems that consume content.
- **Engine hygiene.** No allocations in per-frame callbacks on hot paths; disconnect signals/listeners and free nodes/objects you own; prefer events/signals over polling.
- **Save compatibility.** Any change to saved state bumps the save version and adds a migration (or an explicit, documented break) per the architecture's save-format rule.
- **Size limits apply to scripts and scenes.** The coding guidelines' file and function limits apply to scripts; a scene that grows into one giant tree gets split into sub-scenes like a component gets split.

## Validation

Run the headless test command and content validation from `tech-stack.md` / `runbook.md` in place of web build/lint steps where those don't exist.
