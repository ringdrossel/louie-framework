# louie-roadmap-change

When the user says **`louie-roadmap-change`**, edit an existing roadmap entry — its status, notes, effort, or title — or mark it deferred / dropped.

The roadmap (`_LOUIE-output/roadmap.md`) holds the project's **bigger changes / epics** — not every feature. Per-feature status lives in `_LOUIE-output/implementations/overview.md`; the roadmap is the higher-level "what big things do we want to do, and where are they" view.

This command is also called by `louie-feature` to keep an epic's status in sync when a feature tied to a roadmap entry is added (→ `In Progress`) or finished (→ offered `Done`).

## Usage forms

| Form | What it does |
|------|--------------|
| `louie-roadmap-change <id>` | Interactive — print the entry, ask which field to change. |
| `louie-roadmap-change <id> status <status>` | Set the `Status` field. |
| `louie-roadmap-change <id> note "<text>"` | Append a dated note to `Notes`. |
| `louie-roadmap-change <id> effort <S\|M\|L>` | Set `Effort`. |
| `louie-roadmap-change <id> title "<text>"` | Rename the entry (the `R-NNN` id never changes). |

Match the field name case-insensitively. Promotion (`Captured` → `Promoted` section move) is **not** done here — that's `louie-roadmap promote` / `louie-feature --from-roadmap`.

## Status values (epic lifecycle)

| Status | Meaning |
|--------|---------|
| `Captured` | Logged as an idea; no feature work started. Default on `louie-roadmap add`. |
| `In Progress` | A feature promoted from this epic is being built. Set automatically by `louie-feature` on `--from-roadmap`. |
| `Done` | The epic's work is complete. Because an epic can span several features, `louie-feature` *offers* this when a feature finishes — it never forces it. |
| `Deferred` | Parked for now. Stays in the file as audit trail. |
| `Dropped` | Abandoned. Stays in the file (struck-through title), never deleted. |

## Procedure

1. **Resolve `_LOUIE-output/roadmap.md`.** It is normally created at `louie-setup` / `louie-import` / `louie-migrate`. If it is missing, create it from `_LOUIE_/templates/roadmap-template.md` first (defensive), then continue.
2. **Parse the id.** Accept `R-007`, `r-007`, or `7` (right-pad to `R-007`). Error if none supplied or the id isn't found.
3. **Locate the entry** in `## Captured` or `## Promoted`.
4. **Apply the change in place:**
   - If the entry has no `Status:` line yet (an entry created before this field existed), add one. A `Captured`-section entry defaults to `Status: Captured`; a `Promoted`-section entry defaults to `Status: In Progress`.
   - `note` appends `  - YYYY-MM-DD: <text>` under `Notes:` rather than overwriting prior notes.
   - `Dropped` keeps the entry but wraps its title in `~~…~~`.
5. **Update the `Last Updated:` line** at the top of the file.
6. **Confirm to the user:** one line, e.g. `R-007 → Status: Done.`

## Cross-Cutting Notes

- **No agent involved.** This command writes the file directly, same as `louie-roadmap`.
- **No architecture or runbook gate.** The roadmap is project-level planning; `change` works regardless of project state.
- **Does not move entries between sections.** Section placement (`Captured` vs `Promoted`) reflects whether a feature folder exists; only `promote` changes that. `Status` tracks the finer lifecycle within a section.
- **Called by `louie-feature`** for status sync on roadmap-linked features (see `_LOUIE_/commands/louie-feature.md`).

## Usage

```
louie-roadmap-change R-007 status "In Progress"
```

```
louie-roadmap-change R-003 note "Split into auth + billing; auth first."
```

```
louie-roadmap-change R-011 status Dropped
```
