# louie-update

When the user says **`louie-update`**, follow this procedure for small, contained changes that don't warrant the full feature chain.

This is the fast lane — no Tom interview, no Sophie architecture eval, no Max review. Just implement, verify, and document.

## When to Use

This command is for changes that are:

- Under 50 lines of code affected
- Contained within one feature's scope
- Low risk and straightforward

**Examples:** adjusting a default value, adding a simple validation, tweaking UI styling/layout, adding a single field to an entity, fixing a small bug, updating error messages, renaming a label.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/implementations/overview.md`
   - Read `_LOUIE-output/tech-stack.md` — know which build/lint commands to run
   - Read `_LOUIE_/guidelines/coding-guidelines.md`

2. **Identify the feature:**
   - If the user specified the feature alongside the command, open its folder at `_LOUIE-output/implementations/[feature-name]/`
   - If not, ask: "Which feature does this change belong to?"
   - Read `feature.md` completely

3. **Verify the change is truly simple:**
   - Estimate lines of code affected
   - If likely **under 50 lines** → proceed
   - If likely **over 50 lines** → STOP and tell the user: "This looks bigger than a simple update. I'd recommend running `louie-extend` instead to get proper requirements and a review."

4. **Implement the change:**
   - Follow `_LOUIE_/guidelines/coding-guidelines.md`
   - Keep it minimal — change only what's needed, nothing more

5. **Quality check:**
   - Run the project's build command (from `tech-stack.md`)
   - Run the project's linter (from `tech-stack.md`)
   - Verify no file exceeds 800 lines
   - If quality check fails, fix before proceeding

6. **Update the feature document:**
   - Add to Change History in `_LOUIE-output/implementations/[feature-name]/feature.md`: `YYYY-MM-DD: [Brief change description]`
   - Update code snippets or structure sections if relevant

7. **Generate a commit message:**
   ```
   fix: <brief description of the change>
   ```

## Escalation Rule

**If the change grows beyond 50 lines during implementation → STOP.**

Tell the user:

> "This change is bigger than expected — it's touching [X lines / Y files]. I'd recommend switching to `louie-extend` so we get proper requirements, a review from Max, and tests from Ava. Want me to switch?"

Do not continue a simple update that has grown complex. The 50-line limit exists to catch scope creep early.

## Usage

```
louie-update
```

or with context:

```
louie-update user-authentication
Change the password minimum length from 8 to 12 characters.
```

or with multiple small changes to one feature:

```
louie-update dashboard
- Change default date range from 7 days to 30 days
- Update the "no data" empty state message
```
