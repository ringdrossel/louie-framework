# Agent Handoff Protocol

Agents pass work through a hybrid model: **persistent files** + **handoff summaries**.

Each agent produces a canonical document (requirements, architecture, feature doc, etc.) and ends it with a short handoff summary for the next agent. This way the next agent can read the full document for detail and the handoff section for quick orientation.

---

## Handoff Chain

```
Tom (Analyst) → Sophie (Architect) → Leo (Designer, if UI) → Nina (Coder) → Max (Reviewer) → Ava (Tester)
```

Ivy (Muse) operates independently — her output goes back to the user, who may then engage Tom.

---

## Handoff Summary Format

Every agent ends its canonical document with:

```markdown
## Handoff to [Next Agent Name]

- **Key context:** [what they need to know]
- **Decisions made:** [bullet list]
- **Open items:** [questions or risks]
- **Files to read:** [paths]
```

Keep it concise — 5-10 bullet points max. The full document is there for deep context; the handoff is a quick-start guide for the next agent.

---

## Canonical Files by Agent

| Agent | Produces | Reads |
|-------|----------|-------|
| **Tom** (Analyst) | `_LOUIE-output/implementations/[feature]/requirements.md` | `_LOUIE-output/implementations/overview.md` |
| **Sophie** (Architect) | `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, `_LOUIE-output/runbook.md` | Requirements docs (in each feature folder) |
| **Leo** (Designer) | UI section in `[feature]/feature.md` | Requirements, architecture, tech-stack |
| **Nina** (Coder) | `_LOUIE-output/implementations/[feature]/feature.md`, source code, optionally `[feature]/decisions.md`, and on bugfixes `[feature]/bugfixes/<date>-<slug>.md` (or top-level `_LOUIE-output/bugfixes/` for cross-cutting) plus a row in `_LOUIE-output/bugfixes/overview.md` | All docs + guidelines |
| **Max** (Reviewer) | Review comments on `[feature]/feature.md` | Feature folder (`feature.md`, `requirements.md`, `decisions.md`, recent `bugfixes/`), source code, guidelines |
| **Ava** (Tester) | Test files, coverage notes in `[feature]/feature.md` | Feature folder, source code, guidelines |
| **Ivy** (Muse) | Idea list (returned to user) | Overview, architecture, tech-stack, per-feature folders |

---

## When to Skip Agents

- **Skip Sophie (Architect)** if a new feature fits the existing architecture — Sophie self-assesses on second+ runs and will say "no changes needed" if everything fits
- **Skip Leo (Designer)** for backend-only features with no UI component
- **Never skip Nina, Max, or Ava** — every change gets implemented, reviewed, and tested
- **Never skip Tom** — even "obvious" features benefit from structured requirements (use Light Mode for simple ones)

---

## Handling Handoff Conflicts

If an agent finds that a previous agent's output is incomplete, contradictory, or raises new questions:

1. **Note the issue** in the current document's Open Questions section
2. **Ask the user** for clarification — don't silently resolve ambiguity
3. **Don't modify another agent's document** — each agent owns their own output
4. If the issue is significant, recommend the user re-engage the previous agent
