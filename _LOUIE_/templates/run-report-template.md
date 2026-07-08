# Run Report: [Feature / Fix Title]

> **Layout:** feature-scoped agentic runs write this to `_LOUIE-output/implementations/<feature>/run-report.md` (overwritten per run — git history keeps prior ones). Cross-cutting bugfixes write `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>-run-report.md`. Only agentic runs (`--agentic`) produce this file; interactive runs present the same content in chat instead.

**Status:** completed | needs-human | blocked
**Command:** [e.g. louie-feature --agentic]
**Date:** YYYY-MM-DD
**Pending decision:** — [only when `needs-human`: one line stating the question a human must answer]

<!-- The header above is the machine-readable contract — orchestrators branch on Status
     without parsing the prose below. Keep the field names and order exactly as-is. -->

## What was requested

[2-4 lines: the task as it arrived — from the invocation, or the adapter concept.]

## Tom — playback and assumptions

[The playback that would have been spoken: 5-10 bullets of what the task was understood to mean.]

**Assumptions made** (low-stakes gaps filled without asking — also recorded in `requirements.md` § Assumptions):

- [assumption + why it was safe to make]

**Open questions** (only when `needs-human`): [the scope-defining gaps that halted the run]

## Sophie — architecture decision

[No changes needed + how the feature maps / what minimal changes were auto-applied / the material change that tripped the wire.]

## Leo — UI direction

[Only for UI features: the direction chosen and the key UX decisions. Omit the section for backend-only work.]

## Max — review outcome

[Rounds run, criticals/should-fixes resolved, deferred Suggestions. Same line as the feature.md Change History entry, plus anything a reviewer should know.]

## Ava — tests and ship recommendation

[Test result, coverage notes, ship/no-ship recommendation.]

## Files changed

[Bullet list of files touched, one line each.]

## Follow-up tasks

[Anything the run could not or must not do: split-off features awaiting their own run, deferred Suggestions, the merge decision itself. Empty is fine — say "None."]

## For the human reviewer

The work is committed but **not merged** — that decision is yours (Critical Rule #3). Review the diff and this report; follow-up changes go through `louie-update` / `louie-bugfix` / `louie-extend` as usual. To resume a `needs-human` run after answering the pending decision: `louie-continue <feature>`.
