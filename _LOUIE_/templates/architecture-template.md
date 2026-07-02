# Architecture

> **Size rule (partitioned architecture):** this file must stay readable in one pass. When it crosses **~400 lines or ~6+ domains**, Sophie proposes splitting it (her subsequent-run size check): this file slims to an **index** — system diagram, domain list (one line each: name, responsibility, path roots, link), cross-domain dependency rules, cross-cutting concerns, deployment topology, system-level ADRs — and per-domain detail moves to `_LOUIE-output/architecture/<domain>.md` (from `architecture-domain-template.md`). The split is one-way, user-gated, and runs via `louie-migrate`. The domain names defined here are the partition vocabulary everywhere: the codebase map, overview grouping, and evaluate chunks all reuse them. Below the threshold, one file is correct — don't split early.

Last Updated: YYYY-MM-DD

## Project Overview

[2-3 sentences — what the system is]

## High-Level Diagram

```mermaid
[system diagram]
```

## Architectural Style

[e.g., Clean Architecture, Hexagonal, Layered, Microservices, Modular Monolith]

**Rationale:** [why this style fits]

## Layers / Modules

### [Layer Name]

**Responsibility:** [what it does]
**Key Patterns:** [e.g., Repository, Unit of Work, CQRS]
**Depends on:** [other layers]

## Data Flow

[Describe how data moves through the system for key operations]

## Folder Structure

```
src/
├── [...]
```

**Rationale:** [why organized this way]

## Integration Points

- [External APIs, message queues, third-party services]

## Deployment Topology

[How the app is deployed — containers, regions, CDN, etc.]

## Scaling Considerations

[Horizontal vs vertical, bottlenecks, caching strategy]

## Security Model

- **Authentication:** [approach]
- **Authorization:** [approach]
- **Data protection:** [at rest, in transit]
- **Input validation:** [where and how]

## Cross-Cutting Concerns

- **Logging:** [approach]
- **Error handling:** [approach]
- **Configuration:** [approach]

## Architectural Decision Records (ADRs)

### ADR-001: [Decision Title]

**Context:** [why the decision was needed]
**Decision:** [what was decided]
**Consequences:** [tradeoffs]

## Handoff to Leo (Designer) / Nina (Coder)

- **Key patterns to follow:** [list]
- **Patterns to avoid:** [list]
- **Open technical questions:** [list]
