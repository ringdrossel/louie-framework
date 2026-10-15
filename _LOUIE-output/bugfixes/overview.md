# Bug Fixes Overview

Cross-project index of every bug fix landed in this project. Per-feature fixes live in `_LOUIE-output/implementations/<feature>/bugfixes/`. Cross-cutting fixes (touching multiple features) live in `_LOUIE-output/bugfixes/`. This index aggregates both for chronological and cross-feature search.

Last Updated: YYYY-MM-DD

> **Maintenance:** Nina appends a row here whenever she lands a fix (per-feature or cross-cutting). New entries go on top of each table — reverse chronological. Old entries stay even after a feature is retired; the index is append-only.

## Recent Fixes

| Date | Feature | Severity | Title | Document |
|------|---------|----------|-------|----------|
| — | — | — | — | No fixes recorded yet |

## Cross-Cutting Fixes

Bug fixes that touched multiple features. Documents live at `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>.md` (top-level), not in any single feature's `bugfixes/` folder.

| Date | Affected Features | Severity | Title | Document |
|------|-------------------|----------|-------|----------|
| — | — | — | — | No cross-cutting fixes recorded yet |

## Notes

- The index is append-only. Don't delete entries when their feature is retired — they remain valuable history.
- For the runtime first-check view ("when this breaks at runtime, here's what to look at"), see the Debugging table in `_LOUIE-output/runbook.md`. The two are complementary: this index is the chronological log of fixes; the runbook's Debugging table is the symptom-to-first-check lookup. Per-bug *detect / avoid* knowledge lives in the bugfix doc itself, not the runbook.
