# louie-review

When the user says **`louie-review`**, invoke Max (Reviewer) to review code.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`
   - Read `_LOUIE_/guidelines/coding-guidelines.md`
   - **Determine the review mode** (see "Review Mode" section below). This decides whether Max stops for approval or auto-hands fixes to Nina in a loop.

2. **Determine what to review:**
   - If the user specified a feature or files alongside the command, use that scope
   - If not, check for recent changes (uncommitted changes, recent commits) and ask: "What would you like me to review? A specific feature, recent changes, or particular files?"

3. **Read the relevant feature folder:**
   - Find and read `_LOUIE-output/implementations/[feature-name]/feature.md` if a specific feature is being reviewed
   - Skim sibling files: `requirements.md`, `decisions.md`, recent `bugfixes/*` — they give Max the full context of what was intended and prior history

4. **Invoke Max (Reviewer):**
   - Read and follow `_LOUIE_/agents/reviewer.md`
   - Max reviews the code against:
     - The feature document (does the code match the plan?)
     - The architecture (does it follow the patterns?)
     - The coding guidelines (800-line limit, SRP, naming, etc.)
     - Security baseline (no secrets, input validation, etc.)
     - Runbook coverage (new ports / commands / env vars / gotchas reflected in `runbook.md`?)
   - Max produces findings in three tiers: Critical / Should Fix / Suggestions
   - Max also calls out good code

5. **If issues are found — behavior depends on mode:**
   - **`manual` mode** — Present Max's review to the user **in chat** (do not write a separate review file anywhere in `_LOUIE-output/`; the review is session-time output, see `_LOUIE_/agents/reviewer.md` Storage convention). If the user wants fixes applied, invoke Nina (Coder) to address the findings. Re-review if critical issues were found.
   - **`auto-fix-critical` mode** — Present the review in chat as a status update, then proceed without asking: hand the `Critical` + `Should Fix` findings to Nina, who applies them, re-runs typecheck / tests / build per `_LOUIE-output/tech-stack.md`, and hands back to Max. Max re-reviews the diff and re-enters this step. Loop until no Critical or Should Fix remain, or the loop cap is reached. After the loop ends, present any remaining `Suggestions` and ask before applying them. See `_LOUIE_/agents/reviewer.md` § Auto-Fix Loop for the full protocol (cap, regression guard, fallback).
   - **`auto-fix-all` mode** — Same loop as `auto-fix-critical`, but `Suggestions` are also auto-applied inside the loop. No final approval prompt.

6. **Record the outcome:**
   - Append a single entry to `_LOUIE-output/implementations/[feature-name]/feature.md` Change History. Format depends on mode:
     - `manual`: `YYYY-MM-DD: Max review — addressed N critical, N should-fix; suggestions deferred.`
     - `auto-fix-critical` / `auto-fix-all`: `YYYY-MM-DD: Max review (<mode>) — N rounds, N critical + N should-fix resolved, N suggestions <deferred|applied>.`
   - If the review accepted a non-trivial decision, append an ADR to `[feature-name]/decisions.md` (create from `_LOUIE_/templates/decisions-template.md` if absent).
   - If the review surfaced a real bug (not a code-quality issue), drop into the `louie-bugfix` flow — don't try to capture the bug fix in the review record.

## Review Mode

`louie-review` reads the project-wide review mode from `_LOUIE-output/runbook.md` under the `## Review Mode` section. Three modes are supported (see `_LOUIE_/commands/louie-review-mode.md` for full descriptions):

- `manual` (default if unset) — Max asks before fixing
- `auto-fix-critical` — auto-applies Critical + Should Fix in a loop; Suggestions surface at the end
- `auto-fix-all` — auto-applies everything in the loop

**Per-call override.** If the first non-empty argument is one of `manual`, `auto`, `auto-fix-critical`, or `auto-fix-all`, use it as the mode for this invocation only. `auto` is an alias for `auto-fix-critical`. The override **does not** update the runbook — it applies to this call only. To change the project-wide setting, use `louie-review-mode`.

If the project's runbook does not have a `## Review Mode` section yet and no per-call override is given, default to `manual` and tell the user once: "Review mode not set — defaulting to manual. Run `louie-review-mode` to change it project-wide."

## Usage

```
louie-review
```

or with a specific scope:

```
louie-review user-authentication
```

or for specific files:

```
louie-review
Please review src/services/auth.ts and src/controllers/login.ts
```

or with a one-time mode override:

```
louie-review auto                  # one-off auto-fix-critical run
louie-review manual                # one-off manual run on an auto-mode project
louie-review auto-fix-all          # one-off "fix everything"
louie-review auto user-authentication   # override + scope
```
