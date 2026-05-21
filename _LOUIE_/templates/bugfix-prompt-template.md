# Bug Fix Prompt Template

```
CONTEXT:
- Read _LOUIE-output/architecture.md — understand the system structure
- Read _LOUIE_/guidelines/coding-guidelines.md — follow the rules while fixing
- Read _LOUIE-output/implementations/overview.md — find the affected feature
- Read _LOUIE-output/bugfixes/overview.md — check whether this bug or a related one has been fixed before
- Read _LOUIE-output/implementations/<feature>/feature.md for the affected feature
- Read _LOUIE-output/implementations/<feature>/bugfixes/ for prior fixes on the same feature

Bug in Feature: [Feature-Name]
Problem: [Brief description of the bug]

PROCEDURE:
1. Identify the feature folder under _LOUIE-output/implementations/
2. Read feature.md, decisions.md, and recent bugfixes/* completely
3. Analyze the problem
4. Fix the bug (following coding guidelines)
5. Run linter and tests to verify the fix
6. Create _LOUIE-output/implementations/<feature>/bugfixes/<YYYY-MM-DD>-<slug>.md
   from _LOUIE_/templates/bugfix-template.md
7. Append the new fix as a row in _LOUIE-output/bugfixes/overview.md (top of the
   Recent Fixes table)
8. Update change history in feature.md:
   - YYYY-MM-DD: Bug fix — [Description] (link to bugfixes/<YYYY-MM-DD>-<slug>.md)
9. Fill in the Detect / Avoid section of the bugfix doc (mandatory). Add a
   one-line `// WHY` comment next to the affected code if a future editor
   would need to know. Only update _LOUIE-output/runbook.md if the fix
   genuinely changed operational surface (new env var, port behaviour,
   new first-check Debugging symptom) — most fixes don't.
10. Have Max (Reviewer) review the fix
```
