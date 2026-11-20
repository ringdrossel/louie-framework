# louie-run

A **run** builds several features unattended from one orchestrator session, and stops when everything is ready for human testing. The orchestrator does the human-facing steps before and after the build; the build in between is the unattended loop (`_LOUIE_/tools/louie-run.sh`), which starts **one fresh session per unit of work**, so no sub-task inherits another's context. The run spec is a filled `_LOUIE_/templates/run-template.md`: with a source adapter it is the **description of a task with `louie_type: run`** — visible in the tracker, read by the AI from there — and without one it is a local file.

## Usage

```
louie-run new              — write a run spec from the current conversation
louie-run <file>           — execute a run spec stored as a local file
louie-from-source <id>     — execute a run task from the tracker (routes here)
```

Prerequisites are the unattended loop's: a set-up project (`architecture.md` + `tech-stack.md`, Critical Rule #2), and a `requirements.md` for every sub-task. Read `_LOUIE_/workflow/agentic-mode.md` § Unattended loop once before the first run — it defines what one session does, parking, `run-status.md`, and the hard limits a run inherits.

## Create mode — `louie-run new`

The usual start: the user has developed an idea with the AI and says something like "add this as a runner task that executes the sub-tasks".

1. **Collect the sub-tasks** from the conversation, the overview (`_LOUIE-output/implementations/overview.md`) and — with an adapter — the tracker. For each: the feature slug, its dependencies, and its tracker id if it has a task.
2. **Make every sub-task buildable.** The unattended build needs a task spec per feature (`louie-continue.md` § Agentic, rule 6). For a sub-task with no `implementations/<slug>/requirements.md`, run Tom (`_LOUIE_/agents/analyst.md`) for it now — interview or concept intake, playback, approval — and write `requirements.md` plus a `Planned` overview row with its `Depends on`. With an adapter, a sub-task that has no tracker task gets one via `create_task` (`louie_type: feature`); leave it in the state creation yields, so another session's `louie-from-source` cannot pick it up — the run claims it.
3. **Fill the template** `_LOUIE_/templates/run-template.md`: goal, `Mode: unattended` unless the user asks for `attended`, sub-tasks in dependency order, standing rules from the conversation, the `[human]` / `[agent]` steps before and after the build. Write every Before step so its outcome can be checked — that is what makes a rerun safe.
4. **Show the spec and get approval** (two-turn gate: the spec in one turn, the question in the next — `_LOUIE_/guidelines/interaction-guidelines.md`). The spec is the plan the night runs on; nothing is filed before the user approves it.
5. **File it.**
   - **With an adapter:** `create_task` with the spec as `description`, `louie_type: run`, title `RUN: <goal>`; then `update_status(id, "Ready")`. Tell the user the id and the next step: a new session with `louie-from-source <id>`.
   - **Without one:** write `_LOUIE-output/runs/<slug>.md` and commit it. Next step: a new session with `louie-run _LOUIE-output/runs/<slug>.md`.

   A new session is recommended, not required — it starts the orchestrator with a clean context.

## Execute mode

The orchestrator is the session that runs this mode. It is one session from start to end, and it never builds a sub-task itself — every build happens in a fresh session started by the loop.

1. **Read the spec** — the task description (via `louie-from-source`, which has already claimed the run task) or the file. Check it before doing anything: every sub-task slug has an overview row and a `requirements.md`; dependencies point at listed slugs or at features already `Implemented`/`Tested`; `Mode` is `unattended` or `attended`. A failed check is reported with what is missing — fix the spec or the docs first, never build around it.
2. **Claim the sub-tasks** (adapter only): `update_status(id, "In LOUIE")` for each listed tracker id. Idempotent — a rerun changes nothing.
3. **Before the build**, in order. Skip a step whose outcome is already there (a resumed run). `[agent]` steps run directly. A `[human]` step: tell the user exactly what to do, wait until it is done, verify the outcome. Follow the spec's **Standing rules** in every step and pass them on to the build (step 4).
4. **The build.** Start the loop from the project root, detached, its output in `.louie-run/loop.log`:

   ```
   bash _LOUIE_/tools/louie-run.sh --only <slug>,<slug>,… --unit <unit> --timeout <s> --max-runs <n> --quiet
   ```

   `--only` takes the sub-task slugs, so the loop builds exactly this run and nothing else that is `Planned`. Standing rules reach every session through the feature docs, not the prompt: before starting, make sure each rule is in the affected features' `requirements.md` § Constraints — add it and commit if not. Then wait for the loop to exit. On a runtime that notifies the session when a background job ends (Claude Code), use that — no polling. Otherwise tell the user the command and the log path, and that rerunning `louie-run` / `louie-from-source <id>` picks up here.

   **`Mode: attended`** adds `--once`: after each unit, report what was built and ask whether to continue.
5. **Read the result** from the loop's exit code and `_LOUIE-output/run-status.md`:
   - `0` with `Status: done` → step 6.
   - `0` with `Status: completed` (only under `Mode: attended`, after `--once`) → report the unit, ask whether to continue; yes → step 4.
   - `10` (`needs-human`) → bring every parked question (`Pending decision:`) to the user in one message. Record each answer in the feature's `requirements.md` § Assumptions or `decisions.md`, commit, and go back to step 4 — the loop resumes where it stopped.
   - `2` (three crashes in a row), `11` (`blocked`), `12` (`--max-runs` reached) → report the reason with the log path, and ask whether to rerun step 4 or stop here.
6. **After the build**, in order — usually live acceptance with the user. Report per step what worked.
7. **Handoff.** With an adapter, write a resolution on **every sub-task** (`update_task(id, resolution)`: what was built, assumptions made, review and test results, what is left — from its run report) and on **the run task** (the summary across all sub-tasks, plus the After-the-build results). Without one, put the same summary in the final message. **Close nothing:** every task stays "In LOUIE" until the user has tested and merged (`louie-from-source` step 7). The final message names the next action: test, then merge.

## Agentic

When the orchestrator itself is started by an autonomous agent (`louie-from-source --agentic` on a run task), there is nobody for `[human]` steps: run the `[agent]` steps, and at the first `[human]` step stop with `needs-human` naming that step. A spec without `[human]` steps runs through. Everything else is unchanged — the build is already unattended.

## Hard limits

Everything in `_LOUIE_/workflow/agentic-mode.md` § Hard limits holds for the whole run, orchestrator included — never merge, never create a branch, never deploy or provision, never run `louie-setup` / `louie-import` — plus two of the run's own: **never push**, and **never close a task**. A spec step that asks for one of these is a `[human]` step, whatever its tag says.
