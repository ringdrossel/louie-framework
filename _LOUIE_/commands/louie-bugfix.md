# louie-bugfix

When the user says **`louie-bugfix`**, follow this procedure to diagnose and fix a bug.

## Procedure

1. **Read project context:**
   - Read `_LOUIE_/templates/bugfix-prompt-template.md` — follow this structure
   - Read `_LOUIE_/templates/bugfix-template.md` — this is the output format for the bug-fix doc
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md` (Common Gotchas may already document this issue or a related one)
   - Read `_LOUIE_/guidelines/coding-guidelines.md`
   - Read `_LOUIE-output/implementations/overview.md` and `_LOUIE-output/bugfixes/overview.md` — understand the feature landscape and prior bug history

2. **Identify the bug:**
   - If the user described the bug alongside the command, proceed
   - If not, ask:
     - "Which feature is affected? (Or is this cross-cutting — touching multiple features?)"
     - "What's the problem? (What happens vs. what should happen)"

3. **Read the affected feature folder:**
   - Read `_LOUIE-output/implementations/[feature-name]/feature.md`
   - Skim `_LOUIE-output/implementations/[feature-name]/bugfixes/` for related prior fixes
   - For cross-cutting bugs, do this for every affected feature

4. **Invoke Nina (Coder) — diagnosis and fix:**
   - Read and follow `_LOUIE_/agents/coder.md`
   - Nina analyzes the problem in the context of the feature document and architecture
   - Nina implements the fix following coding guidelines
   - Nina runs linter and tests to verify the fix
   - Nina creates the bug-fix doc using `_LOUIE_/templates/bugfix-template.md`:
     - **Per-feature fix:** `_LOUIE-output/implementations/[feature-name]/bugfixes/<YYYY-MM-DD>-<slug>.md`
     - **Cross-cutting fix:** `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>.md` (top-level)
   - Nina appends a row at the top of the appropriate table in `_LOUIE-output/bugfixes/overview.md` (Recent Fixes for per-feature; Cross-Cutting Fixes for multi-feature)
   - Nina updates `feature.md` Change History: `YYYY-MM-DD: Bug fix — [description] (see bugfixes/<file>.md)`
   - **Nina appends a Common Gotchas entry to `runbook.md`** capturing what went wrong, how to detect it, and how to avoid it. Bugfixes are the highest-value runbook entries — this is mandatory.

5. **Invoke Max (Reviewer) — review the fix:**
   - Read and follow `_LOUIE_/agents/reviewer.md`
   - Max reviews the fix for correctness, side effects, and guideline compliance
   - If changes are needed, Nina fixes them

6. **Invoke Ava (Tester) — verify and cover:**
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
