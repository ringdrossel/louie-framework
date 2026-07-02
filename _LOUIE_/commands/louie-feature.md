# louie-feature

When the user says **`louie-feature`**, follow this procedure to add a new feature to the project.

> **Auto-pilot:** before Step 4, resolve whether this run is unattended (see `## Auto-Pilot` at the bottom). It changes where the approval gate sits and whether Steps 5–12 stop for the user. The Procedure below is the **step-by-step (manual)** flow; the Auto-Pilot section describes how it reshapes.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`
   - Read `_LOUIE-output/implementations/overview.md` if it exists
   - Read `_LOUIE_/workflow/ai-workflow.md` for the workflow

2. **Check prerequisites:**
   - If `_LOUIE-output/architecture.md` does not exist, tell the user: "No architecture defined yet. Run `louie-setup` first to set up the project foundation, or `louie-import` if this is an existing project with source code already in place."
   - Do not proceed without architecture and tech stack in place.
   - If `_LOUIE-output/runbook.md` is missing on a project that has architecture (legacy LOUIE project), suggest the user generate it via Sophie before proceeding — or proceed and ask Sophie to bootstrap one based on the existing architecture.

3. **Resolve the feature seed:**
   - If invoked with `--from-roadmap <id>` (or via `louie-roadmap promote <id>`): read `_LOUIE-output/roadmap.md`, locate the entry under `## Captured`, and use its Notes (plus Title) as the seed for Tom. If the ID doesn't exist or is already under `## Promoted`, stop and tell the user. Skip the "what feature?" question — the entry *is* the description.
   - Otherwise, if the user already provided a description alongside the command, proceed directly.
   - Otherwise, if `_LOUIE-output/roadmap.md` exists and has Captured entries, offer them: "There are N captured ideas in the roadmap — want to promote one? Run `louie-roadmap promote <id>`. Otherwise, what feature would you like to add?"
   - Otherwise, ask: "What feature would you like to add? A brief description is fine — Tom will dig into the details."

4. **Invoke Tom (Analyst):**
   - **Shortcut:** if a `requirements.md` for this feature already exists (typically because `louie-setup` captured it in the initial split), skip Tom entirely. Re-read it and confirm with the user that it's still accurate — this is a content-carrying gate: first present a compact digest of the requirements **in chat as a normal message** and end the turn; ask for confirmation only in the next response, skipping the dialog if the user's reply already decides (two-turn gate — see `_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second). Never ask "still accurate?" about a document the user hasn't just seen. Then go to Step 5.
   - Otherwise: read and follow `_LOUIE_/agents/analyst.md`.
   - Tom interviews the user, then runs the **Scope Split Gate** (analyst.md § Step 4a). If the request actually covers multiple capabilities (e.g. "add login + profile editing + admin panel"), Tom splits it into multiple feature folders, each with its own `requirements.md`. From this command's perspective, the rest of the procedure then runs once **per approved feature** — confirm with the user which one to take through Steps 5–11 first; the others stay as `requirements.md`-only until the user runs `louie-feature` for them.
   - Tom creates each feature folder `_LOUIE-output/implementations/<feature-name>/` and writes its `requirements.md`.

5. **Invoke Sophie (Architect) — evaluation:**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie evaluates whether the new feature fits the existing architecture
   - If yes: Sophie writes a brief handoff note, no document changes needed
   - If no: Sophie proposes minimal updates, gets user confirmation, updates docs

6. **Create feature document:**
   - Create `_LOUIE-output/implementations/[feature-name]/feature.md` using `_LOUIE_/templates/feature-template.md`
   - Fill in all sections based on `[feature-name]/requirements.md` and the architecture
   - **Annotate the Implementation Plan phases** with `[Depends: none|<phase-nrs> | Files: <globs>]` (template § Implementation Plan has the rules). Derive the `Files:` write scopes from the architecture's folder structure; keep the glob lists small. An integration phase that depends on several others is normal — don't contort the plan to avoid it. Nina validates these annotations before implementing.
   - Update `_LOUIE-output/implementations/overview.md` — add the feature to the **Features** table with `Status: Planned`. Document column links to `implementations/[feature-name]/feature.md`. (Tom may already have added it during setup; if so, leave it as `Planned`.)
   - **If this run was seeded `--from-roadmap <id>`:** move the entry from `## Captured` to `## Promoted` in `_LOUIE-output/roadmap.md`. Preserve the original `Created` and `Notes`. Set `Status: In Progress` and add `Promoted: YYYY-MM-DD → _LOUIE-output/implementations/[feature-name]/`. If the `## Promoted` section is showing the placeholder `_No ideas promoted yet._`, remove that line first. Update the `Last Updated:` line at the top of the roadmap file. (Equivalent to `louie-roadmap-change <id> status "In Progress"`.)

7. **Confirmation gate:**
   - Present the feature document and implementation plan **in chat as a normal message** — a compact digest (key sections, phases, scope), with a pointer to the full `feature.md`. The file write alone is **not** a presentation; its result renders collapsed.
   - **End the turn after presenting.** Ask for explicit confirmation (short, self-contained question) only in the next response — a structured-choice dialog hides anything sharing its response, even a short summary. Skip the dialog if the user's reply already decides (two-turn gate — see `_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second). Wait before coding.
   - **Under auto-pilot this gate is already satisfied** at the plan-agreement gate (see `## Auto-Pilot`): the user approved the plan at Tom's playback, and `feature.md` is its faithful write-up. Don't re-ask — narrate that the plan was written and continue.

8. **Branch handling (branch mode):**
   - Read the `## Branch Mode` section of `_LOUIE-output/runbook.md`. If absent or unset, treat the mode as `current`.
   - `current` (default): stay on the current branch (including `main`). Do not create a branch and do not prompt.
   - `ask`: ask the user "Create a new `feature/<feature-name>` branch for this feature, or work on the current branch (`<current-branch>`)?" If they choose a branch, create and switch to `feature/<feature-name>`; otherwise continue on the current branch.
   - In **either** mode, if the user already asked for a branch (in their command or earlier in the conversation), create and switch to `feature/<feature-name>` without re-asking.
   - See `_LOUIE_/commands/louie-branch-mode.md` to change the project-wide setting.

9. **Invoke Leo (Designer) — if the feature has UI:**
   - Read and follow `_LOUIE_/agents/designer.md`
   - Leo first presents a lightweight UI proposal and discusses it with the user (Proposal & Discussion Gate, same as Sophie). He only writes the design into `feature.md` after explicit approval.
   - Skip this step for backend-only features

10. **Invoke Nina (Coder):**
    - Set the feature's row in `_LOUIE-output/implementations/overview.md` to `Status: In Development` before coding starts.
    - Read and follow `_LOUIE_/agents/coder.md`
    - Nina implements the feature and updates the feature document (including its `feature.md` Status checkboxes)
    - **On a capable runtime under auto-pilot**, independent work packages (plan phases with met `Depends:` and disjoint `Files:`) may run as concurrent Nina subagents per `_LOUIE_/guidelines/execution-guidelines.md` § Within-feature parallel runs. Manual mode and sequential runtimes: phases run in dependency order, exactly as written.

11. **Invoke Max (Reviewer):**
    - Read and follow `_LOUIE_/agents/reviewer.md`
    - If changes are needed, Nina fixes them before proceeding

12. **Invoke Ava (Tester):**
    - Read and follow `_LOUIE_/agents/tester.md`
    - Ava writes tests and gives a ship recommendation

13. **Sync overview + roadmap status:**
    - **Overview:** set the feature's row in `_LOUIE-output/implementations/overview.md` to `Status: Tested` if Ava wrote tests and they pass, otherwise `Status: Implemented`. This must match the `feature.md` checkboxes Nina/Ava ticked — they are the source of truth; the overview Status mirrors them. Update the `Last Updated:` line.
    - **Roadmap (only if this feature came from a roadmap entry):** if this run was seeded `--from-roadmap <id>`, the epic may now be complete — but an epic can span several features. **Ask, don't assume** — present as a structured choice (structured-choice tool if available, else a lettered list; see `_LOUIE_/guidelines/interaction-guidelines.md`): "This feature is done. Is the roadmap epic `<id>` complete?" Options: "Complete — mark it Done" / "More features to come — keep it In Progress". On "complete," run `louie-roadmap-change <id> status Done`; otherwise leave it `In Progress`. Skip this bullet for features not linked to a roadmap entry.

## Auto-Pilot

Auto-pilot lets the chain run unattended after the user approves the plan, stopping only at a final pre-merge summary. See `_LOUIE_/commands/louie-autopilot-mode.md` and `_LOUIE-internals/autopilot.md`.

**Resolve the mode at the start of the run** (resolution order):
1. **Per-call flag** — `louie-feature --auto` or `louie-feature --manual` wins for this run (doesn't change the stored setting).
2. **Persistent setting** — read `_LOUIE-output/runbook.md` `## Auto-Pilot`, the `feature:` value. If absent/unset, treat as `off`.
3. **Inline at the gate** — if `off` and no flag, the gate below offers the choice for this one run.

**The plan-agreement gate** (this is where the human checkpoint moves to):
- It sits at **Tom's playback confirmation in Step 4** — the moment the user says "looks good" to the agreed scope/approach, *before* `feature.md` is written. By then the plan is a faithful transcription of the discussion, so this is the approval; Step 7's gate is not a second one.
- **Auto-pilot off (default):** after Tom's playback is confirmed, present a structured choice in its own response (two-turn gate — the playback content was the prior turn): **Continue step-by-step** / **Auto-pilot the rest of this feature**. ("Revise" is already handled by Tom's playback loop.) On step-by-step, run the Procedure as written. On auto-pilot, engage the unattended run below for this one feature.
- **Auto-pilot on:** Tom's confirmed playback proceeds straight into the unattended run — no second confirmation (a re-confirm would re-introduce the gate auto-pilot removes).
- **Resolve branching here too:** if branch mode is `ask`, ask the branch question at this gate (alongside the step-by-step/auto-pilot choice, or as part of engaging auto-pilot) so the run has no mid-chain prompt. Auto-pilot never auto-creates a branch.

**The unattended run** (rest of Step 4 through Step 12, when auto-pilot is engaged):
- Tom finishes writing `requirements.md` (end of Step 4, right after the confirmed playback), then `feature.md` is written at Step 6 — both as automated steps, no separate approval. `feature.md` is never skipped — it's the source of truth later commands read.
- Sophie evaluates (Step 5): auto-applies minimal/mechanical changes and narrates; **pauses on a material architecture change** (see `architect.md` § Auto-Pilot).
- Leo (Step 9, if UI): picks and writes the recommended direction, narrates; **pauses on a fundamentally different UX** (see `designer.md` § Auto-Pilot).
- Nina (Step 10) implements — on capable runtimes, independent work packages run concurrently (see `_LOUIE_/guidelines/execution-guidelines.md`; a deviation-tripwire hit in one package pauses that package, siblings finish, no new dispatch until resolved). Max (Step 11) runs the **`auto-fix-critical`** loop (auto-pilot raises the floor — see `reviewer.md`). Ava (Step 12) tests.
- Each agent **narrates its output in chat** as it goes — auto-pilot suppresses *blocking*, not *visibility*.

**Hard stops that survive auto-pilot:**
- **The deviation tripwire** — if writing the plan, Sophie's eval, or the phase breakdown materially diverges from what was agreed (non-trivial arch change, an undiscussed phase, scope clearly larger than the conversation implied, a fundamentally different UX), **pause** and surface the fork (content-first, two-turn gate). It's a judgment call; when unsure, pause.
- **The merge-to-main gate** (Critical Rule #3). Auto-pilot **always stops before merge** with a final summary: what was built, Sophie's decision, Leo's direction (if any), Max's review outcome (rounds + deferred Suggestions), Ava's result + ship recommendation, files changed, and the merge decision left to the user. Never auto-merge.
- Then complete Step 13 (sync overview + roadmap) as usual.

## Usage

```
louie-feature
```

or unattended after the plan is agreed:

```
louie-feature --auto
```

or with a description upfront:

```
louie-feature
Add user authentication with email/password login, session management,
and a password reset flow.
```

or seeded from a roadmap entry:

```
louie-feature --from-roadmap R-007
```
