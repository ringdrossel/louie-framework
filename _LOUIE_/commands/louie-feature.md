# louie-feature

When the user says **`louie-feature`**, follow this procedure to add a new feature to the project.

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
   - **Shortcut:** if a `requirements.md` for this feature already exists (typically because `louie-setup` captured it in the initial split), skip Tom entirely. Re-read it, confirm with the user that it's still accurate, and go to Step 5.
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
   - Update `_LOUIE-output/implementations/overview.md` with the new feature entry — Document column links to `implementations/[feature-name]/feature.md`
   - **If this run was seeded `--from-roadmap <id>`:** move the entry from `## Captured` to `## Promoted` in `_LOUIE-output/roadmap.md`. Preserve the original `Created` and `Notes`. Add `Promoted: YYYY-MM-DD → _LOUIE-output/implementations/[feature-name]/`. If the `## Promoted` section is showing the placeholder `_No ideas promoted yet._`, remove that line first. Update the `Last Updated:` line at the top of the roadmap file.

7. **Confirmation gate:**
   - Show the user the feature document and implementation plan
   - Wait for explicit confirmation before coding

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
    - Read and follow `_LOUIE_/agents/coder.md`
    - Nina implements the feature and updates the feature document

11. **Invoke Max (Reviewer):**
    - Read and follow `_LOUIE_/agents/reviewer.md`
    - If changes are needed, Nina fixes them before proceeding

12. **Invoke Ava (Tester):**
    - Read and follow `_LOUIE_/agents/tester.md`
    - Ava writes tests and gives a ship recommendation

## Usage

```
louie-feature
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
