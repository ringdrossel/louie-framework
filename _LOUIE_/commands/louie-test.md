# louie-test

When the user says **`louie-test`**, invoke Ava (Tester) to write or improve tests.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/tech-stack.md` — know the testing frameworks in use
   - Read `_LOUIE-output/architecture.md` — understand what to mock vs. test through
   - Read `_LOUIE_/guidelines/coding-guidelines.md` — follow testing conventions

2. **Determine what to test:**
   - If the user specified a feature or files alongside the command, use that scope
   - If not, ask: "What would you like me to test? A specific feature, recent changes, or the whole project's coverage?"

3. **Read the relevant feature folder:**
   - Find and read `_LOUIE-output/implementations/[feature-name]/feature.md` if a specific feature is being tested
   - For regression tests on a bug fix, read the bug-fix doc at `<feature>/bugfixes/<date>-<slug>.md` (or `_LOUIE-output/bugfixes/` for cross-cutting)
   - Read Max's review if available — his "Key concerns for testing" section highlights focus areas

4. **Invoke Ava (Tester):**
   - Read and follow `_LOUIE_/agents/tester.md`
   - Ava writes tests following the AAA pattern and naming conventions
   - Ava covers: unit tests, integration tests, component tests, and E2E for critical flows
   - Ava focuses on edge cases, error paths, and security-sensitive operations
   - Ava provides: test files, mocking strategy, missing coverage notes, and a confidence assessment

5. **Run the tests:**
   - Execute the test suite to verify all new tests pass
   - Fix any failures before reporting results

## Usage

```
louie-test
```

or with a specific scope:

```
louie-test user-authentication
```

or for targeted testing:

```
louie-test
Write edge case tests for the password reset flow — especially
around expired tokens and rate limiting.
```
