# Game Overlay — Max (Reviewer)

Read only when the project profile is `game`. It extends `_LOUIE_/agents/reviewer.md`; where the two conflict, this file wins. Output format, tiers, storage convention, auto-fix loop, cap, regression guard, and handoff apply unchanged.

## Context additions

Also read the feature's `mechanics.md` if it exists, the `balancing.md` entries it references, and `_LOUIE-output/story/flags.md`.

## Checklist changes

- **§ 4 API & Contract Consistency → Data & Contract Consistency:** code matches `mechanics.md` (rules, edge cases) and reads tuning values from data, not literals; every flag read or written exists in `flags.md` with the right type; content consumed matches the content schema; any change to saved state bumps the save version and handles older saves.
- **§ 5 Security → only if the game has online features** (accounts, multiplayer, leaderboards, loading mods/UGC or other untrusted data). Then the base security checks apply to those surfaces. An offline game skips the web security checks.
- **New § Engine Anti-Patterns** (Critical when on a hot path, else Should Fix):
  - allocations in per-frame callbacks (new objects, string building, collection copies on hot paths)
  - node/object lifetime: objects never freed, references kept to freed objects, scenes instanced but never removed
  - signal/listener leaks: connections never disconnected, duplicate connections on re-entry
  - polling where an event/signal exists
  - game logic inside presentation (UI or scene scripts deciding rules)
  - deep scene-tree lookups by path in hot code
- **New § Determinism** (Critical for game rules): unseeded or global random calls in game logic; frame-rate- or delta-dependent rule outcomes; iteration over unordered collections where order affects the result; wall-clock time in rule code.
- **§ 6 Testing Readiness:** game rules run headless without the scene tree; the RNG is injectable.

## Slim Mode

The security baseline becomes: no secrets in the diff, no unseeded randomness or per-frame allocation introduced, flags used exist in `flags.md`. File size and diff-vs-intent are unchanged.

## Evaluate mode

Add **Engine anti-patterns** and **Determinism** as categories alongside the standard ones (findings go to `findings.md`; split into their own file only past ~30 findings, per `louie-evaluate`'s per-category rule).
