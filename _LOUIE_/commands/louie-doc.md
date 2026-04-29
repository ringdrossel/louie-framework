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
   - **Overview** (`_LOUIE-output/implementations/overview.md`) — update feature table if status changed
   - **Architecture** (`_LOUIE-output/architecture.md`) — update if new patterns, layers, or integration points were introduced
   - **Tech stack** (`_LOUIE-output/tech-stack.md`) — update if new libraries or tools were added

4. **Update the documentation:**
   - Read each affected document before modifying it
   - Add Change History entries with today's date
   - Update status fields (Planned → In Development → Implemented → Tested)
   - Update code structure sections with actual files created/modified
   - Add key interfaces/types if they were implemented
   - Keep updates factual and concise — document what IS, not what might be

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
