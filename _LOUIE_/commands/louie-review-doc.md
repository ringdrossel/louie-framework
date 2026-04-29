# louie-review-doc

When the user says **`louie-review-doc`**, run a code review followed by documentation updates — in one flow.

This combines `louie-review` and `louie-doc` into a single command. Max reviews the code, issues get fixed, then documentation is updated and a commit message is generated.

## Procedure

### Phase 1: Review (Max)

1. **Read project context:**
   - Read `_LOUIE-output/architecture.md`, `_LOUIE-output/tech-stack.md`, and `_LOUIE-output/runbook.md`
   - Read `_LOUIE_/guidelines/coding-guidelines.md`

2. **Determine what to review:**
   - If the user specified a feature or files alongside the command, use that scope
   - If not, check for recent changes (uncommitted changes, recent commits) and ask: "What would you like me to review? A specific feature, recent changes, or particular files?"

3. **Read the relevant feature folder:**
   - Find and read `_LOUIE-output/implementations/[feature-name]/feature.md` if applicable
   - Skim sibling files: `requirements.md`, `decisions.md`, recent `bugfixes/*`

4. **Invoke Max (Reviewer):**
   - Read and follow `_LOUIE_/agents/reviewer.md`
   - Max reviews against architecture, guidelines, and the feature document
   - Max produces findings: Critical / Should Fix / Suggestions

5. **Fix issues:**
   - If Max found Critical or Should Fix issues, invoke Nina (Coder) to address them
   - Read and follow `_LOUIE_/agents/coder.md` for fixes
   - Re-review if critical issues were found to confirm they're resolved

### Phase 2: Documentation (after review is clean)

6. **Determine which documents need updating:**
   - Feature document (`_LOUIE-output/implementations/[feature]/feature.md`) — update status, code structure, change history
   - Decisions (`_LOUIE-output/implementations/[feature]/decisions.md`) — append ADR if a non-trivial decision was made
   - Overview (`_LOUIE-output/implementations/overview.md`) — update feature table if status changed
   - Bug fixes overview (`_LOUIE-output/bugfixes/overview.md`) — confirm any bug fixes are indexed
   - Architecture / tech stack — update if new patterns or libraries were introduced
   - Runbook (`_LOUIE-output/runbook.md`) — update if new ports / commands / env vars / external services were added, or if Max found gotchas Nina missed

7. **Update the documentation:**
   - Add Change History entries with today's date
   - Update status fields
   - Update code structure sections with actual files
   - Keep updates factual and concise

8. **Show a summary:**
   - **Review results:** what Max found and what was fixed
   - **Docs updated:** which files changed and what was added
   - Highlight any open questions or gaps

9. **Generate a commit message:**
   ```
   feat: <brief description>

   Review:
   - <key findings and fixes>

   Docs:
   - <documents updated and why>
   ```

## Usage

```
louie-review-doc
```

or with a specific scope:

```
louie-review-doc user-authentication
```

or after finishing implementation:

```
louie-review-doc
Just finished the payment integration feature.
```
