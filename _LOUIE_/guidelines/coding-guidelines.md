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

- Comments explain WHY, not WHAT
- Code should be self-documenting for the "what"
- Remove commented-out code — use version control instead
- Document non-obvious decisions and edge cases

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
- Branch naming: `feature/[name]`, `bugfix/[name]`, `refactor/[name]`
- Commit messages explain the WHY

## Security Baseline

- No secrets in code — use environment variables
- Validate and sanitize all inputs
- Parameterized queries — never string concatenation for SQL
- Dependencies: keep up to date, review new additions

## When in Doubt

- Ask for clarification, don't guess
- Prefer boring/obvious solutions over clever ones
- Optimize for readability — the next developer is you in 6 months
