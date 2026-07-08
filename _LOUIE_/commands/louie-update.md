# louie-update

When the user says **`louie-update`**, follow this procedure for small, contained changes that don't warrant the full feature chain.

This is the fast lane — no Tom interview, no Sophie architecture eval, no Ava test pass. Implementation runs straight through, followed by a **slim Max review** and a focused spec sync.

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

6. **Slim Max review:**
   - Read and follow `_LOUIE_/agents/reviewer.md` — invoke Max in **Slim Mode**
   - Scope is intentionally narrow: file-size limit (800 lines), security baseline (no secrets, input validation at boundaries), and "does the diff actually match what the user asked for?"
   - Max produces a single flat list of findings in chat — no three-tier structure
   - If Max flags anything critical, fix it and re-run the quality check before proceeding to spec sync
   - If Max finds nothing actionable, say so explicitly and move on

7. **Sync the specs:**
   Only touch what the change actually affected. Don't write spec updates that aren't needed.
   - **Always:** append a Change History entry to `_LOUIE-output/implementations/[feature-name]/feature.md`: `YYYY-MM-DD: [Brief change description] (louie-update, slim review)`
   - **If code snippets or the structure section in `feature.md` reference the changed code:** update them to match
   - **If observable behavior shifted** (new validation, changed default, new field exposed, error message wording that other docs/tests reference): append a short "Update: <date>" note to `_LOUIE-output/implementations/[feature-name]/requirements.md`
   - **If the change touched env vars, ports, external services, or operator commands:** update `_LOUIE-output/runbook.md`. Implementation learnings (framework quirks, cache rules) go in a code-local `// WHY` comment instead — the runbook does not carry a gotchas list.
   - **If a non-trivial decision was made** (e.g. picked one approach over another for a real reason): append an ADR to `_LOUIE-output/implementations/[feature-name]/decisions.md` (create from `_LOUIE_/templates/decisions-template.md` if absent)
   - **If feature status changed** (e.g. moved from In Development to Implemented): update the feature's `Status` column in `_LOUIE-output/implementations/overview.md` to mirror the `feature.md` checkboxes

8. **Generate a commit message:**
   ```
   fix: <brief description of the change>
   ```

## Auto-Pilot

Auto-pilot has **thin leverage here** — `louie-update` is already the fast lane with no Tom/Sophie/Leo gates and no plan-approval step. There is nothing to make unattended that isn't already. See `_LOUIE_/commands/louie-autopilot-mode.md`.

What the `update:` toggle (or a `--auto`/`--manual` flag) does:
- The slim Max review (Step 6) runs as a **loop** — flag criticals, hand to Nina, re-run the quality check, re-review — rather than a single pass, matching the `auto-fix-critical` floor. (Slim review already auto-fixes criticals before spec sync; auto-pilot just makes the re-review explicit.)
- **The 50-line escalation rule below still fires** under auto-pilot — it's the deviation tripwire for this command. Auto-pilot does not let an update that has grown into an extension run silently.

Resolution order is the same as the other commands: `--auto`/`--manual` flag > `runbook.md` `## Auto-Pilot` `update:` value (default `off`).

## Agentic

When invoked with `--agentic`, an autonomous agent is driving (full contract: `_LOUIE_/workflow/agentic-mode.md`). Thin here, like auto-pilot:

- Auto-pilot is implied `on` (slim Max review runs as a loop). `--agentic --manual` is a contradiction — stop.
- **The feature must resolve without a prompt** (Step 2): if the invocation doesn't name it unambiguously, write a run report with `status: needs-human` and stop.
- **The 50-line escalation halts instead of asking:** write the run report with `status: needs-human` recommending `louie-extend --agentic`, leave the work uncommitted-but-intact, and stop. Same for a real bug surfacing mid-review — report `needs-human` recommending `louie-bugfix` rather than switching flows on your own.
- On completion, write the run report to `_LOUIE-output/implementations/<feature>/run-report.md` (`status: completed`); the commit-message step still runs, the commit/merge decision stays human.

## Escalation Rule

**If the change grows beyond 50 lines during implementation → STOP.**

Tell the user:

> "This change is bigger than expected — it's touching [X lines / Y files]. I'd recommend switching to `louie-extend` so we get proper requirements, a full review from Max, and tests from Ava. Want me to switch?"

Do not continue a simple update that has grown complex. The 50-line limit exists to catch scope creep early.

**If the slim review surfaces a real bug** (not a code-quality issue), drop into `louie-bugfix` — don't try to patch it inside the update flow.

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
