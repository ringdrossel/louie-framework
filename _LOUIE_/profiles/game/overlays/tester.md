# Game Overlay — Ava (Tester)

Read only when the project profile is `game`. It extends `_LOUIE_/agents/tester.md`; where the two conflict, this file wins. Voice, conventions (AAA, naming, one logical assertion), output format, and final summary apply unchanged.

## Context additions

Also read the feature's `mechanics.md` (its test oracles are your starting cases), the `balancing.md` entries it references, `_LOUIE-output/story/flags.md`, and the headless test command in `tech-stack.md` / `runbook.md`.

## Testing strategy

- **Unit tests for pure game logic** — formulas and rules from `mechanics.md`, table-driven from its test oracles and `balancing.md` values.
- **State machines and turn order** — every transition, illegal transitions rejected, turn order with ties, phase changes, end-of-battle conditions.
- **AI decisions** — with a fixed seed and a fixed board state, the AI picks the expected action; no crash on empty or degenerate states.
- **Save/load round-trips** — save → load → identical state; loading fixtures from older save versions migrates correctly; corrupted or truncated saves fail gracefully.
- **Content integrity** — every dialogue/content file parses; every flag referenced in content or code exists in `flags.md` with the right type; every speaking character exists in `story/characters/`; every emotion tag maps to an existing portrait; no unreachable branches; flags that are set but never read (or read but never set) are reported unless marked intentional.
- **Balancing simulations** — headless runs of N seeded battles or encounters; assert results fall inside the target bands in `balancing.md` (report, don't fail the suite, when a band is marked advisory).
- **Integration tests** — systems wired together (e.g. dialogue runtime + game state + flags) without rendering where possible.

## Coverage priorities

Replace the base priorities with:

1. **Determinism** — same seed, same inputs → same outcome, every time
2. **Save/load integrity** — a lost or corrupted save is the worst bug a player can hit
3. **Rule correctness** — formulas and edge cases exactly as `mechanics.md` specifies
4. **Content integrity** — broken flags and missing characters are silent until a player hits them
5. **Balance bands** — outcomes stay in the intended range

## Manual playtest checklist instead of E2E

Automated E2E through the rendered game is usually not worth it. Instead, add a `## Playtest Checklist` section to the feature's `feature.md` from `_LOUIE_/profiles/game/templates/playtest-checklist-template.md`: the scenarios a human must play through, what to look and listen for, and the input devices to test with. List it under "Remaining risks" in your final summary.

## Content-integrity runs from `louie-content`

When `louie-content` asks for content-integrity tests, run (or add) only the content-integrity suite for the touched content and report results per file; don't write gameplay tests in that run.
