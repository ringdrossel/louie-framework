# louie-roadmap

When the user says **`louie-roadmap`**, dispatch by subcommand. The roadmap is the project's pre-feature-folder idea list — see `_LOUIE-output/roadmap.md` (lazy-created on first `add`).

## Subcommands

| Form | What it does |
|------|--------------|
| `louie-roadmap` | Print the current roadmap (Captured + Promoted). If `roadmap.md` doesn't exist, say so and suggest `louie-roadmap add`. |
| `louie-roadmap add "<title>"` | Capture a new idea. |
| `louie-roadmap promote <id>` | Hand off to `louie-feature --from-roadmap <id>`. |

Match the subcommand case-insensitively. If the user types something else (e.g. `louie-roadmap drop R-003`), tell them v1 supports only `add` and `promote` and that direct file edits cover other operations.

## Procedure

### Resolve `_LOUIE-output/roadmap.md`

- If the file does not exist and the subcommand is `add`: lazy-create it by copying `_LOUIE_/templates/roadmap-template.md` to `_LOUIE-output/roadmap.md`. Set the `Last Updated` line to today.
- If the file does not exist and the subcommand is `promote` or bare: tell the user the roadmap is empty and suggest `louie-roadmap add` first.

### `add`

1. **Get the title and notes.**
   - If the user supplied a title in quotes after `add`, use it.
   - If not, ask: "What's the idea? A short title is fine — Notes can be free text."
   - Optionally collect Notes (multi-line). If the user has nothing more to say, leave Notes empty.
   - Optionally collect Effort (`S` / `M` / `L`) if the user volunteers one. Don't infer it.

2. **Determine the Source field.**
   - `ideate` — when invoked downstream of `louie-ideate` (the ideate command will pass this through).
   - `feature-work` — when invoked mid-`louie-feature` / `louie-extend`.
   - `bugfix` — when invoked mid-`louie-bugfix`.
   - `manual` — anything else (the default for a bare `louie-roadmap add`).

3. **Allocate the next ID.**
   - Read `roadmap.md`, scan all entries (both `## Captured` and `## Promoted`), find the highest `R-NNN`, increment.
   - First entry on a fresh file is `R-001`.

4. **Append the entry under `## Captured`** at the top of that section (newest first):

   ```markdown
   ### R-NNN: <Title>

   - Created: YYYY-MM-DD
   - Source: <source>
   - Effort: <S|M|L>         (omit the line if the user didn't supply one)
   - Notes:

     <free text, or omitted if empty>
   ```

   If the `## Captured` section is showing the placeholder `_No ideas captured yet._`, remove that line before inserting.

5. **Update the `Last Updated:` line** at the top of the file.

6. **Confirm to the user:** "Captured R-NNN: <title>. Run `louie-roadmap promote R-NNN` when you're ready to turn it into a feature."

### `promote`

1. **Parse the ID.** Accept `R-007`, `r-007`, or `7` (right-pad to `R-007`). Error if no ID supplied.

2. **Locate the entry.** Read `roadmap.md`. The entry must be in `## Captured`. If it's already in `## Promoted`, tell the user and link to the existing feature folder. If it doesn't exist at all, error.

3. **Delegate to `louie-feature --from-roadmap <id>`.** Read and follow `_LOUIE_/commands/louie-feature.md`. The feature command handles seeding Tom and moving the entry to `## Promoted` after the feature folder is created.

### Bare call (no subcommand)

1. If `roadmap.md` doesn't exist, say "No roadmap yet — `louie-roadmap add \"<title>\"` to capture the first idea."
2. Otherwise, print:
   - The current `## Captured` entries (ID, Title, Created, Effort if set).
   - A count of `## Promoted` entries with a one-line link list.
   - The total count.

Keep the printout terse. Don't dump Notes inline — they live in the file, not in chat output.

## Cross-Cutting Notes

- **No agent involved.** This command writes the file directly. Ivy doesn't own the roadmap; she only feeds it through `louie-ideate`.
- **No architecture or runbook gate.** The roadmap is pre-commitment. `add` works on a fresh repo with no `architecture.md`. `promote` triggers `louie-feature`, which enforces the standard gates.
- **Lazy creation.** Don't bootstrap `roadmap.md` from any other command (setup, import, migrate, update-framework). First `add` creates it.
- **One-way audit trail.** Promoted entries stay in `roadmap.md` forever as a record of what was once a captured idea. They're not deleted, even if the resulting feature is later retired.

## Usage

```
louie-roadmap
```

```
louie-roadmap add "CSV import for recipes"
```

```
louie-roadmap add "Dark mode"
I want it to honor system preference by default and remember a manual override.
Effort: S
```

```
louie-roadmap promote R-007
```
