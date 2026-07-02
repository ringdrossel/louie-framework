# louie-status

When the user says **`louie-status`**, print a read-only snapshot of the project's state — "where am I?" — by aggregating existing artifacts. No agent, no writes, no gates: it reads indexes and headers and reports.

Optional argument: `louie-status <domain>` restricts the report to one domain (once the overview is domain-grouped — see S-03).

## What it reports

Aggregate and print, grouped by domain once the overview is domain-grouped (reuse the `architecture.md` / `codebase-map.md` domain names):

1. **Features by status** — counts and the per-feature list from `_LOUIE-output/implementations/overview.md` (`Planned` / `In Development` / `Implemented` / `Tested`; list `Retired` only as a count). Flag any `In Development` feature as the likely resume target.
2. **Open questions** — every unresolved `## Open Questions` item across feature docs and requirements, with its source feature. Only the open ones.
3. **Stale in-development docs** — features marked `In Development` whose last `Change History` line is older than ~14 days (configurable in the ask if the user wants a different window). These are the "started and forgotten" candidates.
4. **Recent bug fixes** — the newest rows from `_LOUIE-output/bugfixes/overview.md` (last ~5).
5. **Roadmap deltas** — `In Progress` epics and anything changed since the roadmap's `Last Updated`, from `_LOUIE-output/roadmap.md`.

Close with a one-line suggestion of the single most useful next action (usually `louie-continue` when something is `In Development`, else the highest-priority `Planned` feature).

## Read discipline

This command must stay cheap even at 150 features — follow `_LOUIE_/guidelines/execution-guidelines.md` § Context Discipline:

- Read **indexes first** and rely on them: `implementations/overview.md`, `bugfixes/overview.md`, `roadmap.md`.
- For per-feature detail, read only the **`## Status`, `## Open Questions`, and the last `## Change History` line** of each `feature.md` (and `requirements.md` Open Questions) — never whole feature folders, never source code.
- Skip the `### Retired` section except to count it.

## Procedure

1. If there's no `_LOUIE-output/`, tell the user there's no LOUIE project yet and point them at `louie-setup` / `louie-import`. Stop.
2. Read `_LOUIE-output/implementations/overview.md` (+ per-domain overview files if the index is split), `_LOUIE-output/bugfixes/overview.md`, and `_LOUIE-output/roadmap.md`.
3. For each active feature, read only its `feature.md` headers listed above.
4. Print the report, grouped by domain if the overview is grouped. Keep it tight — this is a dashboard, not a narrative.

## Cross-Cutting Notes

- **Read-only, no agent, no state file.** Pure aggregation; it writes nothing.
- **Distinct from `louie-continue`:** `louie-status` answers "what's the state of everything?"; `louie-continue` answers "what was I doing, and resume it." Status is the map; continue is the action.

## Usage

```
louie-status
```

```
louie-status auth
```
