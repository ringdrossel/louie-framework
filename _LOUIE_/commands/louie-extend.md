# louie-extend

When the user says **`louie-extend`**, follow this procedure to extend an existing feature.

> **Reset context before you start.** Ignore any framing from prior work in this session (bugfix mode, update mode, etc.). You are extending a feature. Verify the target against the steps below — don't trust your prior mental model of what the target is.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`
   - Read `_LOUIE-output/implementations/overview.md` to see existing features

2. **Identify the feature to extend:**
   - If the user specified which feature alongside the command, find its folder at `_LOUIE-output/implementations/[feature-name]/`
   - If not, show the list of existing features from `overview.md` and ask: "Which feature would you like to extend?"

3. **Precondition check — is this actually a feature?**
   - The target **must** be a feature folder containing `feature.md` at `_LOUIE-output/implementations/[feature-name]/feature.md`
   - If `feature.md` does not exist for the named target, STOP and do not improvise. Check what the name actually matches:
     - **Matches only a bugfix doc** (e.g. `_LOUIE-output/bugfixes/<date>-<name>.md` or `implementations/<other>/bugfixes/<date>-<name>.md`): tell the user **"Bugfixes are not extended."** Then offer three options:
       1. If this is new functionality → run `louie-feature` to create a proper feature
       2. If this restores intended behavior of an existing feature → run `louie-bugfix` against that feature
       3. If a real feature underlies the work but lacks a folder → run `louie-feature` first to give it one, then come back to `louie-extend` against it
     - **Matches nothing** (typo or genuinely missing): show the feature list from `overview.md` and ask the user to pick one
     - **Ambiguous** (multiple plausible matches): list them and ask the user to disambiguate
   - Do **not** create a feature folder on the fly inside `louie-extend`. Feature folders are owned by `louie-feature`.

4. **Read the existing feature folder:**
   - Read `_LOUIE-output/implementations/[feature-name]/feature.md` completely
   - Read `_LOUIE-output/implementations/[feature-name]/requirements.md` if it exists
   - Skim `_LOUIE-output/implementations/[feature-name]/decisions.md` and `bugfixes/` for context (prior ADRs, recent bug history)

5. **Ask what the extension should do:**
   - If the user already described the extension, proceed
   - If not, ask: "What would you like to add or change in this feature?"

6. **Invoke Tom (Analyst) — Light Mode recommended:**
   - Read and follow `_LOUIE_/agents/analyst.md`
   - Tom interviews about the extension (Light Mode is usually sufficient for extensions)
   - Tom appends an "Extension: <date>" section to `_LOUIE-output/implementations/[feature-name]/requirements.md` rather than creating a new file. This keeps all requirements for one feature in one document.

7. **Invoke Sophie (Architect) — evaluation:**
   - Read and follow `_LOUIE_/agents/architect.md`
   - Sophie evaluates if the extension fits the existing architecture
   - If changes are needed, get user confirmation before updating docs

8. **Update the feature document:**
   - Add a new implementation phase to `_LOUIE-output/implementations/[feature-name]/feature.md`
   - Add a Change History entry
   - If a new ADR was made for the extension, append it to `_LOUIE-output/implementations/[feature-name]/decisions.md` (create from template if absent)
   - Update the feature's `Status` column in `_LOUIE-output/implementations/overview.md` if the status changed (mirror the `feature.md` checkboxes)

9. **Confirmation gate:**
   - Show the user the updated feature document and extension plan
   - Wait for explicit confirmation before coding

10. **Continue the chain:**
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
