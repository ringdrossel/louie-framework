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
   - Tom interviews the user and produces `_LOUIE-output/requirements/[feature-name]-requirements.md`
   - Use the template from `_LOUIE_/templates/requirements-template.md`
   - Tom also updates `_LOUIE-output/implementations/overview.md` with the project context (name, goal, status) and adds the first feature to the Planned table

5. **Invoke Sophie (Architect):**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie reads Tom's requirements and produces:
     - `_LOUIE-output/architecture.md` — system architecture with mermaid diagram, layers, patterns, folder structure, security model
     - `_LOUIE-output/tech-stack.md` — every technology choice with rationale
   - Use templates from `_LOUIE_/templates/architecture-template.md` and `_LOUIE_/templates/tech-stack-template.md`

6. **Confirmation gate (architecture):**
   - Present the requirements, architecture, and tech stack to the user
   - Walk through the key decisions and their rationale
   - Wait for explicit confirmation before proceeding
   - If the user wants changes, update the documents and re-present

7. **Create feature document:**
   - Create `_LOUIE-output/implementations/[feature-name].md` using `_LOUIE_/templates/feature-template.md`
   - Fill in all sections based on Tom's requirements and Sophie's architecture
   - This is for the feature Tom already captured — do NOT ask "which feature?" again

8. **Confirmation gate (feature doc):**
   - Present the feature document and implementation plan to the user
   - Wait for explicit confirmation before coding

9. **Invoke Leo (Designer) — if the feature has UI:**
   - Read and follow `_LOUIE_/agents/designer.md`
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
