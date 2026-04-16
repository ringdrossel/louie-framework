# Project Setup with LOUIE

## Overview

This guide walks you through deploying the LOUIE framework into a new project and running your first agent sequence.

## Step 1: Copy the Framework

Copy the `_LOUIE_/` directory into your project root:

```
your-project/
├── _LOUIE_/          ← copy this entire directory
├── src/              ← your source code
└── README.md
```

That's it for the framework itself. The `_LOUIE-output/` directory will be created automatically as agents produce their artifacts.

## Step 2: Create the Output Directory

Create the initial output structure:

```bash
mkdir -p _LOUIE-output/requirements
mkdir -p _LOUIE-output/implementations
```

Optionally, create a starter `overview.md`:

```bash
touch _LOUIE-output/implementations/overview.md
```

Your project should now look like:

```
your-project/
├── _LOUIE_/                         ← the framework (tool)
│   ├── README.md
│   ├── setup/
│   ├── agents/
│   ├── templates/
│   ├── guidelines/
│   └── workflow/
├── _LOUIE-output/                   ← agent artifacts (work)
│   ├── requirements/
│   └── implementations/
│       └── overview.md
└── src/
```

## Step 3: First-Time Agent Sequence

When starting a brand new project, run the agents in this order:

### 3a. Start with Tom (Analyst)

Paste the initial prompt from `_LOUIE_/setup/initial-prompt.md` into your AI assistant, filling in your project idea. Tom will interview you and produce a requirements document.

### 3b. Run Sophie (Architect)

After Tom produces requirements, invoke Sophie:

```
Invoke _LOUIE_/agents/architect.md

Requirements are ready in _LOUIE-output/requirements/[feature]-requirements.md.
This is a new project — please produce architecture.md and tech-stack.md.
```

Sophie will produce:
- `_LOUIE-output/architecture.md`
- `_LOUIE-output/tech-stack.md`

**Review both documents carefully.** These define every technical decision for your project. Confirm before proceeding.

### 3c. Proceed with Feature Work

Once architecture is confirmed, follow the standard workflow in `_LOUIE_/workflow/ai-workflow.md`:
1. Create a feature document from the template
2. Get confirmation
3. Run Leo (Designer) if UI is involved
4. Run Nina (Coder) to implement
5. Run Max (Reviewer) to review
6. Run Ava (Tester) to test

## Git Recommendations

Add both directories to version control:

```bash
git add _LOUIE_/ _LOUIE-output/
git commit -m "docs: add LOUIE framework and initial artifacts"
```

Consider adding to `.gitignore` if you don't want to track agent output:

```
# Uncomment if you don't want agent artifacts in version control
# _LOUIE-output/
```

Most teams benefit from tracking `_LOUIE-output/` — it provides a history of requirements and architectural decisions.

## Adding LOUIE to an Existing Project

If your project already has source code but no LOUIE framework:

1. Copy `_LOUIE_/` into the project root
2. Create `_LOUIE-output/` structure (Step 2 above)
3. Run Sophie (Architect) to document your existing architecture and tech stack
4. From now on, follow the standard workflow for new features

You don't need to retroactively create requirements or feature docs for existing code — just use LOUIE going forward.

## Updating LOUIE

To update the framework:

1. Replace the `_LOUIE_/` directory with the new version
2. Your `_LOUIE-output/` artifacts are untouched — they live separately by design
3. Review the changelog for any changes to agent behavior or templates

## Quick Reference

| What you want | What to do |
|---------------|------------|
| Start a new project | Paste `setup/initial-prompt.md` into your AI assistant |
| Add a feature | Invoke Tom (`agents/analyst.md`) with your idea |
| Fix a bug | Follow the bug fix scenario in `workflow/ai-workflow.md` |
| Get ideas | Invoke Ivy (`agents/muse.md`) |
| Understand the workflow | Read `workflow/ai-workflow.md` |
| Know the coding rules | Read `guidelines/coding-guidelines.md` |
