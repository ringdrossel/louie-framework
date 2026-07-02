# louie-doc

When the user says **`louie-doc`**, follow this procedure to update project documentation.

## Procedure

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`
   - Read `_LOUIE_/workflow/ai-workflow.md` for the documentation workflow
   - Read `_LOUIE-output/implementations/overview.md` if it exists

2. **Determine what changed:**
   - If the user described what changed alongside the command, use that
   - If not, check recent git changes (`git diff`, `git log`) to understand what was modified
   - Ask the user for context if the changes aren't clear from the diff

3. **Identify which documents need updating:**
   - **Feature document** (`_LOUIE-output/implementations/[feature]/feature.md`) — update status, code structure, change history
   - **Decisions** (`_LOUIE-output/implementations/[feature]/decisions.md`) — append a new ADR if a non-trivial decision was made (create from `_LOUIE_/templates/decisions-template.md` if absent)
   - **Bug fixes overview** (`_LOUIE-output/bugfixes/overview.md`) — if any bug fixes landed, ensure the index is current
   - **Overview** (`_LOUIE-output/implementations/overview.md`) — update the feature's `Status` column if status changed (see the reconcile pass in step 4a)
   - **Architecture** (`_LOUIE-output/architecture.md`) — update if new patterns, layers, or integration points were introduced
   - **Tech stack** (`_LOUIE-output/tech-stack.md`) — update if new libraries or tools were added

4. **Update the documentation:**
   - Read each affected document before modifying it
   - Add Change History entries with today's date
   - Update status fields (Planned → In Development → Implemented → Tested)
   - Update code structure sections with actual files created/modified
   - Add key interfaces/types if they were implemented
   - Keep updates factual and concise — document what IS, not what might be

4a. **Reconcile the overview Status column (drift-healing pass):**
   - The `Status` column in `_LOUIE-output/implementations/overview.md` mirrors each feature's own `feature.md` checkboxes — those checkboxes are the source of truth. Drift happens when a chain step was skipped.
   - For every row in the Features table, read the linked `implementations/<feature>/feature.md`, take the highest ticked checkbox (`Planned` < `In Development` < `Implemented` < `Tested`), and set the row's `Status` to match. Report any rows you corrected.
   - **Legacy layout:** if the overview still uses the old three-table layout (`### Implemented` / `### In Development` / `### Planned`), convert it to the single **Features** table with a `Status` column as part of this pass — derive each row's Status from which table it was in (and refine from `feature.md`).
   - Update the `Last Updated:` line.

4b. **Reconcile the codebase map (if `_LOUIE-output/codebase-map.md` exists):**
   - Regenerate the mechanical columns: `Size` per domain (LOC / file counts from the current tree) and the Largest Files table.
   - Flag (don't silently delete) any row whose `Path roots` no longer match existing paths — the domain may have been renamed or removed; ask before dropping the row.
   - Check that domain names still match the `architecture.md` domain list; report any divergence.
   - Update the `Last reconciled:` line.

5. **Show a summary:**
   - List each file that was updated and what changed
   - Highlight any open questions or gaps found during documentation

6. **Generate a commit message:**
   - Format as Conventional Commits:

   ```
   docs: <brief description of what was documented>

   - <bullet point for each document updated>
   - <what specifically changed in each>
   ```

   - Present the commit message for the user to review and use

## Usage

```
louie-doc
```

or with context about what changed:

```
louie-doc
Just finished implementing the user authentication feature.
Added login, logout, and password reset endpoints.
```

or after a specific change:

```
louie-doc
We added Redis caching to the API layer — need to update
architecture and tech-stack docs.
```
