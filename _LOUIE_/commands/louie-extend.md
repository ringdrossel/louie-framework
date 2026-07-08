# louie-extend

When the user says **`louie-extend`**, follow this procedure to extend an existing feature.

> **Reset context before you start.** Ignore any framing from prior work in this session (bugfix mode, update mode, etc.). You are extending a feature. Verify the target against the steps below — don't trust your prior mental model of what the target is.

> **Auto-pilot:** before Step 6, resolve whether this run is unattended (see `## Auto-Pilot` at the bottom). It moves the approval gate to Tom's playback and lets Steps 7–10 run without stopping. The Procedure below is the **step-by-step (manual)** flow.

> **Agentic:** invoked with `--agentic` (an autonomous agent is driving, no human can answer prompts)? Read `_LOUIE_/workflow/agentic-mode.md` first and see `## Agentic` at the bottom.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`
   - Read `_LOUIE-output/implementations/overview.md` to see existing features

2. **Identify the feature to extend:**
   - If the user specified which feature alongside the command, find its folder at `_LOUIE-output/implementations/[feature-name]/`
   - If not, show the list of existing features from `overview.md` and ask: "Which feature would you like to extend?"

3. **Precondition check — is this actually a feature?**
   - The target **must** be a feature folder containing `feature.md` at `_LOUIE-output/implementations/[feature-name]/feature.md`
   - If `feature.md` does not exist for the named target, STOP and do not improvise. Check what the name actually matches:
     - **Matches only a bugfix doc** (e.g. `_LOUIE-output/bugfixes/<date>-<name>.md` or `implementations/<other>/bugfixes/<date>-<name>.md`): tell the user **"Bugfixes are not extended."** Then offer three options:
       1. If this is new functionality → run `louie-feature` to create a proper feature
       2. If this restores intended behavior of an existing feature → run `louie-bugfix` against that feature
       3. If a real feature underlies the work but lacks a folder → run `louie-feature` first to give it one, then come back to `louie-extend` against it
     - **Matches nothing** (typo or genuinely missing): show the feature list from `overview.md` and ask the user to pick one
     - **Ambiguous** (multiple plausible matches): list them and ask the user to disambiguate
   - Do **not** create a feature folder on the fly inside `louie-extend`. Feature folders are owned by `louie-feature`.

4. **Read the existing feature folder:**
   - Read `_LOUIE-output/implementations/[feature-name]/feature.md` completely
   - Read `_LOUIE-output/implementations/[feature-name]/requirements.md` if it exists
   - Skim `_LOUIE-output/implementations/[feature-name]/decisions.md` and `bugfixes/` for context (prior ADRs, recent bug history)

5. **Ask what the extension should do:**
   - If the user already described the extension, proceed
   - If not, ask: "What would you like to add or change in this feature?"

6. **Invoke Tom (Analyst) — Light Mode recommended:**
   - Read and follow `_LOUIE_/agents/analyst.md`
   - Tom interviews about the extension (Light Mode is usually sufficient for extensions)
   - Tom appends an "Extension: <date>" section to `_LOUIE-output/implementations/[feature-name]/requirements.md` rather than creating a new file. This keeps all requirements for one feature in one document.

7. **Invoke Sophie (Architect) — evaluation:**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie evaluates if the extension fits the existing architecture
   - If changes are needed, get user confirmation before updating docs

8. **Update the feature document:**
   - Add a new implementation phase to `_LOUIE-output/implementations/[feature-name]/feature.md`, annotated with `[Depends: … | Files: …]` (see `_LOUIE_/templates/feature-template.md` § Implementation Plan; an extension phase typically depends on the existing phases it builds on). **On a legacy plan without annotations, annotate only the phase you're adding — never rewrite the existing phases** (completed work is never retro-annotated; unannotated phases stay valid and run in written order).
   - Add a Change History entry
   - If a new ADR was made for the extension, append it to `_LOUIE-output/implementations/[feature-name]/decisions.md` (create from template if absent)
   - Update the feature's `Status` column in `_LOUIE-output/implementations/overview.md` if the status changed (mirror the `feature.md` checkboxes)

9. **Confirmation gate:**
   - Present the updated feature document and extension plan **in chat as a normal message** (compact digest + pointer to the file) — the file write alone is not a presentation
   - **End the turn after presenting.** Ask for explicit confirmation only in the next response — a structured-choice dialog hides anything sharing its response. Skip the dialog if the user's reply already decides (two-turn gate — see `_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second). Wait before coding.
   - **Under auto-pilot this gate is already satisfied** at the plan-agreement gate (see `## Auto-Pilot`): the user approved the extension at Tom's playback (Step 6). Narrate that the plan was written and continue.

10. **Continue the chain:**
   - Leo (Designer) if the extension has UI changes
   - Nina (Coder) implements (on a capable runtime under auto-pilot, independent work packages may run concurrently — see `_LOUIE_/guidelines/execution-guidelines.md` § Within-feature parallel runs)
   - Max (Reviewer) reviews
   - Ava (Tester) tests

## Auto-Pilot

Auto-pilot lets the extension chain run unattended after the user approves the plan, stopping only at a final pre-merge summary. See `_LOUIE_/commands/louie-autopilot-mode.md`.

**Resolve the mode** (order): `--auto`/`--manual` flag > `runbook.md` `## Auto-Pilot` `extend:` value (default `off`) > inline choice at the gate.

**Plan-agreement gate** — sits at **Tom's playback in Step 6** (the moment the user confirms the extension scope, before Step 8 writes the new phase into `feature.md`):
- *Off (default):* after Tom's playback is confirmed, present a structured choice in its own response — **Continue step-by-step** / **Auto-pilot the rest**. On auto-pilot, engage the unattended run.
- *On:* the confirmed playback proceeds straight into the unattended run — no second confirmation.

**Unattended run** (Steps 7–10): Sophie auto-applies minimal changes + narrates (pauses on material arch change); the feature-doc update + Step 9 gate are pre-approved (narrate, don't re-ask); Leo auto-applies the recommended UI direction + narrates (pauses on a fundamentally different UX); Nina implements; Max runs the `auto-fix-critical` loop; Ava tests. Each agent narrates as it goes.

**Hard stops that survive auto-pilot:** the **deviation tripwire** (pause if the write-up / Sophie's eval materially diverges from what was agreed — non-trivial arch change, undiscussed scope) and the **merge-to-main gate** (always stop before merge with a final summary; never auto-merge, never auto-branch). See `_LOUIE-internals/autopilot.md` for the full model.

## Agentic

When invoked with `--agentic`, an autonomous agent is driving. Full contract: `_LOUIE_/workflow/agentic-mode.md`. On top of the Auto-Pilot unattended run:

- **Auto-pilot is implied `on`** (per-run; ignore the runbook setting, never offer the inline choice; `--agentic --manual` is a contradiction — stop).
- **The target feature must resolve without a prompt.** If the invocation doesn't name an existing feature folder unambiguously (Step 2/3), write a run report with `status: needs-human` naming the candidates and stop — never guess the target and never create a folder.
- **Tom runs the evidential gate** against the task input instead of the extension interview (see `analyst.md` § Agentic): low-stakes gaps → documented assumptions appended with the "Extension: <date>" section; scope-defining gaps → `status: needs-human`.
- **The deviation tripwire halts instead of pausing to ask** — fork into the run report, work stays resumable via `louie-continue`.
- **The terminal summary becomes a run report** at `_LOUIE-output/implementations/<feature>/run-report.md` with `status: completed`. Merge stays the human's decision.

## Usage

```
louie-extend
```

or unattended after the plan is agreed:

```
louie-extend --auto user-authentication
```

or with context upfront:

```
louie-extend user-authentication
Add OAuth2 support for Google and GitHub login alongside the existing
email/password authentication.
```
