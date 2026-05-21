# louie-bugfix

When the user says **`louie-bugfix`**, follow this procedure to diagnose and fix a bug.

## Procedure

1. **Read project context:**
   - Read `_LOUIE_/templates/bugfix-prompt-template.md` — follow this structure
   - Read `_LOUIE_/templates/bugfix-template.md` — this is the output format for the bug-fix doc
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`. Then read `_LOUIE-output/bugfixes/overview.md` and the relevant feature's `bugfixes/` folder — that's where prior detect/avoid knowledge lives (the runbook no longer carries a gotchas list).
   - Read `_LOUIE_/guidelines/coding-guidelines.md`
   - Read `_LOUIE-output/implementations/overview.md` and `_LOUIE-output/bugfixes/overview.md` — understand the feature landscape and prior bug history

2. **Identify the bug:**
   - If the user described the bug alongside the command, proceed
   - If not, ask:
     - "Which feature is affected? (Or is this cross-cutting — touching multiple features?)"
     - "What's the problem? (What happens vs. what should happen)"

3. **Scope check — is this actually a bug?**
   A bug is **unintended behavior that diverges from the feature's documented or implied intent**. One issue, one fix, one regression test. If the work in front of you doesn't match that shape, stop and route it correctly:
   - **Multiple unrelated issues bundled under one umbrella** (e.g. "Chat UX Fixes" covering an icon change, a layout tweak, and an error message): STOP. Each issue is its own bugfix doc, or — if any of them adds new behavior — its own `louie-update` / `louie-extend`. Do not create a single "Fixes" doc that aggregates them; bugfix docs are not feature buckets.
   - **The work adds new functionality, controls, fields, or surfaces** rather than restoring intended behavior: this is not a bugfix. Suggest `louie-update` (under 50 lines, contained) or `louie-extend` (larger or touches requirements).
   - **The "bug" is actually a missing feature**: route to `louie-feature`.
   - **Cosmetic polish requested by the user** that wasn't broken (e.g. "make the spacing nicer"): route to `louie-update`, not `louie-bugfix`.

   When in doubt, ask the user: "This looks more like [update/extend/feature] than a bugfix because [reason]. Want me to switch?" Mislabeled bugfix docs cause real downstream confusion — a future `louie-extend` against the affected area cannot tell whether the "bugfix" is a feature or a fix.

4. **Read the affected feature folder:**
   - Read `_LOUIE-output/implementations/[feature-name]/feature.md`
   - Skim `_LOUIE-output/implementations/[feature-name]/bugfixes/` for related prior fixes
   - For cross-cutting bugs, do this for every affected feature

5. **Invoke Nina (Coder) — diagnosis and fix:**
   - Read and follow `_LOUIE_/agents/coder.md`
   - Nina analyzes the problem in the context of the feature document and architecture
   - Nina implements the fix following coding guidelines
   - Nina runs linter and tests to verify the fix
   - Nina creates the bug-fix doc using `_LOUIE_/templates/bugfix-template.md`:
     - **Per-feature fix:** `_LOUIE-output/implementations/[feature-name]/bugfixes/<YYYY-MM-DD>-<slug>.md`
     - **Cross-cutting fix:** `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>.md` (top-level)
   - Nina appends a row at the top of the appropriate table in `_LOUIE-output/bugfixes/overview.md` (Recent Fixes for per-feature; Cross-Cutting Fixes for multi-feature)
   - Nina updates `feature.md` Change History: `YYYY-MM-DD: Bug fix — [description] (see bugfixes/<file>.md)`
   - **Detect / avoid wording lives in the bugfix doc itself** (mandatory section — see `_LOUIE_/templates/bugfix-template.md`). If a future reader would need this knowledge while editing the affected code, also add a one-line `// WHY` comment next to it.
   - **Only update `runbook.md` if the fix changed operational surface** (a new env var the deploy now needs, a port behaviour change, a new first-check Debugging symptom). Most bugfixes don't — that's expected.

6. **Invoke Max (Reviewer) — review the fix:**
   - Read and follow `_LOUIE_/agents/reviewer.md`
   - Max reviews the fix for correctness, side effects, and guideline compliance
   - If changes are needed, Nina fixes them

7. **Invoke Ava (Tester) — verify and cover:**
   - Read and follow `_LOUIE_/agents/tester.md`
   - Ava verifies the fix with a targeted test
   - Ava adds a regression test to prevent the bug from returning

## Usage

```
louie-bugfix
```

or with context upfront:

```
louie-bugfix user-authentication
The password reset email link expires immediately instead of after 24 hours.
```
