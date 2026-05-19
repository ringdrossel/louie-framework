# louie-review-mode

When the user says **`louie-review-mode`**, view or change the project-wide review mode setting that controls how `louie-review` behaves.

## What this controls

The review mode determines whether `louie-review` stops for human approval after presenting findings, or auto-hands fixes to Nina in a loop. Three modes:

| Mode | Behavior |
|------|----------|
| `manual` | Max presents the verdict and asks before any code changes. Nothing is fixed without explicit user approval. |
| `auto-fix-critical` | Max auto-hands `Critical` + `Should Fix` findings to Nina. Nina applies them, re-runs typecheck / tests / build, and hands back to Max for a re-review. Loop until clean or the loop cap is reached. `Suggestions` are surfaced at the end and still need approval. |
| `auto-fix-all` | Same loop as `auto-fix-critical`, but `Suggestions` are also auto-applied. Heavy-handed — intended for solo or throwaway projects. |

The setting is **project-wide**, stored in `_LOUIE-output/runbook.md` under the `## Review Mode` section.

## Procedure

1. **Read the current mode:**
   - Read `_LOUIE-output/runbook.md`.
   - Look for a `## Review Mode` section. If present, parse the `Mode:` and `Loop cap:` values.
   - If absent or unset, treat the mode as `manual` (the safe default) and tell the user it has not been set yet.

2. **Show the current state and ask:**
   - Present the current mode (and when it was set, if recorded) in chat. Example:
     > "Current review mode: `auto-fix-critical` (set 2026-05-19, loop cap 3). What would you like to change it to?"
   - Offer the three options plus "keep current":
     - `manual` — Max presents findings, asks before fixing
     - `auto-fix-critical` — auto-fix Critical + Should Fix; loop; surface Suggestions
     - `auto-fix-all` — auto-fix everything; loop
     - keep current — no change

3. **Update the runbook:**
   - If the user picks a new mode, update the `## Review Mode` section of `_LOUIE-output/runbook.md` in place. Bump the `Set:` date to today.
   - If the section does not exist yet, create it (place it after `## Common Gotchas`, before `## Debugging`).
   - Do not touch any other part of the runbook.
   - If the user picks "keep current," do nothing — print a one-line confirmation and exit.

4. **Confirm the change:**
   - Print a one-line confirmation: `Review mode set to <mode>. Loop cap: <N>.`
   - If the user changed away from `manual`, add a one-line note that they can override per-call with `louie-review manual` for one-off invocations.

## Loop cap (advanced)

The default loop cap is 3 rounds (review → fix → review × N). To change it, the user can edit the `Loop cap:` value in `_LOUIE-output/runbook.md` directly, or pass it interactively when this command asks for confirmation. Caps below 1 or above 10 are rejected — that range covers every reasonable workflow.

## Usage

```
louie-review-mode
```

No arguments — this command is always interactive. For one-time overrides during a single review, use the override syntax on `louie-review` itself: `louie-review auto`, `louie-review manual`, `louie-review auto-fix-all`.

## Related

- `_LOUIE_/commands/louie-review.md` — reads the mode and branches behavior
- `_LOUIE_/agents/reviewer.md` — Max's loop logic for auto modes
- `_LOUIE_/templates/runbook-template.md` — the `## Review Mode` section
- `_LOUIE-internals/review-mode.md` — design rationale (framework-dev only)
