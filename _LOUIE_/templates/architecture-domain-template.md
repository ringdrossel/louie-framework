# Domain: [Name]

> **Layout:** this file lives at `_LOUIE-output/architecture/<domain>.md` — one per domain of a partitioned architecture (see the note in `architecture-template.md`). The slim `_LOUIE-output/architecture.md` index stays the always-read entry point; agents read this doc only when working in this domain. Keep the domain name identical to its row in the index and the codebase map.

Last Updated: YYYY-MM-DD

## Responsibility

[1-2 sentences — what this domain owns]

## Path Roots

- `[src/<domain>/**]`

## Internal Structure

### Layers / Patterns

[Layers, key patterns (repository, service, etc.) inside this domain]

### Data Flow

[How data moves through this domain for its key operations]

### Folder Structure

```
src/[domain]/
├── [...]
```

## Integration Points

[Which *other* domains this one talks to and through what interface — name them, so the reader knows which sibling domain doc matters. Cross-domain dependency *rules* live in the architecture index, not here.]

## Domain ADRs

### ADR-[domain]-001: [Decision Title]

**Context:** [why the decision was needed]
**Decision:** [what was decided]
**Consequences:** [tradeoffs]
