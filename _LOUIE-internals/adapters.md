# Source Adapters

**Audience:** AI assistants working on the LOUIE framework. Design notes for the source-adapter layer — connecting an external task/PM system to the LOUIE workflow without coupling the public framework to any specific tool.

## Problem

Teams want to drive LOUIE from an external task source (a tracker, a PM tool) — fetch the next ready task, run the right LOUIE command on it, write status back. But LOUIE is meant for public release and must stay tool-agnostic: no specific vendor can be named or hard-wired inside `_LOUIE_/`.

## Shape

Two layers, with a hard public/private boundary:

```
_LOUIE_/                              ← public, tool-agnostic, publishable
  adapters/louie-source-adapter.md    ← the INTERFACE (operations + routing + concept handoff)
  commands/louie-from-source.md       ← the public command (works with ANY adapter)

louie-adapters/                       ← PRIVATE, project root, gitignored
  <name>/adapter.md                   ← concrete implementation (endpoints, auth, payloads)
  <name>/config.example               ← credential template (committed in the user's private repo)
  <name>/config                       ← real credentials (always gitignored)
```

The interface defines four operations — `fetch_next_task`, `fetch_task(id)`, `update_status(id, status)`, `attach_concept(id, markdown)` (optional) — plus a `louie_type → command` routing table (setup/feature/extend/update/bugfix) and the concept handoff rule (concept present → skip Tom, go straight to Sophie / the bugfix chain; the routed command's gates still apply).

`louie-from-source` is the entry point: pick the active adapter under `louie-adapters/`, read its `adapter.md`, fetch the task, mark it "In LOUIE", route by `louie_type` passing the concept as context, and mark it "Done" on completion.

## Design decisions

- **Public/private split is the whole point.** `_LOUIE_/` names no source system; all vendor specifics live in `louie-adapters/<name>/`, which a root `.gitignore` excludes from the public framework repo. In the public repo nothing vendor-specific is committed; the concrete adapter belongs in the user's separate private repo (where `config.example` is committed and `config` is gitignored).
- **The command is adapter-generic.** `louie-from-source` selects the first `louie-adapters/<name>/` (or asks via the structured-choice convention if several) — it never hard-codes an adapter name.
- **Concept replaces Tom, not the gates.** A concept doc stands in for the requirements interview, but the architecture-confirmation and feature-doc gates (Three Critical Rules) still run.
- **`louie-update-framework` syncs `_LOUIE_/adapters/` but never `louie-adapters/`** (user-owned, private).

## Out of scope / notes

- No concrete adapter ships in the public framework. The ProjectWB adapter referenced in the original spec lives only in the user's private `louie-adapters/projectwb/` (gitignored here).
- Exact source-system response shapes belong in that system's own contract doc, not in `_LOUIE_/`.
- Ephemeral remote sessions: gitignored `louie-adapters/` content is not pushed and is lost when the container is reclaimed — concrete adapters must be kept in a private repo.
