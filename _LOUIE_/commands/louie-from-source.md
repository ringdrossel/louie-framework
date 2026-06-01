# louie-from-source

Fetch a task from the configured source adapter and hand it off to the correct LOUIE command. Works with **any** adapter that implements `_LOUIE_/adapters/louie-source-adapter.md` — it names no specific source system.

## Usage

```
louie-from-source          — fetch the next Ready task
louie-from-source 42       — fetch task with ID 42
```

## Steps

1. **Determine which adapter is active:**
   Read `louie-adapters/` (a sibling of `_LOUIE_/`, at the project root). Use the first directory found, or — if multiple exist — ask the user which to use (present as a structured choice; see `_LOUIE_/guidelines/interaction-guidelines.md`). If `louie-adapters/` is absent or empty, tell the user no source adapter is configured and stop.

2. **Read the adapter instructions:**
   Load `louie-adapters/{adapter}/adapter.md` and follow its operation definitions (endpoints, auth, request/response shapes).

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
   - If a concept is present: skip Tom (Analyst) and pass the concept as the initial context document to the next agent (Sophie for setup/feature/extend; the bugfix diagnosis chain for bugfix).
   - If a concept is absent: start the full chain from Tom.
   - Either way, the routed command's normal confirmation gates still apply (architecture/tech-stack confirmed before feature work; feature doc approved before coding).

7. **On LOUIE workflow completion** (the routed command finished — e.g. Ava shipped / the change is merged): call `update_status(id, "Done")` on the source system.

## Notes

- This command is the public, tool-agnostic entry point. All source-specific behaviour (endpoints, auth, payloads) lives in the private `louie-adapters/<name>/adapter.md`, never in `_LOUIE_/`.
- If any adapter call fails (auth, network, unexpected shape), surface the error and stop — don't silently continue or fabricate a task.
