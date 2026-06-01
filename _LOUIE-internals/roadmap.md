# Roadmap System

Design notes for `_LOUIE-output/roadmap.md` — the per-project idea-capture artifact and the `louie-roadmap` command that writes to it. Read this before changing the roadmap template, the `louie-roadmap` command, or the way `louie-ideate` / `louie-feature` interact with the roadmap.

## Why It Exists

LOUIE had two intake surfaces for new feature ideas, with a gap between them:

| Surface | Commitment level | Persistence |
|---------|------------------|-------------|
| `louie-ideate` (Ivy) | None — brainstorm | None — chat scrollback |
| `louie-feature` (Tom + Sophie + chain) | High — feature folder + requirements + architecture eval | Full feature folder |

There was no lightweight, persistent surface for **captured-but-unevaluated ideas**. Three concrete failure modes:

1. **Ideation evaporates.** Ivy generates ~10 ideas per `louie-ideate` run; users typically act on one. The other nine disappear when chat scrolls.
2. **Mid-feature ideas have no home.** Users discover "we should also do X eventually" during `louie-feature` / `louie-extend` / `louie-bugfix` flows. The only options were "stop and run `louie-feature` on X" or "trust it'll come back later."
3. **`implementations/overview.md` is the wrong slot.** Its "Planned" rows imply a feature folder exists with requirements written and architecture evaluated — that's already a meaningful commitment. There's no room for untriaged ideas.

The roadmap fills this gap with the lightest commitment LOUIE supports: an ID, a title, and free-form notes.

## Why Not Absorb Into `implementations/overview.md`

Two artifacts, two commitment levels:

| Concern | Audience | State | Right home |
|---------|----------|-------|-----------|
| Captured ideas (pre-folder, pre-Tom, pre-Sophie) | The user, occasionally Ivy | Untriaged; may never become features | `roadmap.md` |
| Planned features (folder exists, requirements written, architecture evaluated) | The full agent chain | Committed; about to build | `implementations/overview.md` "Planned" |

Merging them would either:

- **Pollute the overview** with untriaged ideas that haven't earned a feature folder, defeating the slim-index design (see `_LOUIE-internals/scaling.md` for the AI-efficiency criterion), or
- **Inflate the overview entry** to support both states, drifting toward BMAD-style monolithic templates that LOUIE explicitly rejects.

Clean separation also means promotion is an explicit, auditable event (Captured → Promoted in roadmap; new row in overview "Planned") rather than an in-place status flag.

## Why Not Absorb Into `_LOUIE-internals/BACKLOG.md`

Different surfaces:

- `_LOUIE-internals/BACKLOG.md` is for the **framework itself**. Lives in `_LOUIE-internals/` (not distributed).
- `_LOUIE-output/roadmap.md` is for **the user's project**. Lives in `_LOUIE-output/` (distributed empty, filled per project).

They never overlap, so the name collision (`BACKLOG.md` vs `roadmap.md`) is fine. We use the word "roadmap" downstream to avoid the Agile-team baggage of "backlog" and to keep the framework-internal vs. project-internal distinction obvious in conversation.

## Lifecycle

| Trigger | Who writes | What happens |
|---------|-----------|--------------|
| `louie-setup` / `louie-import` / `louie-migrate` | The command directly | Create `roadmap.md` from template if missing, so it always exists. |
| `louie-roadmap add "<title>"` | The command directly | Append entry under `## Captured` with next ID and `Status: Captured`. Recreates the file from template if a legacy project is missing it. |
| `louie-ideate` (end of Ivy's pass) | The command, on user pick | Ask user which of Ivy's ideas to save; append each as a `Source: ideate` entry. |
| `louie-feature --from-roadmap <id>` | `louie-feature` | Seed Tom's interview with the entry's Notes; after the feature folder is created, move the entry to `## Promoted` with a back-link and set `Status: In Progress`. On finish, offer `Status: Done` (epics can span multiple features — ask, don't force). |
| `louie-roadmap promote <id>` | The command | Delegate to `louie-feature --from-roadmap <id>`. |
| `louie-roadmap-change <id> …` | The command directly | Edit an entry: `status` / `note` / `effort` / `title`; `Deferred` / `Dropped`. Does not move between sections. |
| Manual edit | User | Re-order or retag freely. The roadmap is plain markdown. |

No agent owns the roadmap, matching the `runbook.md` precedent. The roadmap is a *surface*, not a *voice*.

## Design Decisions

### Naming: `roadmap.md` / `louie-roadmap`

"Backlog" carries Agile-team semantics (Scrum backlog, refinement, point estimates) that mislead users. "Roadmap" signals forward-looking without locking in a timeline. The template explicitly states "triage list, not a timeline" to head off Gantt-style expectations.

### Single File, Section per Entry

Folder-per-idea (one file per entry) would impose feature-folder weight on items whose entire value proposition is *lightness*. v1 ships a single file with heading-per-entry. We revisit only if real usage produces 50+ active entries on one project, which is not the expected scale.

### Minimal Schema

| Field | Required? | Notes |
|-------|-----------|-------|
| ID | Yes | `R-NNN`, monotonically incrementing. Addressable by `louie-feature --from-roadmap R-NNN` and `louie-roadmap promote R-NNN`. |
| Title | Yes | One line. |
| Created | Yes | ISO date. |
| Source | Yes | `ideate` / `manual` / `feature-work` / `bugfix`. Free text fallback. |
| Status | Yes | `Captured` / `In Progress` / `Done` / `Deferred` / `Dropped`. Explicit `Status:` field (epic lifecycle). The section (`## Captured` / `## Promoted`) reflects whether a feature folder exists; `Status` tracks the finer state within it. Set on `add`, synced by `louie-feature`, edited by `louie-roadmap-change`. |
| Effort | No | `S` / `M` / `L`. Only if the user supplied it. Never auto-generated. |
| Notes | No | Free text. When the entry was captured from Ivy, her full idea card (what/why/effort/builds-on/fits-arch) goes here verbatim. |

**Explicitly not on the schema:** Priority, Owner, Dependencies, Tags. Each adds friction to a list whose value proposition is *no friction*. Priority belongs on a feature doc, not on a captured idea — captured ideas haven't earned ranking yet. We can add fields later; we can't easily take them away.

### No Agent Owner

Same model as `runbook.md`. The command writes to the file directly. Ivy *interacts with* the roadmap when `louie-ideate` ends, but she doesn't own it — she presents ideas; the user picks; the command appends. Tom doesn't read the roadmap either — `louie-feature` reads the relevant entry and seeds Tom's interview with its Notes. Tom interviews as usual.

Adding a dedicated agent for a triage list would be ceremony.

### Promotion: Move to `## Promoted` Section

When an idea becomes a real feature, three options exist for what happens to the roadmap entry:

| Option | Pro | Con |
|--------|-----|-----|
| Delete the entry | Cleanest "active" list | Loses the audit trail — no record that this feature was ever a roadmap idea |
| Flag with status, keep in place | Auditable, single section | Pollutes the active list; "Captured" becomes a mix of pending + done |
| **Move to `## Promoted` section (chosen)** | Auditable; active list stays clean | One extra section in the file |

Promoted entries carry a `Promoted: YYYY-MM-DD → _LOUIE-output/implementations/<feature>/` line back to the feature folder. The feature.md doesn't need to back-link to the roadmap entry — the audit trail flows one way.

### Created at Setup (reversal of the original lazy-creation decision)

`roadmap.md` is now created by `louie-setup` (and `louie-import` / `louie-migrate`), **not** lazy-created on first `louie-roadmap add`.

The original v1 decision was lazy creation (cite: lazy-loading principle, zero migration cost, no empty-file noise). In practice that produced a bug: several commands and agent flows reference `roadmap.md` (`louie-feature` checks for captured entries, `louie-roadmap promote`, the bare `louie-roadmap` print) and on a project that never ran `add`, those references hit "not found." The fix is to guarantee the file exists from project start.

- The Resolve step in `louie-roadmap` / `louie-roadmap-change` still recreates the file from template defensively, so legacy projects (and any that predate setup creation) never surface "not found" either.
- The empty-file-noise concern is outweighed by the correctness win; an empty roadmap with placeholders is clearer than a missing one.

### Scope: epics / bigger changes, not every feature

The roadmap tracks *bigger changes / epics* — larger pieces of work worth shepherding from idea to done. Per-feature status stays in `implementations/overview.md`; duplicating every feature here would recreate exactly the overlap the "Why Not Absorb Into overview.md" section argues against. The `Status` lifecycle (`In Progress` / `Done`) is therefore epic-level: `louie-feature` only touches the roadmap for roadmap-linked work, and because one epic can span several features it *offers* `Done` rather than forcing it.

### Subcommands: `add`, `promote`, and `change`

v1 shipped `add` and `promote` only, deferring `drop` / `defer` / `edit`. The `change` operation now ships as its own command (`louie-roadmap-change`) because the epic lifecycle needs status transitions that `louie-feature` can call programmatically and the user can drive manually (status / notes / effort / title; defer / drop). `reorder` / `query` remain direct-file-edit only — real usage hasn't shown they need tool support.

### `louie-feature --from-roadmap <id>` (Not a Separate Command)

The promotion flow is "kick off the feature chain, seeded from a roadmap entry." That's exactly what `louie-feature` already does, minus the seed source. Adding it as a flag — rather than a new top-level command — keeps the chain's existing structure and gate behavior. `louie-roadmap promote <id>` is a thin alias that delegates to `louie-feature --from-roadmap <id>`.

### What Sophie Sees on Promotion

Same as a normal `louie-feature` invocation. Sophie evaluates architecture fit fresh — the captured Notes are *seed material*, not a prior decision. If the captured entry had a `Fits architecture: Yes` line from Ivy (months ago, when the project was different), Sophie re-evaluates against the current state. The stale field is context, not commitment.

## v1 Scope

**Ships:**

- `_LOUIE-output/roadmap.md` (lazy-created from template).
- `_LOUIE_/templates/roadmap-template.md`.
- `_LOUIE_/commands/louie-roadmap.md` with subcommands `add` and `promote` (and a bare-call that prints the current roadmap).
- `louie-ideate` updated to offer "save to roadmap" at the end of Ivy's pass.
- `louie-feature` updated to accept `--from-roadmap <id>` and to move the entry to `## Promoted` after the feature folder is created.
- Registration in `CLAUDE.md`, `README.md`, `_LOUIE_/workflow/ai-workflow.md`, `_LOUIE_/setup/project-setup.md`, and the six init scripts.
- One-line cross-references from `feature-template.md` and `implementations/overview.md` to the roadmap.

**Deferred:**

- `louie-status` integration (separate `_LOUIE-internals/BACKLOG.md` item; schema is structured enough to grep when that command lands).
- Subcommands `drop` / `defer` / `reorder` / `retag` / `query`.
- Tool-level integration into `louie-bugfix` / `louie-extend` (convention only; users can run `louie-roadmap add` mid-flow).
- A dedicated agent owner.
- Auto-capture from chat history.
- Priority / effort / category filtering.

## Open Questions

- **Bulk operations.** No tool support yet for "promote three at once" or "drop everything older than N months." Defer until usage shows it.
- **Status-command coupling.** A future `louie-status` should summarize roadmap entries alongside `implementations/overview.md`. The roadmap schema is parseable enough; no roadmap-side work is needed when `louie-status` lands.
- **Roadmap and `louie-retire`.** A future feature-retirement command might want a `Dropped` mirror of `Promoted`. The schema already accommodates a `## Dropped` section; we just don't have a command path for it at v1.
