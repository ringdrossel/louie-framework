# louie-from-source

Fetch a task from the configured source adapter and hand it off to the correct LOUIE command. Works with **any** adapter that implements `_LOUIE_/adapters/louie-source-adapter.md` — it names no specific source system.

## Usage

```
louie-from-source          — fetch the next Ready task
louie-from-source 42       — fetch task with ID 42
```

## Steps

1. **Determine which adapter is active:**
   Look for adapters in this order — the first location that contains at least one `<name>/adapter.md` wins:
   1. `louie-adapters/` at the project root (a sibling of `_LOUIE_/`) — per-project override
   2. `~/.louie/adapters/` — machine-global install, shared by all projects

   Use the first adapter directory found in the winning location, or — if multiple exist — ask the user which to use (present as a structured choice; see `_LOUIE_/guidelines/interaction-guidelines.md`). If neither location has an adapter, tell the user no source adapter is configured (install one to `~/.louie/adapters/<name>/adapter.md`) and stop.

2. **Read the adapter instructions:**
   Load `{adapters-dir}/{adapter}/adapter.md` (from the location resolved in step 1) and follow its operation definitions (endpoints, auth, request/response shapes).

3. **Fetch the task:**
   - If an ID was provided: call `fetch_task(id)`
   - If no ID: call `fetch_next_task()`
   - If no Ready task is found: inform the user and stop

4. **Mark it picked up:** call `update_status(id, "In LOUIE")` on the source system.

5. **Route by louie_type** (per the adapter's routing table), passing the concept as input context:
   - `setup`   → run `louie-setup`
   - `feature` → run `louie-feature`
   - `extend`  → run `louie-extend`
   - `update`  → run `louie-update`
   - `bugfix`  → run `louie-bugfix`
   - Unknown `louie_type` → stop and report it; don't guess a command.

6. **Concept handoff:**
   - If a concept is present: start with Tom (Analyst) in **concept-intake mode** (see `_LOUIE_/agents/analyst.md`, Step 0): Tom narrates what he understood from the concept ("Here is what I understood so far…"), asks any open questions and confirms the answers, then asks for explicit approval before handing over to Sophie (setup/feature/extend). For bugfix, the routed command runs the same gate itself — summarize the concept, confirm, then start diagnosis. The concept is the initial context document.
   - If a concept is absent: start the full chain from Tom (full interview).
   - Either way, the routed command's normal confirmation gates still apply (architecture/tech-stack confirmed before feature work; feature doc approved before coding).

7. **On LOUIE workflow completion** (the routed command finished — e.g. Ava shipped / the change is merged): call `update_status(id, "Done")` on the source system.

## Notes

- This command is the public, tool-agnostic entry point. All source-specific behaviour (endpoints, auth, payloads) lives in a private adapter (`louie-adapters/<name>/adapter.md` in the project, or `~/.louie/adapters/<name>/adapter.md` machine-global), never in `_LOUIE_/`.
- If any adapter call fails (auth, network, unexpected shape), surface the error and stop — don't silently continue or fabricate a task.
