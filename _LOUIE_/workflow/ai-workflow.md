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
| **Tom** (Analyst) | Requirements interview | `_LOUIE-output/implementations/[feature]/requirements.md` |
| **Sophie** (Architect) | Architecture + tech stack + runbook (initial) | `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, `_LOUIE-output/runbook.md` |
| **Leo** (Designer) | UI/UX design | UI section in `[feature]/feature.md` |
| **Nina** (Coder) | Implementation + runbook updates + bugfix docs | Source code + `_LOUIE-output/implementations/[feature]/feature.md` (and `decisions.md` when an ADR is made) + bugfix docs + appended entries in `runbook.md` |
| **Max** (Reviewer) | Code review + runbook + bugfix coverage check | Review comments on `[feature]/feature.md` |
| **Ava** (Tester) | Test writing | Test files + coverage notes in `[feature]/feature.md` |
| **Ivy** (Muse) | Product ideation | Idea list for user consideration |

---

## Scenario 1: Starting a New Project

This is the full chain. Run every step in order.

### Step 1: Talk to Tom (Analyst)

```
Invoke _LOUIE_/agents/analyst.md

My idea: [describe your project or first feature]
```

Tom creates the feature folder and produces `_LOUIE-output/implementations/[feature]/requirements.md`.

### Step 2: Talk to Sophie (Architect)

```
Invoke _LOUIE_/agents/architect.md

Requirements are ready in _LOUIE-output/implementations/[feature]/requirements.md
```

Sophie produces `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`.

**CONFIRMATION GATE:** Review all three documents. No one proceeds until you approve.

### Step 3: Create Feature Document

Create `_LOUIE-output/implementations/[feature]/feature.md` using `_LOUIE_/templates/feature-template.md`. Fill in all sections based on the requirements and architecture.

**CONFIRMATION GATE:** Review the feature document and implementation plan. Confirm before coding.

### Step 4: Talk to Leo (Designer) — if the feature has UI

```
Invoke _LOUIE_/agents/designer.md

Feature folder: _LOUIE-output/implementations/[feature]/
```

Leo designs the component structure and UX. Skip this step for backend-only features.

### Step 5: Talk to Nina (Coder)

```
Invoke _LOUIE_/agents/coder.md

Feature folder: _LOUIE-output/implementations/[feature]/
```

Nina implements the feature, updates `feature.md` (and creates `decisions.md` if an ADR was made), and hands off to Max.

### Step 6: Talk to Max (Reviewer)

```
Invoke _LOUIE_/agents/reviewer.md

Feature folder: _LOUIE-output/implementations/[feature]/
Review the implementation.
```

Max reviews and provides feedback. If changes are needed, Nina fixes them before proceeding.

### Step 7: Talk to Ava (Tester)

```
Invoke _LOUIE_/agents/tester.md

Feature folder: _LOUIE-output/implementations/[feature]/
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

## Scenario 6: Importing an Existing Project

Use `louie-import` when adding LOUIE to a project that already has source code (and optionally v1-style docs at `docs/implementations/`):

```
louie-import
```

The command auto-detects mode:

- **Cold import** — no prior LOUIE-shaped docs. Sophie scans the codebase to infer architecture, tech stack, runbook, and discovered features. Tom interviews to fill gaps (project goal, target users, acceptance criteria).
- **v1-docs import** — `docs/implementations/overview.md` plus per-feature `*.md` siblings exist. Sophie still scans the code; v1 docs are translated into LOUIE feature docs. Tom asks only what's missing.

In both modes, discovered features are written with status **Implemented** (the running code is the source of truth). After Sophie + Tom finish, the standard architecture confirmation gate applies.

`louie-import` does not run Leo, Nina, Max, or Ava. It is a documentation pass — no source code is modified. After it completes, the project behaves like one that went through `louie-setup` plus several rounds of `louie-feature`.

The init scripts (`_LOUIE_/setup/<tool>-init.{sh,bat}`) detect existing projects and recommend running `louie-import` after install.

---

## Scenario 7: Product Ideation

Use `louie-ideate`:

```
louie-ideate
I think the dashboard could be more useful. What ideas do you have?
```

Ivy suggests ideas. At the end she'll offer to sort each one: **pursue now** (run `louie-feature` to build it), **save to the roadmap** (capture in `_LOUIE-output/roadmap.md` for later), or **drop**.

---

## Scenario 8: Capture an Idea Without Committing

Use `louie-roadmap` when you want to write an idea down without kicking off a full feature chain. Captured ideas live in `_LOUIE-output/roadmap.md` (lazy-created on first `add`) — pre-feature-folder, no requirements, no architecture eval.

```
louie-roadmap add "CSV import for recipes"
```

When you're ready to build a captured idea, promote it:

```
louie-roadmap promote R-007
```

Promotion delegates to `louie-feature --from-roadmap R-007`, which seeds Tom with the captured notes and runs the full chain. The roadmap entry moves from `## Captured` to `## Promoted` with a back-link to the new feature folder.

This is distinct from `implementations/overview.md` — "Planned" features there already have a folder, requirements, and architecture evaluation. Roadmap entries earn that during promotion.

---

## All Commands

| Command | What it does |
|---------|-------------|
| `louie-setup` | Initialize a new project (Tom interviews, Sophie architects) |
| `louie-import` | Import an existing project (cold or v1 docs) into LOUIE |
| `louie-migrate` | Migrate an old-layout LOUIE project to per-feature folders |
| `louie-feature` | Add a new feature (full chain: Tom → Sophie → Leo → Nina → Max → Ava) |
| `louie-extend` | Extend an existing feature |
| `louie-update` | Quick change (< 50 lines, auto-escalates to `louie-extend`) |
| `louie-bugfix` | Diagnose and fix a bug |
| `louie-review` | Code review by Max |
| `louie-review-doc` | Review + fix + update docs in one flow |
| `louie-test` | Write or improve tests with Ava |
| `louie-doc` | Update documentation and generate a commit message |
| `louie-ideate` | Brainstorm ideas with Ivy |
| `louie-roadmap` | Capture pre-feature ideas in `_LOUIE-output/roadmap.md`; promote one to a full feature when ready |
| `louie-recipe` | Browse or load a reusable recipe (settings, auth, Docker, etc.) |
| `louie-update-framework` | Update LOUIE to the latest version |

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
Sophie (Architect) ─── evaluate ──→ architecture.md + tech-stack.md + runbook.md
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
├── architecture.md               ← Sophie's output (design)
├── tech-stack.md                 ← Sophie's output (build-time)
├── runbook.md                    ← Sophie's output (run-time); Nina appends
├── roadmap.md                    ← pre-feature idea list; lazy-created on first `louie-roadmap add`
├── implementations/              ← One folder per feature + slim overview
│   ├── overview.md               ← slim index of all features
│   └── [feature]/
│       ├── feature.md            ← Nina's output (the implementation doc)
│       ├── requirements.md       ← Tom's output (requirements for this feature)
│       ├── decisions.md          ← feature-scoped ADRs; created when needed
│       └── bugfixes/
│           └── YYYY-MM-DD-<slug>.md   ← one file per per-feature bug fix
└── bugfixes/                     ← Cross-project bug-fix index + cross-cutting fixes
    ├── overview.md
    └── YYYY-MM-DD-<slug>.md      ← bug fixes touching multiple features
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
