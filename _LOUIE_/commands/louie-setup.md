# louie-setup

When the user says **`louie-setup`**, follow this procedure to initialize the LOUIE workflow for a new project.

## Procedure

1. **Read the framework context:**
   - Read `README.md` (project root) for an overview of LOUIE
   - Read `_LOUIE_/workflow/ai-workflow.md` for the full workflow
   - Read `_LOUIE_/workflow/agent-handoffs.md` for handoff protocol

2. **Greet the user and explain what's about to happen:**
   - Introduce the LOUIE framework briefly
   - Explain that Tom (Analyst) will interview them about their project/feature idea
   - After requirements, Sophie (Architect) will define the architecture and tech stack
   - Both will be shown for confirmation before any code is written

3. **Ask for their idea:**
   - If the user already provided an idea alongside the command, proceed directly
   - If not, ask: "What's the project or feature you'd like to build? A sentence or two is enough — Tom will ask follow-up questions."

4. **Invoke Tom (Analyst):**
   - Read and follow `_LOUIE_/agents/analyst.md`
   - Tom interviews the user, then runs the **Scope Split Gate** (analyst.md § Step 4a). For a project-from-scratch this almost always produces multiple features (e.g. `auth`, `books-core`, `shelf-ui`, `csv-import`, …) — not one giant `mvp` folder.
   - For **each** approved feature, Tom creates `_LOUIE-output/implementations/<feature-name>/` and writes its own `requirements.md` using `_LOUIE_/templates/requirements-template.md`.
   - Tom also updates `_LOUIE-output/implementations/overview.md` with the project context (name, goal, status) and adds **every** new feature to the Planned table in implementation order — Document column links to `implementations/<feature-name>/feature.md`.

5. **Invoke Sophie (Architect):**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie reads **all** of Tom's `requirements.md` files (one per feature folder) and produces a single set of project-wide foundation docs:
     - `_LOUIE-output/architecture.md` — system architecture with mermaid diagram, layers, patterns, folder structure, security model
     - `_LOUIE-output/tech-stack.md` — every technology choice with rationale
     - `_LOUIE-output/runbook.md` — deployment model, ports, common commands, env vars, external services (Common Gotchas starts empty)
   - These three docs cover the **whole project**, not per-feature. Per-feature design lives in each feature folder's `feature.md` (Step 7).
   - Use templates from `_LOUIE_/templates/architecture-template.md`, `_LOUIE_/templates/tech-stack-template.md`, and `_LOUIE_/templates/runbook-template.md`

5b. **Ask the user to choose a review mode:**
   - This controls how `louie-review` behaves project-wide. See `_LOUIE_/commands/louie-review-mode.md` for the full description.
   - Ask the user:
     > "One quick setup question — how should code reviews behave on this project?
     > 1. `manual` — Max presents findings and asks before fixing anything. Safe default.
     > 2. `auto-fix-critical` — Max auto-hands Critical + Should-Fix items to Nina in a loop, surfaces Suggestions at the end for approval. Less friction on trusted projects.
     > 3. `auto-fix-all` — same loop, but Suggestions are also auto-applied. Heavy-handed; solo or throwaway projects only.
     >
     > You can change this anytime with `louie-review-mode`, or override per-call with `louie-review manual` / `louie-review auto`. Default if you skip: `manual`."
   - Wait for the answer. Accept `1`/`2`/`3`, the mode name, or "skip" / "default" (→ `manual`).
   - Update `_LOUIE-output/runbook.md` § Review Mode in place: set `Mode:` to the chosen value, `Set:` to today's date, leave `Loop cap:` at the default `3`.

6. **Confirmation gate (architecture):**
   - Present the requirements, architecture, tech stack, and runbook to the user
   - Walk through the key decisions and their rationale
   - Wait for explicit confirmation before proceeding
   - If the user wants changes, update the documents and re-present

7. **Create feature document for the FIRST feature only:**
   - Tom typically produced multiple feature folders in Step 4. Pick the **first** one in the Planned table (the foundational feature — usually `auth` or whichever has no dependencies) and create just its `feature.md` using `_LOUIE_/templates/feature-template.md`.
   - Fill in all sections based on that feature's `requirements.md` and Sophie's architecture.
   - The remaining feature folders stay as `requirements.md`-only until the user runs `louie-feature` for each one in turn (Steps 8–12 below cover only the first feature). This keeps the per-feature loop tight and prevents the bundle-everything-up-front anti-pattern.

8. **Confirmation gate (feature doc):**
   - Present the feature document and implementation plan to the user
   - Wait for explicit confirmation before coding

9. **Invoke Leo (Designer) — if the feature has UI:**
   - Read and follow `_LOUIE_/agents/designer.md`
   - Skip this step for backend-only features

10. **Invoke Nina (Coder):**
    - Read and follow `_LOUIE_/agents/coder.md`
    - Nina implements **this one feature** and updates its feature document. She does not pre-implement the other planned features — they get their own pass via `louie-feature` later.

11. **Invoke Max (Reviewer):**
    - Read and follow `_LOUIE_/agents/reviewer.md`
    - If changes are needed, Nina fixes them before proceeding

12. **Invoke Ava (Tester):**
    - Read and follow `_LOUIE_/agents/tester.md`
    - Ava writes tests and gives a ship recommendation

13. **Hand off to the next feature:**
    - Tell the user which features remain in the Planned table and that the next one ships by running `louie-feature` (which will go straight to creating the `feature.md` from the already-captured `requirements.md`).

## Usage

```
louie-setup
```

or with an idea upfront:

```
louie-setup
I want to build a recipe manager where I can save recipes from URLs,
organize them by tags, and plan weekly meals.
```

## Tips for a Good Initial Idea

You don't need to be detailed — Tom will interview you. But a good starting point includes:

- **What** the project does in 1-2 sentences
- **Who** it's for (even roughly: "for me", "for a small team", "public-facing")
- **Any hard constraints** you already know (must be mobile-friendly, needs to work offline, etc.)
