# Runbook System

Design notes for `_LOUIE-output/runbook.md` — the operational/runtime reference produced alongside `architecture.md` and `tech-stack.md`. Read this before changing the runbook template, the agents that touch it, or the workflow steps that produce it.

> **Update 2026-05-21:** The accumulating `Common Gotchas` section was removed (LLM dilution: long flat lists are write-only sinks; the right fact is rarely in the relevant top-K). Operational caveats now live inline as Notes-column parentheticals next to the entry they affect. Implementation learnings moved to per-feature `bugfixes/<slug>.md` (mandatory Detect/Avoid section) plus code-local `// WHY` comments. This file's narrative below predates that change — keep it for design history, but the current template no longer carries Common Gotchas as a section.

## Why It Exists

LOUIE projects accumulate operational content with no canonical home: deployment commands, port assignments, gotchas discovered during implementation, "how do I restart this thing" knowledge. Without a slot, AI sessions invent ad-hoc files (e.g. `project-context.md`) that drift from the canonical docs. The runbook fills this gap.

The need is real and category-wide. Comparison against established AI dev frameworks (verified April 2026):

| Framework | How operational content is handled |
|-----------|------------------------------------|
| **SpecKit** | `plan-template.md` has zero deployment/runtime sections. Operational concerns "intentionally deferred" with no canonical home. |
| **BMAD V4** | 17-section `architecture-tmpl.yaml` includes "Infrastructure and Deployment" but no local-dev setup, gotchas, or runbook content. Covers maybe half of what a project actually needs. |
| **BMAD V6** | Architecture template lost sections vs. V4 (see Discussion #979). Even less coverage. |
| **Cursor / Aider / Claude Code** | Catch-all in `.cursorrules` / `CONVENTIONS.md` / `CLAUDE.md`. Mixes coding rules, project context, ops in one file. |
| **SRE practice (non-AI)** | Runbook is a first-class artifact for decades. AI frameworks haven't adopted it. |

LOUIE adopts the SRE convention: a separate, slow-growing operational reference, distinct from architecture and from coding rules.

## Why Not Absorb Into `architecture.md`

BMAD V4 demonstrated this approach. Two failure modes:

1. **The doc grows unbounded.** Architecture should be a stable design reference. Operational gotchas accumulate forever — every bug discovered adds an entry. A monolithic doc ends up unreadable as a design reference.
2. **Sections drift.** BMAD's V4→V6 regression shows that big templates lose discipline over time — sections get dropped during template revisions. A small, focused `runbook.md` with a stable 6-section template is more durable than relying on architecture template discipline.

Different audiences, different lifetimes, different update cadences:

| Concern | Audience | Cadence | Right home |
|---------|----------|---------|-----------|
| Design / structure | Designers, architects, new devs onboarding | Stable | `architecture.md` |
| Tech choices | Anyone evaluating the stack | Slow change | `tech-stack.md` |
| Run commands, ports, gotchas | Anyone *running* the system | Constant accretion | `runbook.md` |

Splitting matches reality.

## Lifecycle

| Phase | Agent | Action |
|-------|-------|--------|
| Initial creation (`louie-setup`) | **Sophie** | Produce skeleton runbook alongside `architecture.md` / `tech-stack.md`. Pre-fill deployment model, ports, common commands, env vars from architectural decisions. Common Gotchas starts empty. |
| Feature work (`louie-feature`, `louie-extend`) | **Nina** | After implementation, append: any new ports / endpoints / commands the feature added; any new env vars; gotchas discovered during the work. |
| Bugfix (`louie-bugfix`) | **Nina** | Append a Common Gotchas entry: what went wrong, how to detect it, how to avoid. Bugfixes are the highest-value runbook entries. |
| Code review (`louie-review`, `louie-review-doc`) | **Max** | Verify new ports / commands / gotchas from the change actually got added. One-line check on existing review checklist. |

No new agent needed. Each existing agent gets a small, additive responsibility that matches their natural workflow.

## Design Decisions

### Required Output of `louie-setup`

The runbook is **required**, not optional. Every real project needs one even if minimal — the deployment model and ports always exist. An empty `runbook.md` at setup is wrong; a sparse but accurate one is right. Sophie produces it from the same architectural decisions she just made.

### Six Sections

The template has six sections — between BMAD V4's 17 (too many to maintain) and SpecKit's 0 (nothing to maintain). Each section is small and orthogonal:

1. **Deployment Model** — how it runs (one paragraph)
2. **Ports & Endpoints** — table of bindings
3. **Common Commands** — start/stop/status/logs/db, with real shell snippets
4. **Environment & Dependencies** — env vars + external services
5. **Common Gotchas** — append-only running list, dated entries
6. **Debugging** — symptom → first-thing-to-check table

`Notes for Maintainers` is a footer, not a numbered section.

### Append, Don't Rewrite

Common Gotchas is **append-only**. Old entries stay even when the underlying issue is resolved — they may resurface, and they document history. Nina's instruction is to add new entries on top with a date. A "Resolved" subsection at the bottom is allowed but not required.

This differs from `architecture.md`, which gets rewritten/updated in place. The runbook's Common Gotchas is more like a journal.

### Lazy-Loaded, Like Everything Else

The runbook is not auto-loaded by `CLAUDE.md`. It's read on demand by:
- Nina before feature work (along with architecture + tech-stack)
- Nina at the end of feature/bugfix work (to append)
- Max during review (to verify additions)
- Any agent doing run/deploy/debug work
- The user when they need to operate the system

The framework respects the lazy-loading principle (`core.md` → Lazy-Loading Principle). No cross-cutting changes to `CLAUDE.md`.

## What Goes Where (Decision Table)

When in doubt about which doc gets new content:

| Content | Goes in |
|---------|---------|
| Why we chose Postgres over MySQL | `architecture.md` (ADR) or `tech-stack.md` (rationale) |
| What version of Postgres | `tech-stack.md` |
| How to start Postgres locally | `runbook.md` (Common Commands) |
| What port Postgres binds | `runbook.md` (Ports) |
| The schema of the `users` table | `architecture.md` (Data Models) or feature doc |
| The migration command | `runbook.md` (Common Commands) |
| "Don't forget to bump `?v=` after frontend changes" | `runbook.md` (Common Gotchas) |
| "All API errors return JSON shape `{error, code}`" | `architecture.md` (Cross-Cutting Concerns) or feature doc |
| Coding style — when to use early returns | `_LOUIE_/guidelines/coding-guidelines.md` |

When still unclear: ask "is this a *design* concern or a *runtime* concern?" Design → architecture. Runtime → runbook.

## Open Questions / Future

- **Periodic pruning.** If gotchas grow past ~50 entries, we may want a `louie-runbook-prune` command or a Max-driven periodic cleanup. Defer until pain appears.
- **Per-environment runbooks.** Some projects have meaningfully different runbooks for local / staging / prod. Single `runbook.md` for now; revisit if multi-env projects start branching it.
- **Migration for existing projects.** Existing LOUIE projects need a one-time bootstrap to create their runbook. The user prompt at the bottom of the framework changelog handles this case.

## References

- `_LOUIE_/templates/runbook-template.md` — the canonical shape
- `_LOUIE_/agents/architect.md` — Sophie's role (initial creation)
- `_LOUIE_/agents/coder.md` — Nina's role (maintenance)
- `_LOUIE_/agents/reviewer.md` — Max's role (verification)
- `core.md` → Lazy-Loading Principle, Three Directories
