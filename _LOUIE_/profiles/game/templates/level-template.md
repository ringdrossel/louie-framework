# Level: [Map Name]

Last Updated: YYYY-MM-DD

> **Layout:** lives at `_LOUIE-output/game-design/levels/<map>.md`. Kai owns it; produced via `louie-content`. Units, classes, and items reference `balancing.md`; story beats reference the chapter doc in `_LOUIE-output/story/chapters/`.

## Metadata

- **Chapter:** [nn-slug] (`story/chapters/<nn>-<slug>.md`)
- **Status:** Planned / Outlined / Drafted / Checked / Final
- **Size:** [w × h tiles]
- **Objective:** [rout / seize / defend N turns / escape / survive]
- **Turn limit / par turns:** [...]
- **Intended difficulty:** [relative to the progression curve in `balancing.md`]
- **Data file:** [path in a declared content path, or "not yet"]

## Layout Sketch

```
[ASCII grid or short description; legend below]
```

**Terrain legend:** [symbol → terrain type, as defined in `balancing.md`]

## Player Deployment

- [slots, forced units, recommended units]

## Enemy Roster

| Unit | Class | Level | Items | AI behavior | Position |
|------|-------|-------|-------|-------------|----------|
| [...] | [`class:...`] | [...] | [...] | [aggressive / hold / guard tile / boss] | [x,y] |

## Events & Reinforcements

| Trigger | Effect | Flags read/set |
|---------|--------|----------------|
| [turn 3 / unit reaches tile / boss HP < 50%] | [reinforcements / dialogue / terrain change] | [...] |

## Win / Lose Conditions

- **Win:** [...]
- **Lose:** [...]

## Story Beats

- [which scenes of the chapter play before, during, and after the battle]

## Rewards

- [items, recruits, unlocks — with flags]

## Playtest Notes

- [observed difficulty, par turns achieved, issues]
