# System: [Name]

Last Updated: YYYY-MM-DD

> **Layout:** lives at `_LOUIE-output/game-design/systems/<system>.md`. Kai owns it. Describes one gameplay system as the player experiences it and as the rules define it. Numbers are referenced by `balancing.md` ID, never restated. Features that implement or change the system link here from their `mechanics.md`.

## Purpose

[Why this system exists — which pillar it serves.]

## Player-Facing Rules

[How a player would explain it to a friend. 3–6 bullets.]

## Rules

[Precise rules, numbered so mechanics docs and tests can cite them: R1, R2, ...]

- **R1:** [...]

## Formulas

| ID | Used for | Defined in |
|----|----------|------------|
| [F-01] | [hit chance] | `balancing.md` |

## States & Transitions

[States this system can be in and what moves it between them. A small table or mermaid state diagram.]

## Edge Cases

- [ties, zero/negative values, simultaneous triggers, unit dies mid-action, softlocks]

## Interactions

- **[Other system]:** [how they affect each other]

## Data

[Which data files/resources this system reads — format and location per `architecture.md` § Content Pipeline.]

## Flags

[Flags read/written — all registered in `story/flags.md`.]

## Tuning Knobs

[Values a designer is expected to tune, with their `balancing.md` IDs.]

## Test Oracles

| Case | Input | Expected |
|------|-------|----------|
| [...] | [...] | [...] |

## Open Questions

- [...]
