# louie-import

When the user says **`louie-import`**, follow this procedure to retrofit LOUIE onto a project that already has source code (and optionally v1-style docs).

The command produces the same artifacts as `louie-setup`:

- `_LOUIE-output/architecture.md`
- `_LOUIE-output/tech-stack.md`
- `_LOUIE-output/runbook.md`
- `_LOUIE-output/requirements/<feature>-requirements.md` (one per discovered feature)
- `_LOUIE-output/implementations/<feature>.md` (one per discovered feature, status: Implemented)
- `_LOUIE-output/implementations/overview.md`

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
   - If `_LOUIE-output/architecture.md`, `tech-stack.md`, or `runbook.md` already exist with content (not just template placeholders), stop and ask the user before continuing. Show them which files exist and ask whether to overwrite, merge, or abort. Never silently overwrite.

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

8. **Produce per-feature requirements docs:**
   - For each discovered feature, create `_LOUIE-output/requirements/<feature>-requirements.md` from `_LOUIE_/templates/requirements-template.md`.
   - Fill in user stories and acceptance criteria from Tom's interview answers (or v1 docs in v1-docs mode).
   - If specific requirements remain unknown, leave them in Open Questions — do not fabricate.

9. **Produce per-feature implementation docs:**
   - For each discovered feature, create `_LOUIE-output/implementations/<feature>.md` from `_LOUIE_/templates/feature-template.md`.
   - Set status to **Implemented** (trust-as-truth: the code is running, that is the source of authority). All status checkboxes for Planned, In Development, and Implemented should be checked; Tested only if test files exist for that feature.
   - Fill Components/Modules, Files, and Key Interfaces/Types from the actual code.
   - In v1-docs mode, carry over content from the matching `docs/implementations/<feature>.md` where it adds detail beyond what code reveals. v1 sections map directly to v2 sections — the v2 template is a strict superset.
   - Fill the Change History with a single entry: `YYYY-MM-DD: Imported into LOUIE from existing codebase` (or `from v1 docs` for v1-docs mode).
   - Skip the `Handoff to Max (Reviewer)` section — there's nothing to hand off; the code already exists.

10. **Produce overview:**
    - Create or update `_LOUIE-output/implementations/overview.md` from the existing template.
    - Fill Project Context (name, goal, status) from Tom's answers and v1 docs (if any).
    - List every discovered feature in the **Implemented** table with a link to its implementation doc.

11. **Confirmation gate (architecture):**
    - Present `architecture.md`, `tech-stack.md`, `runbook.md`, the per-feature requirements docs, the per-feature implementation docs, and the overview.
    - Walk the user through Sophie's key inferences and any Open Questions.
    - Wait for explicit confirmation before declaring the import complete.
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
