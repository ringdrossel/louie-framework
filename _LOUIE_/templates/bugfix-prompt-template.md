# Bug Fix Prompt Template

```
CONTEXT:
- Read _LOUIE-output/architecture.md — understand the system structure
- Read _LOUIE_/guidelines/coding-guidelines.md — follow the rules while fixing
- Read _LOUIE-output/implementations/overview.md — find the affected feature
- Find and read the affected feature document in _LOUIE-output/implementations/

Bug in Feature: [Feature-Name]
Problem: [Brief description of the bug]

PROCEDURE:
1. Identify the feature document
2. Read the feature document completely
3. Analyze the problem
4. Fix the bug (following coding guidelines)
5. Run linter and tests to verify the fix
6. Update change history in feature document:
   - YYYY-MM-DD: Bug fix — [Description]
7. Have Max (Reviewer) review the fix
```
