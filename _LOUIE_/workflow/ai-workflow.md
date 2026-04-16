# LOUIE AI Workflow

## CRITICAL RULE

**NEVER implement directly without first:**

1. Creating a feature document
2. Showing the implementation plan
3. Receiving user confirmation

**NEVER start feature work without:**

1. Architecture and tech stack confirmed by user (`_LOUIE-output/architecture.md` + `_LOUIE-output/tech-stack.md`)

These rules apply ALWAYS, without exception.

---

## The Agent Chain

```
  Tom          Sophie        Leo          Nina         Max          Ava
(Analyst) → (Architect) → (Designer) → (Coder) → (Reviewer) → (Tester)
                              ↑
                              optional
                              (skip for backend-only)

Ivy (Muse) — runs independently, feeds ideas back to Tom
```

### Agent Responsibilities

| Agent | Role | Produces |
|-------|------|----------|
| **Tom** (Analyst) | Requirements interview | `_LOUIE-output/requirements/[feature].md` |
| **Sophie** (Architect) | Architecture + tech stack | `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md` |
| **Leo** (Designer) | UI/UX design | UI section in feature document |
| **Nina** (Coder) | Implementation | Source code + `_LOUIE-output/implementations/[feature].md` |
| **Max** (Reviewer) | Code review | Review comments on feature doc |
| **Ava** (Tester) | Test writing | Test files + coverage notes |
| **Ivy** (Muse) | Product ideation | Idea list for user consideration |

---

## Scenario 1: Starting a New Project

This is the full chain. Run every step in order.

### Step 1: Talk to Tom (Analyst)

```
Invoke _LOUIE_/agents/analyst.md

My idea: [describe your project or first feature]
```

Tom interviews you and produces `_LOUIE-output/requirements/[feature]-requirements.md`.

### Step 2: Talk to Sophie (Architect)

```
Invoke _LOUIE_/agents/architect.md

Requirements are ready in _LOUIE-output/requirements/[feature]-requirements.md
```

Sophie produces `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.

**CONFIRMATION GATE:** Review both documents. No one proceeds until you approve.

### Step 3: Create Feature Document

Create `_LOUIE-output/implementations/[feature].md` using `_LOUIE_/templates/feature-template.md`. Fill in all sections based on the requirements and architecture.

**CONFIRMATION GATE:** Review the feature document and implementation plan. Confirm before coding.

### Step 4: Talk to Leo (Designer) — if the feature has UI

```
Invoke _LOUIE_/agents/designer.md

Feature doc: _LOUIE-output/implementations/[feature].md
```

Leo designs the component structure and UX. Skip this step for backend-only features.

### Step 5: Talk to Nina (Coder)

```
Invoke _LOUIE_/agents/coder.md

Feature doc: _LOUIE-output/implementations/[feature].md
```

Nina implements the feature, updates the feature doc, and hands off to Max.

### Step 6: Talk to Max (Reviewer)

```
Invoke _LOUIE_/agents/reviewer.md

Feature doc: _LOUIE-output/implementations/[feature].md
Review the implementation.
```

Max reviews and provides feedback. If changes are needed, Nina fixes them before proceeding.

### Step 7: Talk to Ava (Tester)

```
Invoke _LOUIE_/agents/tester.md

Feature doc: _LOUIE-output/implementations/[feature].md
Write tests for the implementation.
```

Ava writes tests and provides a final ship/no-ship recommendation.

---

## Scenario 2: Adding a Feature to an Existing Project

Use `louie-feature`:

```
louie-feature
Add a notification system for real-time alerts.
```

This runs the full chain automatically — Tom interviews, Sophie evaluates fit with existing architecture, then feature doc → Leo → Nina → Max → Ava.

---

## Scenario 3: Extending an Existing Feature

Use `louie-extend`:

```
louie-extend user-authentication
Add OAuth2 support for Google and GitHub login.
```

---

## Scenario 4: Bug Fix

Use `louie-bugfix`:

```
louie-bugfix user-authentication
The password reset link expires immediately instead of after 24 hours.
```

Nina diagnoses and fixes, Max reviews, Ava adds a regression test.

---

## Scenario 5: Code Review

Use `louie-review`:

```
louie-review user-authentication
```

Max reviews against architecture, guidelines, and the feature document.

---

## Scenario 6: Product Ideation

Use `louie-ideate`:

```
louie-ideate
I think the dashboard could be more useful. What ideas do you have?
```

Ivy suggests ideas. If you like one, run `louie-feature` to build it.

---

## All Commands

| Command | What it does |
|---------|-------------|
| `louie-setup` | Initialize a new project |
| `louie-feature` | Add a new feature (full chain) |
| `louie-extend` | Extend an existing feature |
| `louie-update` | Quick change (< 50 lines, auto-escalates) |
| `louie-bugfix` | Diagnose and fix a bug |
| `louie-review` | Code review by Max |
| `louie-review-doc` | Review + fix + update docs in one flow |
| `louie-test` | Write or improve tests with Ava |
| `louie-doc` | Update documentation + generate commit message |
| `louie-ideate` | Brainstorm ideas with Ivy |

Command definitions live in `_LOUIE_/commands/`.

---

## Workflow Diagram

```
New Requirement
      │
      ▼
Tom (Analyst) ─── interview ──→ requirements.md
      │
      ▼
Sophie (Architect) ─── evaluate ──→ architecture.md + tech-stack.md
      │                              (first run or update)
      ▼
  ┌─────────────────┐
  │ CONFIRMATION     │
  │ GATE             │
  │ User approves    │
  │ architecture     │
  └────────┬────────┘
           ▼
Create Feature Document (from template)
           │
           ▼
  ┌─────────────────┐
  │ CONFIRMATION     │
  │ GATE             │
  │ User approves    │
  │ feature doc      │
  └────────┬────────┘
           ▼
Leo (Designer) ─── if UI ──→ component design
           │
           ▼
Nina (Coder) ─── implement ──→ source code + updated feature doc
           │
           ▼
Max (Reviewer) ─── review ──→ feedback (loop back to Nina if needed)
           │
           ▼
Ava (Tester) ─── test ──→ test files + ship recommendation
           │
           ▼
        Done
```

---

## Documentation Structure

```
_LOUIE_/                          ← The framework (you are here)
├── agents/                       ← Agent definitions
├── templates/                    ← Output templates
├── guidelines/                   ← Coding rules
├── workflow/                     ← This document + handoff protocol
└── setup/                        ← Deployment & kickoff

_LOUIE-output/                    ← Agent-produced artifacts
├── architecture.md               ← Sophie's output
├── tech-stack.md                 ← Sophie's output
├── requirements/                 ← Tom's output
│   └── [feature]-requirements.md
└── implementations/              ← Feature docs + overview
    ├── overview.md
    └── [feature].md
```

---

## Tips

### DO
- **Be specific:** "User login with email/password and OAuth" not "add auth"
- **Give context:** "This extends the existing dashboard" not "add a chart"
- **Trust the chain:** Let each agent do their job — don't skip steps
- **Review at gates:** The two confirmation gates exist to catch mistakes early

### DON'T
- **Don't skip Tom:** Even "simple" features benefit from clear requirements
- **Don't code without a feature doc:** This is the #1 rule
- **Don't bypass confirmation gates:** A few minutes of review saves hours of rework
- **Don't clutter the overview:** Only feature list + status in `overview.md` — details go in feature docs
