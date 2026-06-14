# louie-import

When the user says **`louie-import`**, follow this procedure to retrofit LOUIE onto a project that already has source code (and optionally v1-style docs).

The command produces the same artifacts as `louie-setup` plus several rounds of `louie-feature`, in the per-feature folder layout:

- `_LOUIE-output/architecture.md`
- `_LOUIE-output/tech-stack.md`
- `_LOUIE-output/runbook.md`
- `_LOUIE-output/implementations/overview.md` — slim index
- `_LOUIE-output/implementations/<feature>/feature.md` — per discovered feature, status: Implemented
- `_LOUIE-output/implementations/<feature>/requirements.md` — per discovered feature
- `_LOUIE-output/implementations/<feature>/decisions.md` — only if decisions were captured during import
- `_LOUIE-output/implementations/<feature>/bugfixes/.gitkeep` — folder created empty
- `_LOUIE-output/bugfixes/overview.md` — empty cross-cutting index, ready for future fixes

After it completes, the project is indistinguishable from one that went through `louie-setup` plus several rounds of `louie-feature`.

## Procedure

1. **Read framework context:**
   - Read `README.md` (project root) for an overview of LOUIE
   - Read `_LOUIE_/workflow/ai-workflow.md` for the workflow
   - Read `_LOUIE_/workflow/agent-handoffs.md` for handoff protocol
   - Read `_LOUIE_/templates/architecture-template.md`, `tech-stack-template.md`, `runbook-template.md`, `requirements-template.md`, and `feature-template.md` — these are the output formats

2. **Detect import mode:**
   - Look for v1 docs at `docs/implementations/overview.md` plus at least one sibling `*.md` file (excluding `overview.md` itself).
   - If found → mode is **v1-docs**.
   - Otherwise → mode is **cold**.
   - Tell the user what was detected and ask them to confirm or override:
     > "I detected this is a [cold / v1-docs] import. [If v1-docs: I found these feature docs at docs/implementations/: …]. Proceed with this mode, or switch to the other?"
   - Do not proceed without an explicit answer.

3. **Refuse to overwrite without permission:**
   - If `_LOUIE-output/architecture.md`, `tech-stack.md`, `runbook.md`, or any subfolder under `_LOUIE-output/implementations/` already exists with content (not just template placeholders), stop and ask the user before continuing. Show them which files exist and ask whether to overwrite, merge, or abort. Never silently overwrite.
   - Special case: a project on the **old flat layout** (`_LOUIE-output/implementations/<feature>.md` files at top level, or any `_LOUIE-output/requirements/` directory) should **not** be imported — it should be migrated. Tell the user to run `louie-migrate` instead.

4. **Greet the user and explain what's about to happen:**
   - Briefly describe what import does: Sophie will scan the codebase to infer architecture/tech-stack/runbook; Tom will interview to fill gaps; both will discover features and produce per-feature requirements + implementation docs.
   - Mention that no source code will be modified.
   - Mention that the architecture confirmation gate applies at the end.

5. **Invoke Sophie (Architect) — codebase analysis pass:**
   - Read and follow `_LOUIE_/agents/architect.md`.
   - Tell Sophie this is import mode. She is to analyze the codebase directly:
     - Inspect manifest files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `composer.json`, `Gemfile`, `mix.exs`, `setup.py`, `requirements.txt`, etc.) to determine the tech stack.
     - Inspect entry points, top-level module layout, framework signatures, and folder shape to infer the architecture.
     - Inspect manifests, `Dockerfile`, `docker-compose.yml`, `.env.example`, and `README.md` to fill the runbook (start/build/test commands, ports, env vars, external services).
     - Identify candidate **features** from the observable surface: HTTP routes, CLI subcommands, top-level modules, exported public APIs.
   - Sophie produces draft `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`. Anything she could not infer from code goes into the document's Open Questions section — do not invent details.
   - Sophie also produces a **discovered-features list** for the next step.

6. **Branch on import mode:**
   - **Cold mode:** skip to Step 7.
   - **v1-docs mode:** read every file under `docs/implementations/`. Reconcile the v1 feature list against Sophie's discovered-features list. If a feature appears in v1 docs but not in Sophie's list (or vice versa), surface it for the user to confirm. The merged list is what the rest of the procedure uses.

7. **Invoke Tom (Analyst) — gap-filling interview:**
   - Read and follow `_LOUIE_/agents/analyst.md`.
   - Tell Tom this is import mode. He is **not** running a full requirements interview — he is filling gaps Sophie left and capturing context that doesn't live in code:
     - Project goal and target users (the "why")
     - Hard constraints not visible in code (compliance, deadlines, performance targets)
     - Acceptance criteria for each discovered feature
     - Any items Sophie flagged in Open Questions
   - For v1-docs mode, Tom should mine the v1 feature docs first (they often contain goal/overview text) and only ask the user about what is still missing.
   - Tom keeps the interview short. Do not over-ask — most of the requirements information should be derivable from code or v1 docs.

8. **Produce per-feature folders:**
   For each discovered feature `<feature>`:
   - Create the folder `_LOUIE-output/implementations/<feature>/`.
   - Create `<feature>/requirements.md` from `_LOUIE_/templates/requirements-template.md`. Fill in user stories and acceptance criteria from Tom's interview answers (or v1 docs in v1-docs mode). Leave Open Questions populated if specific requirements remain unknown — do not fabricate.
   - Create `<feature>/feature.md` from `_LOUIE_/templates/feature-template.md`:
     - Set status to **Implemented** (trust-as-truth: the running code is the source of authority). Tick Planned, In Development, and Implemented; tick Tested only if test files exist for that feature.
     - Fill Components/Modules, Files, and Key Interfaces/Types from the actual code.
     - In v1-docs mode, carry over content from the matching `docs/implementations/<feature>.md` where it adds detail beyond what code reveals. v1 sections map directly to LOUIE feature sections — the LOUIE template is a strict superset.
     - Fill Change History with one entry: `YYYY-MM-DD: Imported into LOUIE from existing codebase` (or `from v1 docs` for v1-docs mode).
     - Omit the `Handoff to Max (Reviewer)` section — there's nothing to hand off; the code already exists.
   - Create the empty bugfixes folder: `<feature>/bugfixes/.gitkeep`.
   - Skip `<feature>/decisions.md` unless an actual decision was captured during import (e.g., something Sophie surfaced from code that warrants an ADR). Don't create empty placeholders.

9. **Produce overview:**
   - Create or update `_LOUIE-output/implementations/overview.md` from the existing skeleton.
   - Fill Project Context (name, goal, status) from Tom's answers and v1 docs (if any).
   - List every discovered feature in the **Features** table with a one-line description and a link to `implementations/<feature>/feature.md`. Set each row's `Status` to `Tested` if test files exist for that feature, otherwise `Implemented` (trust-as-truth — the running code is the source of authority). Match the `feature.md` checkboxes you ticked in Step 8.

10. **Bootstrap the bugfix index:**
    - Create `_LOUIE-output/bugfixes/overview.md` from `_LOUIE_/templates/bugfixes-overview-template.md` if it doesn't exist. Leave the tables empty — there are no recorded fixes yet (we don't backfill from existing source).

10b. **Ask the user to choose a review mode:**
    - This controls how `louie-review` behaves project-wide on the imported codebase. See `_LOUIE_/commands/louie-review-mode.md` for the full description.
    - Imported projects are higher-risk than greenfield ones (existing code, unknown invariants), so frame the question conservatively. **Present this as a structured choice** — use your runtime's structured-choice tool if it has one, otherwise a lettered list (see `_LOUIE_/guidelines/interaction-guidelines.md`). Question: "How should code reviews behave on this project? On imported projects I recommend `manual` until you've built confidence in the review/fix loop on this codebase." Options:
      - `manual` — Max presents findings and asks before fixing. *(recommended for imports)*
      - `auto-fix-critical` — Max auto-hands Critical + Should-Fix to Nina in a loop
      - `auto-fix-all` — also auto-applies Suggestions
    - Note alongside the choice: changeable anytime with `louie-review-mode`. Default if skipped: `manual`.
    - Wait for the answer. Accept the mode name, the option letter, or "skip" / "default" (→ `manual`).
    - Update `_LOUIE-output/runbook.md` § Review Mode in place: set `Mode:` to the chosen value, `Set:` to today's date, leave `Loop cap:` at `3`.

10c. **Create the roadmap file:**
    - Copy `_LOUIE_/templates/roadmap-template.md` to `_LOUIE-output/roadmap.md` if it doesn't already exist. Set `Last Updated` to today; leave the Captured / Promoted placeholders. Don't backfill — the roadmap is for bigger changes / epics going forward, not a record of already-built features (those live in `implementations/overview.md`).

10d. **Set the auto-pilot mode (no question — default):**
    - Auto-pilot controls how far each command runs unattended after the plan is approved. The default is `off` for every command — do **not** ask at import. Imported projects are higher-risk; leaving auto-pilot off keeps every gate in place until the user opts in.
    - Update `_LOUIE-output/runbook.md` § Auto-Pilot in place: set `feature` / `extend` / `update` / `bugfix` all to `off`, `Set:` to today's date.
    - Note alongside: "Auto-pilot is `off` for all commands. Enable it per command anytime with `louie-autopilot-mode` once you trust the chain on this codebase."

10e. **Set the language (no question — defaults):**
    - Language controls which natural language LOUIE talks in (Conversation) and writes documents in (Documents). The defaults are Conversation `auto` (reply in whatever language the user writes in; ask and remember if ambiguous) and Documents `English` — do **not** ask at import.
    - Update `_LOUIE-output/runbook.md` § Language in place: set `Conversation:` to `auto`, `Documents:` to `English`, `Set:` to today's date.
    - Note alongside: "Language is `auto` for conversation (I'll match the language you write in) and `English` for documents. Change either anytime with `louie-language`."

11. **Confirmation gate (architecture):**
    - Present `architecture.md`, `tech-stack.md`, `runbook.md`, the per-feature folders (with their `feature.md` and `requirements.md`), and the overviews (`implementations/overview.md` + `bugfixes/overview.md`) — **in chat as a normal message** (compact digest per document; file writes alone are not a presentation).
    - Walk the user through Sophie's key inferences and any Open Questions.
    - **End the turn after presenting.** Ask for explicit confirmation only in the next response — a structured-choice dialog hides anything sharing its response. Skip the dialog if the user's reply already decides (two-turn gate — see `_LOUIE_/guidelines/interaction-guidelines.md` § Content first, choice second). Wait for explicit confirmation before declaring the import complete.
    - If the user wants changes, update the documents and re-present.

12. **Wrap up:**
    - Tell the user the import is complete and that they can now run `louie-feature`, `louie-extend`, `louie-bugfix`, etc. as usual.
    - For v1-docs mode, note that the old `docs/` directory is untouched — the user can delete or archive it once they're satisfied.

## Constraints

- **No source code modifications.** Import is a documentation pass.
- **No agent invocations beyond Tom and Sophie.** Leo, Nina, Max, and Ava are not part of import — there is nothing to design, build, review, or test.
- **No fabrication.** Anything not derivable from code or v1 docs and not confirmed by the user belongs in Open Questions.
- **No silent overwrite of existing `_LOUIE-output/` artifacts.** Always ask first.

## Usage

```
louie-import
```

The command auto-detects mode. To force a mode:

```
louie-import cold
louie-import v1-docs
```

If the user already knows what they want (e.g., "import this from the docs/ folder"), they can pass that as free text alongside the command and it should be honored.
