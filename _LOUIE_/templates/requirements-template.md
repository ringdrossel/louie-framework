# Requirements: [Feature Name]

> **Scope rule:** one feature = one capability / user-story cluster, ~5–8 stories. If this document covers auth + UI + persistence + integrations + admin, it is in the wrong shape — split it into multiple feature folders. See `_LOUIE_/agents/analyst.md` § Step 4a.
>
> **Length budget:** target ~150 lines, hard cap ~250. Testable WHAT only. No rationale paragraphs, no design prose, no implementation hints. Cross-feature concerns → `architecture.md`. Per-feature decisions → sibling `decisions.md`.

## Metadata

- **Mode:** Light / Comprehensive
- **Created:** YYYY-MM-DD
- **Analyst Session:** [link or reference]

## Summary

[1-3 sentence description of what the user wants]

## User Personas

[Light mode: skip. Comprehensive: 1-3 personas with goals/pain points]

## User Stories

### Story 1: [Title]

**As a** [role]
**I want** [action]
**So that** [benefit]

**Acceptance Criteria:**

- Given [context], When [action], Then [outcome]
- Given [context], When [action], Then [outcome]

## Non-Functional Requirements

- **Performance:** [e.g., page load < 2s]
- **Security:** [e.g., input validation, auth required]
- **Accessibility:** [e.g., WCAG 2.1 AA]
- **Other:** [scalability, i18n, etc.]

## Constraints

- [Technical, business, or regulatory constraints]

## Success Metrics

- [How do we know this feature succeeded?]

## Out of Scope

- [Explicitly NOT included — prevents scope creep]

## Open Questions

- [ ] [Questions that need answers before architecture]

## Handoff to Sophie (Architect)

- **Feature complexity:** [Simple/Medium/Complex]
- **New architectural patterns needed:** [Yes/No — brief description]
- **Key technical decisions needed:** [list]
- **User-confirmed priorities:** [list]
