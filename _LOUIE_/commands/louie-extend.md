# louie-extend

When the user says **`louie-extend`**, follow this procedure to extend an existing feature.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`
   - Read `_LOUIE-output/implementations/overview.md` to see existing features

2. **Identify the feature to extend:**
   - If the user specified which feature alongside the command, find its feature document in `_LOUIE-output/implementations/`
   - If not, show the list of existing features from `overview.md` and ask: "Which feature would you like to extend?"

3. **Read the existing feature document:**
   - Read `_LOUIE-output/implementations/[feature-name].md` completely
   - Read the original requirements from `_LOUIE-output/requirements/[feature-name]-requirements.md` if it exists

4. **Ask what the extension should do:**
   - If the user already described the extension, proceed
   - If not, ask: "What would you like to add or change in this feature?"

5. **Invoke Tom (Analyst) — Light Mode recommended:**
   - Read and follow `_LOUIE_/agents/analyst.md`
   - Tom interviews about the extension (Light Mode is usually sufficient for extensions)
   - Tom produces updated or new requirements: `_LOUIE-output/requirements/[feature-name]-extension-requirements.md`

6. **Invoke Sophie (Architect) — evaluation:**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie evaluates if the extension fits the existing architecture
   - If changes are needed, get user confirmation before updating docs

7. **Update the feature document:**
   - Add a new implementation phase to `_LOUIE-output/implementations/[feature-name].md`
   - Add a Change History entry
   - Update `overview.md` if the feature status changes

8. **Confirmation gate:**
   - Show the user the updated feature document and extension plan
   - Wait for explicit confirmation before coding

9. **Continue the chain:**
   - Leo (Designer) if the extension has UI changes
   - Nina (Coder) implements
   - Max (Reviewer) reviews
   - Ava (Tester) tests

## Usage

```
louie-extend
```

or with context upfront:

```
louie-extend user-authentication
Add OAuth2 support for Google and GitHub login alongside the existing
email/password authentication.
```
