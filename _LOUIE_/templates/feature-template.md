# Feature: [Name]

> **Layout:** this file lives at `_LOUIE-output/implementations/<feature>/feature.md`. Sibling files in the same folder: `requirements.md` (Tom's output), `decisions.md` (feature-scoped ADRs), and `bugfixes/<YYYY-MM-DD>-<slug>.md` (one per fix). Pre-feature-folder ideas live in `_LOUIE-output/roadmap.md`; promote one via `louie-feature --from-roadmap <id>`.

## Status

- [ ] Planned
- [ ] In Development
- [ ] Implemented
- [ ] Tested

## Metadata

- **Type:** API / Client / Integration
- **Priority:** High / Medium / Low
- **Dependencies:** [other features or "None"]
- **Affected Entities:** [from architecture diagram]
- **Created:** YYYY-MM-DD
- **Last Updated:** YYYY-MM-DD

## Overview

[Brief description of the feature — max 3 sentences]

## Requirements Reference

See `_LOUIE-output/implementations/[feature]/requirements.md` for full requirements, user stories, and acceptance criteria.

## Decisions Reference

See `_LOUIE-output/implementations/[feature]/decisions.md` for ADRs scoped to this feature (if any have been recorded).

## Technical Details

Refer to `_LOUIE-output/architecture.md` for system patterns and `_LOUIE-output/tech-stack.md` for technology choices.

### Components/Modules

- `Component/ModuleName` — [Description]
- `ServiceName` — [Description]

### API Endpoints (if relevant)

- `GET /api/...`
- `POST /api/...`

### Data Model

[Reference to architecture entities and data flow]

## Implementation Plan

### Phase 1: Preparation

- [ ] Task 1
- [ ] Task 2

### Phase 2: Backend/Frontend

- [ ] Task 1
- [ ] Task 2

### Phase 3: Integration & Testing

- [ ] Task 1
- [ ] Task 2

## Code Structure

### Files

```
[Overview of files to be created/modified]
```

### Key Interfaces/Types

```
// Important interfaces/types as reference
```

## Testing Strategy

- Unit Tests
- Integration Tests
- E2E Tests

## Bug Fixes

Per-feature bug fixes live in the sibling `bugfixes/` folder, one file per fix named `YYYY-MM-DD-<slug>.md`. They follow `_LOUIE_/templates/bugfix-template.md`.

The cross-project index is `_LOUIE-output/bugfixes/overview.md` — Nina updates it whenever she lands a fix.

## Open Questions

- [ ] Question 1
- [ ] Question 2

## Change History

> **One line per entry. No exceptions.** This log is a chronological index of *what happened and when*, not a narrative. Rationale, SF/decision references, file lists, test rationale, and deferred suggestions belong in `decisions.md` (ADRs), `bugfixes/<slug>.md`, the code itself, or `git log` — **not** in the history line. If you're writing more than ~120 characters, you're writing in the wrong place.
>
> Format: `YYYY-MM-DD: <kind> — <short summary>. [optional pointer]`
>
> Examples:
> - `2026-05-17: Initially created`
> - `2026-05-17: Chunk 5 — parked-prompt resume unified across daemon restart (+8 tests)`
> - `2026-05-17: Max review — 3 critical, 2 should-fix addressed; suggestions deferred`
> - `2026-05-17: Bug fix — daemon re-mints prompt id on resume (see bugfixes/2026-05-17-resume-id.md)`
> - `2026-05-17: ADR-007 — chose ws over sse for daemon transport (see decisions.md)`

- YYYY-MM-DD: Initially created

## Handoff to Max (Reviewer)

- **Files changed:** [list of created/modified files]
- **Key decisions made during implementation:** [list]
- **Areas of concern:** [anything the reviewer should pay extra attention to]
- **Testing notes:** [what was tested, what needs manual verification]
