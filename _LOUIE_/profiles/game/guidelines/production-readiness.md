# Production Readiness — Game Profile

Read only when the project profile is `game`. It replaces the **Web** section of `_LOUIE_/guidelines/production-readiness.md`. The **Core** section there still applies unchanged: bounded/unbounded classification, no unbounded reads, and seed data with volume. Engine specifics live in `_LOUIE_/recipes/game/`. These rules stay engine-agnostic.

## Data

- Save data, logs, replays, inventories, codex/journal entries and leaderboards get the same bounded/unbounded classification. An inventory capped by the rules is bounded. A battle log or a leaderboard is not.
- Unbounded game data is never loaded or rendered in full. Page or window leaderboards and logs, and trim or rotate logs and replays to a stated cap.
- Saves stay small and versioned. Never serialize derived or cached state.

## Frame budget

- Every scene has a frame budget: **16.6 ms at 60 fps** (33.3 ms at 30 fps), unless `tech-stack.md` sets another target.
- **No allocations in the per-frame / update loop.** That means no new objects, strings or closures per frame, and no per-frame lookups by name or path. Cache references once.
- **Pool frequently spawned objects** (projectiles, particles, damage numbers, enemies). Spawning more than a few per second counts as frequent.
- **Asset strategy:** preload what a scene needs before it starts, and unload what it no longer needs. Never load synchronously on the main thread mid-gameplay.

## UI text

- Every UI text element fits the **longest plausible string in every supported language**. Plan for ~30–40% expansion over English, plus the longest name a player can enter.
- Every text field has an explicit rule (wrap, shrink to a minimum size, scroll, or truncate), the same as Content robustness in the base file.
- Test UI at the smallest and largest supported resolution and aspect ratio (see `tech-stack.md`).
