# Bug Fix: [Title]

> **Layout:** per-feature fixes live at `_LOUIE-output/implementations/<feature>/bugfixes/<YYYY-MM-DD>-<slug>.md`. Cross-cutting fixes that touch multiple features live at `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>.md` (top-level). Either way, the cross-project index in `_LOUIE-output/bugfixes/overview.md` must be updated.

## Metadata

- **Feature:** [feature-slug] (or "cross-cutting" with a list of affected features)
- **Date:** YYYY-MM-DD
- **Severity:** Critical / High / Medium / Low
- **Reporter:** [user / system / Nina-during-feature-work]
- **Fixed By:** [implementer]

## Symptoms

[What the user or system observed when the bug manifested. Be specific — error messages, conditions, frequency, the exact misbehavior.]

## Root Cause

[The actual cause, not just the symptom. Walk through the code path that produced the bug. If the cause was a misunderstanding of an upstream contract or a missing edge case, say so.]

## Fix

[What was changed. Reference files and line ranges where helpful. Keep it concise — the diff is the source of truth, this is the narrative.]

## Regression Test

[Reference the regression test that prevents this bug from returning. Include the test file path and the test name. If no regression test was added, say why explicitly.]

## Runbook Update

[If this fix produced a Common Gotchas entry in `_LOUIE-output/runbook.md`, link to or quote the entry. Bugfixes are the highest-value runbook content — this section should rarely be empty.]

## Related

- **Feature doc:** `_LOUIE-output/implementations/[feature]/feature.md`
- **Linked fixes:** [if any — e.g., "fix at YYYY-MM-DD-<slug>.md uncovered this one", "regressed YYYY-MM-DD-<slug>.md"]
