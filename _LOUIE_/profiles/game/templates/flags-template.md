# Flags

Last Updated: YYYY-MM-DD

> **Layout:** lives at `_LOUIE-output/story/flags.md`. **The single registry of every story and dialogue flag — the contract between story and code.** Mira maintains it; Kai and Nina add entries through her or with her review. A flag used in a dialogue file or in code that isn't registered here is a bug; Ava's content-integrity tests check this file against both.

## Rules

- **Register first.** A flag is added here before any content or code uses it.
- **Naming:** lowercase snake_case, prefixed by scope — `chNN_` (chapter), `char_<name>_` (character), `sup_<a>_<b>_` (support), `game_` (global).
- **Types:** `bool`, `int`, `enum(<values>)`, `string` — no untyped flags.
- **Default:** every flag has one; a new game starts with all defaults.
- **Set by / read by:** name the content file, scene ID, or code module. A flag set but never read (or read but never set) is reported unless marked `intentional`.
- **Never delete** a flag that may exist in player saves — move it to `## Retired` with the date.

## Registry

| Flag | Type | Default | Set by | Read by | Description |
|------|------|---------|--------|---------|-------------|
| — | — | — | — | — | No flags yet |

## Retired

| Flag | Retired | Reason |
|------|---------|--------|
| — | — | — |
