# Balancing

Last Updated: YYYY-MM-DD

> **Layout:** lives at `_LOUIE-output/game-design/balancing.md`. Kai owns it. **The single home of every formula and number** — mechanics docs, system docs, levels, and code reference entries here by ID. If the game's data files are the runtime source, this file states the design intent and the target bands; keep both in sync via `louie-content`.

## Principles

- [e.g. "a full-HP unit never dies to one unbuffed basic attack on Normal"]

## Formulas

| ID | Name | Formula | Variables | Notes |
|----|------|---------|-----------|-------|
| F-01 | [Hit chance] | [accuracy − avoid, clamped 0–100] | [...] | [...] |

## Random Rolls

| ID | Roll | Distribution | Notes |
|----|------|--------------|-------|
| RNG-01 | [hit roll] | [e.g. average of two d100 rolls] | [from the seeded game RNG] |

## Classes / Units

| ID | Base stats | Growth rates | Caps | Movement | Notes |
|----|------------|--------------|------|----------|-------|
| class:[name] | [...] | [...] | [...] | [...] | [...] |

## Items / Weapons

| ID | Type | Might | Hit | Crit | Weight | Range | Uses | Notes |
|----|------|-------|-----|------|--------|-------|------|-------|
| item:[name] | [...] | | | | | | | |

## Terrain

| ID | Move cost | Avoid | Defense | Heal | Notes |
|----|-----------|-------|---------|------|-------|
| terrain:[name] | [...] | | | | |

## Difficulty Modes

| Mode | Modifiers |
|------|-----------|
| [Normal] | [...] |

## Progression Curve

| Chapter | Expected player level | Expected enemy level | Notes |
|---------|-----------------------|----------------------|-------|
| [1] | [...] | [...] | |

## Target Bands

[What the balancing simulations check. Mark a band `advisory` if a miss should be reported but not fail tests.]

| ID | Metric | Target | Advisory? |
|----|--------|--------|-----------|
| B-01 | [player win rate, chapter 1, Normal, recommended party] | [≥ 90%] | no |

## Change Log

- YYYY-MM-DD: [what changed and why]
