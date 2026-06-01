# louie-branch-mode

When the user says **`louie-branch-mode`**, view or change the project-wide branch mode setting that controls whether `louie-feature` creates a new branch for each feature.

## What this controls

The branch mode determines what `louie-feature` does about version-control branching when a new feature starts. Two modes:

| Mode | Behavior |
|------|----------|
| `current` | **Default.** Work on whatever branch you are already on (including `main`). LOUIE never creates a branch on its own and never prompts. Create a branch yourself, or just ask LOUIE to, whenever you want one. |
| `ask` | At the start of each new feature, LOUIE asks whether to create a feature branch (`feature/<name>`) or stay on the current branch. Nothing is branched silently either way. |

A new branch is **never** created automatically. In either mode, if the user explicitly asks for one ("branch this feature off"), LOUIE creates `feature/<feature-name>` and switches to it.

This setting affects `louie-feature` only. `louie-extend`, `louie-update`, and `louie-bugfix` always run on the current branch.

The setting is **project-wide**, stored in `_LOUIE-output/runbook.md` under the `## Branch Mode` section.

## Procedure

1. **Read the current mode:**
   - Read `_LOUIE-output/runbook.md`.
   - Look for a `## Branch Mode` section. If present, parse the `Mode:` value.
   - If absent or unset, treat the mode as `current` (the default) and tell the user it has not been set explicitly yet.

2. **Show the current state and ask:**
   - Present the current mode (and when it was set, if recorded) in chat. Example:
     > "Current branch mode: `current` (work on the current branch, no prompt). What would you like to change it to?"
   - Offer the two options plus "keep current":
     - `current` — work on the current branch; never auto-branch, never prompt (default)
     - `ask` — ask before each new feature whether to create a branch
     - keep current — no change

3. **Update the runbook:**
   - If the user picks a new mode, update the `## Branch Mode` section of `_LOUIE-output/runbook.md` in place. Bump the `Set:` date to today.
   - If the section does not exist yet, create it (place it after `## Review Mode`, before `## Debugging`).
   - Do not touch any other part of the runbook.
   - If the user picks "keep current," do nothing — print a one-line confirmation and exit.

4. **Confirm the change:**
   - Print a one-line confirmation: `Branch mode set to <mode>.`
   - If the user changed to `ask`, add a one-line note that they can still skip the branch on any given feature, and that they can branch on demand in any mode just by asking.

## Usage

```
louie-branch-mode
```

No arguments — this command is always interactive.

## Related

- `_LOUIE_/commands/louie-feature.md` — reads the mode and branches behavior at feature start
- `_LOUIE_/guidelines/coding-guidelines.md` — Git Discipline (branch naming, merge-to-main gate)
- `_LOUIE_/templates/runbook-template.md` — the `## Branch Mode` section
- `_LOUIE-internals/branch-mode.md` — design rationale (framework-dev only)
