# louie-bugfix

When the user says **`louie-bugfix`**, follow this procedure to diagnose and fix a bug.

## Procedure

1. **Read project context:**
   - Read `_LOUIE_/templates/bugfix-prompt-template.md` — follow this structure
   - Read `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`
   - Read `_LOUIE_/guidelines/coding-guidelines.md`
   - Read `_LOUIE-output/implementations/overview.md` to understand the feature landscape

2. **Identify the bug:**
   - If the user described the bug alongside the command, proceed
   - If not, ask:
     - "Which feature is affected?"
     - "What's the problem? (What happens vs. what should happen)"

3. **Read the affected feature document:**
   - Find and read `_LOUIE-output/implementations/[feature-name].md`
   - Understand the intended behavior, implementation plan, and code structure

4. **Invoke Nina (Coder) — diagnosis and fix:**
   - Read and follow `_LOUIE_/agents/coder.md`
   - Nina analyzes the problem in the context of the feature document and architecture
   - Nina implements the fix following coding guidelines
   - Nina runs linter and tests to verify the fix
   - Nina updates the feature document's Change History: `YYYY-MM-DD: Bug fix — [description]`

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
