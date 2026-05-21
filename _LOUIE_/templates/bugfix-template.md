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

## Detect / Avoid

[One short paragraph: how a future reader spots this bite (the observable symptom or the code shape that produces it) and how to avoid it next time. This is the canonical home for that knowledge — the runbook does not carry a gotchas list. Mandatory; do not leave empty.]

## Regression Test

[Reference the regression test that prevents this bug from returning. Include the test file path and the test name. If no regression test was added, say why explicitly.]

## Runbook Update

[Only fill in if this fix changed operational surface — a new env var the deploy now needs, a port behaviour change, a new first-check row in the Debugging table. Most bugfixes leave this empty; that is expected. Implementation-level detect/avoid wording lives in the section above, not here.]

## Related

- **Feature doc:** `_LOUIE-output/implementations/[feature]/feature.md`
- **Linked fixes:** [if any — e.g., "fix at YYYY-MM-DD-<slug>.md uncovered this one", "regressed YYYY-MM-DD-<slug>.md"]
