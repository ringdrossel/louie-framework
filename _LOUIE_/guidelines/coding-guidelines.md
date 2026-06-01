# Coding Guidelines

These guidelines apply to ALL code in this project, regardless of language or framework. Every agent (Coder, Reviewer, Tester, Designer) reads this file before working.

## File Organization

- **Max 800 lines per file** — Flag for refactoring if exceeded. Critical violation during review.
- **Single Responsibility Principle** — one reason to change per module
- **Group by feature, not by type** — prefer `user/UserService.ts` over `services/UserService.ts`

## Functions & Methods

- Do one thing
- Ideal length: < 30 lines
- Max parameters: 3–4 (use object/record for more)
- Pure functions where possible
- Early returns over nested conditionals

## Naming

- **Meaningful names over comments** — `calculateTotalAfterTax()` not `calc()` + comment
- **Booleans**: `is/has/can/should` prefixes
- **Constants**: UPPER_SNAKE_CASE
- **No abbreviations** except industry standards (URL, API, ID)

## DRY (Don't Repeat Yourself)

- Extract repeated logic after the second occurrence
- Shared types/interfaces in dedicated files
- Avoid copy-paste modifications

## Comments

- **Default to no comment.** Code should be self-documenting via good names and small functions. A comment is a last resort, not a habit.
- **One short line max** when a comment is genuinely needed — explains the WHY (a hidden constraint, a subtle invariant, a workaround for a specific bug, behaviour that would surprise a reader).
- **Never** write multi-line comment blocks, multi-paragraph docstrings, ASCII-art section headers, or "orientation" comments that summarise what the next 20 lines do — split or rename instead.
- **Never** restate WHAT the code does ("loops over users", "calls the API", "returns the result").
- **Never** reference the current task, ticket, fix, or callers ("added for issue #42", "used by the shelf page") — that belongs in `git log` / the PR / `decisions.md`, not in the file.
- Rationale paragraphs, design discussion, and "I chose X because Y" go in `_LOUIE-output/implementations/<feature>/decisions.md` (ADRs), not in code comments.
- Remove commented-out code — use version control instead.

## Error Handling

- Fail fast with clear error messages
- Never swallow exceptions silently
- Validate inputs at boundaries
- Use typed errors where the language supports it

## Testing

- **Test naming**: `should [expected behavior] when [condition]`
- **AAA pattern**: Arrange / Act / Assert
- One logical assertion per test when possible
- Mock external dependencies (DB, APIs, file system)
- Test edge cases: empty inputs, nulls, auth failures, limits

## Frontend-Specific (when applicable)

- Components under 200 lines
- Composition over prop drilling
- Extract reusable components after the second use
- Single responsibility per component
- Accessibility: semantic HTML, ARIA labels, keyboard navigation

## Backend-Specific (when applicable)

- Thin controllers, fat services
- Repository pattern for data access (if architecture calls for it)
- Input validation at API boundary
- Never trust client input
- Log at appropriate levels (debug/info/warn/error)

## Git Discipline

- Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Commit messages explain the WHY
- **Branching is governed by Branch Mode** (`_LOUIE-output/runbook.md` § Branch Mode). Default is `current` — work on the branch you're already on, including `main`; LOUIE never creates a branch on its own. When a branch is used, name it `feature/[name]`, `bugfix/[name]`, or `refactor/[name]`. See `_LOUIE_/commands/louie-branch-mode.md`.
- **When work is on a feature branch, merge to `main` after review, with user confirmation.** Once Max's review passes and Ava's tests are green, ask the user for explicit permission to merge. On approval, fast-forward the branch into `main` and push. Never merge without asking; never skip the ask because the change "looks safe". (This gate is inert when you're already committing on `main` under `current` mode.)

## Security Baseline

- No secrets in code — use environment variables
- Validate and sanitize all inputs
- Parameterized queries — never string concatenation for SQL
- Dependencies: keep up to date, review new additions

## When in Doubt

- Ask for clarification, don't guess
- Prefer boring/obvious solutions over clever ones
- Optimize for readability — the next developer is you in 6 months
