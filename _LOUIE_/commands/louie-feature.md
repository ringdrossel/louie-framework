# louie-feature

When the user says **`louie-feature`**, follow this procedure to add a new feature to the project.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`
   - Read `_LOUIE-output/implementations/overview.md` if it exists
   - Read `_LOUIE_/workflow/ai-workflow.md` for the workflow

2. **Check prerequisites:**
   - If `_LOUIE-output/architecture.md` does not exist, tell the user: "No architecture defined yet. Run `louie-setup` first to set up the project foundation."
   - Do not proceed without architecture and tech stack in place.

3. **Ask for the feature idea:**
   - If the user already provided a description alongside the command, proceed directly
   - If not, ask: "What feature would you like to add? A brief description is fine — Tom will dig into the details."

4. **Invoke Tom (Analyst):**
   - Read and follow `_LOUIE_/agents/analyst.md`
   - Tom interviews the user about the new feature
   - Tom produces `_LOUIE-output/requirements/[feature-name]-requirements.md`

5. **Invoke Sophie (Architect) — evaluation:**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie evaluates whether the new feature fits the existing architecture
   - If yes: Sophie writes a brief handoff note, no document changes needed
   - If no: Sophie proposes minimal updates, gets user confirmation, updates docs

6. **Create feature document:**
   - Create `_LOUIE-output/implementations/[feature-name].md` using `_LOUIE_/templates/feature-template.md`
   - Fill in all sections based on requirements and architecture
   - Update `_LOUIE-output/implementations/overview.md` with the new feature entry

7. **Confirmation gate:**
   - Show the user the feature document and implementation plan
   - Wait for explicit confirmation before coding

8. **Invoke Leo (Designer) — if the feature has UI:**
   - Read and follow `_LOUIE_/agents/designer.md`
   - Skip this step for backend-only features

9. **Invoke Nina (Coder):**
   - Read and follow `_LOUIE_/agents/coder.md`
   - Nina implements the feature and updates the feature document

10. **Invoke Max (Reviewer):**
    - Read and follow `_LOUIE_/agents/reviewer.md`
    - If changes are needed, Nina fixes them before proceeding

11. **Invoke Ava (Tester):**
    - Read and follow `_LOUIE_/agents/tester.md`
    - Ava writes tests and gives a ship recommendation

## Usage

```
louie-feature
```

or with a description upfront:

```
louie-feature
Add user authentication with email/password login, session management,
and a password reset flow.
```
