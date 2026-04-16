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

Architecture and tech stack already exist. The chain is shorter.

### Step 1: Talk to Tom (Analyst)

Same as above — Tom interviews you about the new feature.

### Step 2: Sophie (Architect) — self-assessment

Sophie reads the new requirements and checks if they fit the existing architecture.

- **If yes:** skip to Step 3 — Sophie writes a brief handoff note
- **If no:** Sophie proposes minimal updates, gets your confirmation, then proceeds

### Steps 3–7: Same as New Project

Create feature doc → Leo (if UI) → Nina → Max → Ava.

---

## Scenario 3: Bug Fix

```
CONTEXT:
- Read _LOUIE-output/architecture.md
- Read _LOUIE_/guidelines/coding-guidelines.md
- Find the affected feature document

Bug in Feature: [Feature-Name]
Problem: [Brief description]

PROCEDURE:
1. Find and read the feature document
2. Analyze the problem
3. Fix the bug
4. Run tests
5. Update change history in feature document
6. Have Max review the fix
```

---

## Scenario 4: Product Ideation

```
Invoke _LOUIE_/agents/muse.md

I'd like ideas for improving [area/feature/the whole product].
```

Ivy suggests ideas. If you like one, engage Tom to write requirements for it.

---

## Short-Form Prompts

### New Project
```
Invoke Tom: _LOUIE_/agents/analyst.md
My idea: [description]
→ Full chain from there
```

### New Feature (existing project)
```
Invoke Tom: _LOUIE_/agents/analyst.md
New feature: [description]
→ Tom interviews, then chain continues
```

### Bug Fix
```
Context: _LOUIE-output/implementations/[feature].md
Bug: [feature] — [problem]
→ Analyze, fix, review, test
```

### Ideation
```
Invoke Ivy: _LOUIE_/agents/muse.md
→ Get ideas, pick favorites, send to Tom
```

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
