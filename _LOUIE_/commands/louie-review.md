# louie-review

When the user says **`louie-review`**, invoke Max (Reviewer) to review code.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`
   - Read `_LOUIE_/guidelines/coding-guidelines.md`

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

5. **If issues are found:**
   - Present Max's review to the user
   - If the user wants fixes applied, invoke Nina (Coder) to address the findings
   - Re-review if critical issues were found

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
