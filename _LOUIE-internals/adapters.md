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

The interface defines three required operations — `fetch_next_task`, `fetch_task(id)`, `update_status(id, status)` — and two optional ones — `create_task(...)`, `attach_concept(id, markdown)` — plus a `louie_type → command` routing table (setup/feature/extend/update/bugfix) and the concept handoff rule (concept present → skip Tom, go straight to Sophie / the bugfix chain; the routed command's gates still apply).

`louie-from-source` is the entry point: pick the active adapter under `louie-adapters/`, read its `adapter.md`, fetch the task, mark it "In LOUIE", route by `louie_type` passing the concept as context, and mark it "Done" only once the user has merged — the end of the routed chain is the merge gate, not completion.

## Design decisions

- **Public/private split is the whole point.** `_LOUIE_/` names no source system; all vendor specifics live in `louie-adapters/<name>/`, which a root `.gitignore` excludes from the public framework repo. In the public repo nothing vendor-specific is committed; the concrete adapter belongs in the user's separate private repo (where `config.example` is committed and `config` is gitignored).
- **The command is adapter-generic.** `louie-from-source` selects the first `louie-adapters/<name>/` (or asks via the structured-choice convention if several) — it never hard-codes an adapter name.
- **Concept replaces Tom, not the gates.** A concept doc stands in for the requirements interview, but the architecture-confirmation and feature-doc gates (Three Critical Rules) still run.
- **`louie-update-framework` syncs `_LOUIE_/adapters/` but never `louie-adapters/`** (user-owned, private).
- **`update_status` is a state goal, not a state write.** A real source system enforced a multi-rung status state machine and rejected a direct hop with a 409; reaching the target took four sequential calls. Specifying it as one write made a caller reasonably assume one write suffices. Putting the ladder on the adapter side keeps the *lifecycle* — transition order and intermediate rungs — out of `_LOUIE_/`; the alternative (a caller-visible transition list) would have leaked a specific tracker's state machine into the public interface. Scope the claim to the lifecycle, not to state names: `_LOUIE_/` does still name states today (the `"In LOUIE"` / `"Done"` literals), and after the logical-states follow-up it will still name states — its own. A multi-hop walk also adds a failure mode the single-write contract didn't have, so the adapter must report the state actually reached when a walk fails part-way; "unchanged" and "fully applied" are otherwise indistinguishable to the caller.
- **`create_task` is spec-only on purpose.** It was added after work was filed retroactively against an endpoint found by probing the live API — the gap was the missing operation, not the adapter. It is deliberately not wired into `louie-from-source` or any other command until a flow needs it, so the contract exists before the first caller improvises one.

## Out of scope / notes

- No concrete adapter ships in the public framework. The ProjectWB adapter referenced in the original spec lives only in the user's private `louie-adapters/projectwb/` (gitignored here).
- Exact source-system response shapes belong in that system's own contract doc, not in `_LOUIE_/`.
- **Follow-up, not yet done: logical states.** `_LOUIE_/` hardcodes the literals `"In LOUIE"` and `"Done"` — one specific tracker's vocabulary in a spec that claims to name no source system. The fix is for the framework to name logical states (`picked-up` / `completed` / `escalated`) and each adapter to map them to its own vocabulary. Verified scope against v1.1.0: **two files, five sites** — `_LOUIE_/adapters/louie-source-adapter.md` (the `update_status` description, the Agentic Mode mapping) and `_LOUIE_/commands/louie-from-source.md` (steps 4 and 7, plus the agentic-composition note). `_LOUIE_/workflow/agentic-mode.md` is already adapter-agnostic ("your 'done/review' state" / "your escalation state") and needs at most a terminology alignment, not a fix. Breaking for any adapter keying on the literal strings, which argues for landing it while few adapters exist.
- Ephemeral remote sessions: gitignored `louie-adapters/` content is not pushed and is lost when the container is reclaimed — concrete adapters must be kept in a private repo.
