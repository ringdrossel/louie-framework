# Mechanics: [Feature Name]

Last Updated: YYYY-MM-DD

> **Layout:** lives at `_LOUIE-output/implementations/<feature>/mechanics.md`, next to `requirements.md` and `feature.md` (game profile only). Kai writes it right after Tom, before Sophie. It is the source of truth for this feature's rules: Sophie's evaluation and the feature doc build on it, Nina implements against it, Ava turns its test oracles into tests. Numbers are `balancing.md` IDs, never literals.
>
> **Length budget:** target ~120 lines.

## Summary

[The rule in one paragraph — what the player does and what happens.]

## Systems

- [system doc(s) this feature implements or changes: `game-design/systems/<system>.md`]

## Rules

- **R1:** [...]

## Formulas

| ID | Used for |
|----|----------|
| [F-01] | [...] |

## State Machine

[States, transitions, who triggers them. Table or mermaid state diagram.]

## Edge Cases

- [...]

## Data Needed

[Stat tables, data files, and their fields the implementation must load.]

## Content Schema

[Only if the feature consumes narrative content — written by Mira: content files consumed, fields and format, emotion/portrait tags, where the files live (declared content path).]

## Flags

| Flag | Read / Write | Registered in flags.md |
|------|--------------|------------------------|
| [...] | [...] | yes |

## Test Oracles

| Case | Setup | Action | Expected |
|------|-------|--------|----------|
| [...] | [seed, state] | [...] | [...] |

## Open Questions

- [...]

## Handoff to Sophie (Architect)

- **Key context:** [...]
- **Decisions made:** [...]
- **Flags:** [...]
- **Data needed:** [...]
- **Open items:** [...]
- **Files to read:** [mechanics.md, balancing.md, systems/<system>.md]
