# Codebase Map

> **What this is:** a maintained *index* of where code actually lives — descriptive, measured, no prose. It answers "where is X handled?" with a row lookup instead of a repo scan. It is **not** architecture: `architecture.md` is prescriptive (what should be where, stable); this map is descriptive (what is where, churns with every feature). Keep them separate.
>
> **Lifecycle:** Sophie creates this at setup/import when the project is already large (or when proposing the architecture split — same threshold, sibling artifacts). Nina appends/edits a row whenever she adds a module or a new path root. `louie-doc`'s reconcile pass regenerates the mechanical columns (Size) and flags rows whose paths no longer exist. Domain names must match the `architecture.md` domain list — one partition vocabulary everywhere.
>
> **Rules:** strictly an index. No design rationale, no descriptions beyond the table cells. `Path roots` are globs of where the domain's code lives; `Entry points` are the files a reader starts from; `Owning features` names the feature folders (reverse traceability: file → feature without grepping every `feature.md`).

Last reconciled: YYYY-MM-DD (louie-doc)

| Domain | Path roots | Entry points | Owning features | Size |
|--------|-----------|--------------|-----------------|------|
| [name] | [src/x/**, src/y/z.ts] | [src/x/index.ts] | [feature-a, feature-b] | [~N LOC / N files] |

## Largest Files (top 10)

| File | Size |
|------|------|
| [path] | [N lines] |

## External Surface

Ports, queues, webhooks, cron entry points — pointers only; operational detail lives in `_LOUIE-output/runbook.md`.

- [e.g. HTTP :3000 → src/server.ts (see runbook § Ports & Endpoints)]
