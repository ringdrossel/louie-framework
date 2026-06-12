# louie-autopilot-mode

When the user says **`louie-autopilot-mode`**, view or change the project-wide auto-pilot setting that controls how far each command runs unattended after the user approves the plan.

## What this controls

Auto-pilot lets a command run the rest of its agent chain **without stopping at the in-flight gates** once the user has approved the plan — up to a final pre-merge summary. It is set **per command** (`feature` / `extend` / `update` / `bugfix`), each independently `on` or `off`.

| Value | Behavior |
|-------|----------|
| `off` | **Default.** Every gate stops for the user as usual. On `louie-feature` / `louie-extend`, the plan-agreement gate offers an inline "auto-pilot the rest" choice for that one run. |
| `on` | After the user approves the plan (at the moment of agreement with Tom, before `feature.md` is written), the chain runs unattended: Sophie → Leo → Nina → Max → Ava. Sophie's minimal arch changes and Leo's UI direction auto-apply and are narrated in chat. Max runs the `auto-fix-critical` loop. It **always stops before merge** and presents a final summary, **never auto-creates a branch**, and **pauses anyway** if the written plan materially diverges from what was agreed (the deviation tripwire). |

**Leverage differs by command.** `feature` and `extend` get the full effect (they have Tom/Sophie/Leo gates to suppress). `update` and `bugfix` are thin — they have no pre-code gates, so auto-pilot there just lets Max's review loop run unattended (largely the same as setting review mode to `auto-fix-critical`). The toggles exist for all four for a uniform mental model.

**Interaction with other modes:**
- **Review mode** — when auto-pilot is on, the Max stage runs at an effective floor of `auto-fix-critical` for that run (a project already on `auto-fix-all` keeps it). This does not change the stored `## Review Mode`.
- **Branch mode** — auto-pilot never auto-creates a branch. If branch mode is `ask`, the branch question is resolved at the plan-agreement gate, so there is no mid-run prompt.

The setting is **project-wide**, stored in `_LOUIE-output/runbook.md` under the `## Auto-Pilot` section.

## Procedure

1. **Read the current settings:**
   - Read `_LOUIE-output/runbook.md`.
   - Look for a `## Auto-Pilot` section. If present, parse the per-command values (`feature` / `extend` / `update` / `bugfix`).
   - If absent or unset, treat every command as `off` (the default) and tell the user it has not been set yet.

2. **Show the current state and ask what to change:**
   - Present the current per-command state, e.g. "Auto-pilot: feature `on`, extend `off`, update `off`, bugfix `off` (set 2026-06-10)."
   - **Present the change as a structured choice** — use your runtime's structured-choice tool if it has one, otherwise a lettered list (see `_LOUIE_/guidelines/interaction-guidelines.md`). First ask **which command(s)** to change (multi-select where supported): `feature` / `extend` / `update` / `bugfix` / keep all current.
   - Then, for the chosen command(s), ask the value: `on` or `off`. If several commands are being changed at once and the user wants the same value for all, accept that in one answer.

3. **Update the runbook:**
   - Update the `## Auto-Pilot` section of `_LOUIE-output/runbook.md` in place: set each changed command's value, bump the `Set:` date to today.
   - If the section does not exist yet, create it (place it after `## Branch Mode`, before `## Debugging`).
   - Do not touch any other part of the runbook.
   - If the user picks "keep all current," do nothing — print a one-line confirmation and exit.

4. **Confirm the change:**
   - Print a one-line confirmation, e.g. `Auto-pilot set to: feature on, extend off, update off, bugfix off.`
   - If the user turned any command **on**, add a one-line note: they can override per-call with `louie-<command> --manual` (or `--auto`) for one-off runs, and that auto-pilot still stops before merge and pauses if the plan diverges from what was agreed.

## Usage

```
louie-autopilot-mode
```

No arguments — this command is always interactive. For one-time overrides during a single run, use the flag on the command itself: `louie-feature --auto`, `louie-extend --manual`, etc. The flag does not change the stored setting.

## Related

- `_LOUIE_/commands/louie-feature.md` / `louie-extend.md` — read the setting, accept `--auto`/`--manual`, move the gate to the moment of agreement
- `_LOUIE_/commands/louie-update.md` / `louie-bugfix.md` — thin auto-pilot (review loop runs unattended)
- `_LOUIE_/commands/louie-review-mode.md` — review mode; auto-pilot implies an `auto-fix-critical` floor
- `_LOUIE_/commands/louie-branch-mode.md` — branch mode; auto-pilot never auto-branches
- `_LOUIE_/agents/analyst.md` — Tom's plan-agreement gate
- `_LOUIE_/templates/runbook-template.md` — the `## Auto-Pilot` section
- `_LOUIE-internals/autopilot.md` — design rationale (framework-dev only)
