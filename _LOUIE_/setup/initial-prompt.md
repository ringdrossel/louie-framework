# louie-setup

When the user says **`louie-setup`**, follow this procedure to initialize the LOUIE workflow.

## Procedure

1. **Read the framework context:**
   - Read `_LOUIE_/README.md` for an overview of LOUIE
   - Read `_LOUIE_/workflow/ai-workflow.md` for the full workflow
   - Read `_LOUIE_/workflow/agent-handoffs.md` for handoff protocol

2. **Greet the user and explain what's about to happen:**
   - Introduce the LOUIE framework briefly
   - Explain that Tom (Analyst) will interview them about their project/feature idea
   - After requirements, Sophie (Architect) will define the architecture and tech stack
   - Both will be shown for confirmation before any code is written

3. **Ask for their idea:**
   - If the user already provided an idea alongside the `louie-setup` command, proceed directly
   - If not, ask: "What's the project or feature you'd like to build? A sentence or two is enough — Tom will ask follow-up questions."

4. **Invoke Tom (Analyst):**
   - Read and follow `_LOUIE_/agents/analyst.md`
   - Tom interviews the user and produces `_LOUIE-output/requirements/[feature-name]-requirements.md`
   - Use the template from `_LOUIE_/templates/requirements-template.md`

5. **Invoke Sophie (Architect):**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie produces `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`
   - Use templates from `_LOUIE_/templates/architecture-template.md` and `_LOUIE_/templates/tech-stack-template.md`

6. **Confirmation gate:**
   - Show the user the requirements, architecture, and tech stack
   - Wait for explicit confirmation before proceeding to feature work

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

### Examples

**Minimal (Tom will ask lots of follow-ups):**
```
louie-setup
A recipe manager for personal use.
```

**Moderate (Tom has more to work with):**
```
louie-setup
A recipe manager where I can save recipes from URLs, organize them by tags,
and plan weekly meals. Just for me and my partner. Should work on phone and desktop.
```

**Detailed (Tom may use Light Mode):**
```
louie-setup
A task management tool for a team of 5 developers. Need kanban boards, time tracking,
GitHub integration for linking PRs to tasks, and a simple reporting dashboard.
Self-hosted on our existing server. We're comfortable with Docker.
```
