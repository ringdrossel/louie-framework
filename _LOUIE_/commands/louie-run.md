# louie-run

A **run** builds several features unattended from one orchestrator session, and stops when everything is ready for human testing. The orchestrator does the human-facing steps before and after the build; the build in between is the unattended loop (`_LOUIE_/tools/louie-run.sh`), which starts **one fresh session per unit of work**, so no sub-task inherits another's context. The run spec is a filled `_LOUIE_/templates/run-template.md`: with a source adapter it is the **description of a task with `louie_type: run`** — visible in the tracker, read by the AI from there — and without one it is a local file.

## Usage

```
louie-run <file>           — execute a run spec stored as a local file
louie-from-source <id>     — execute a run task from the tracker (routes here)
```

This command **executes** a run. Writing the spec is a separate step, `louie-spec-run` (`_LOUIE_/commands/louie-spec-run.md`) — usually at the end of the conversation in which the idea was developed, followed by a new session that runs this command.

Prerequisites are the unattended loop's: a set-up project (`architecture.md` + `tech-stack.md`, Critical Rule #2), and a `requirements.md` for every sub-task. Read `_LOUIE_/workflow/agentic-mode.md` § Unattended loop once before the first run — it defines what one session does, parking, `run-status.md`, and the hard limits a run inherits.

## Procedure

The orchestrator is the session that runs this command. It is one session from start to end, and it never builds a sub-task itself — every build happens in a fresh session started by the loop.

1. **Read the spec** — the task description (via `louie-from-source`, which has already claimed the run task) or the file. Check it before doing anything: every sub-task slug has an overview row and a `requirements.md`; dependencies point at listed slugs or at features already `Implemented`/`Tested`; `Mode` is `unattended` or `attended`. A failed check is reported with what is missing — fix the spec or the docs first, never build around it.
   **Rerun?** Run `bash _LOUIE_/tools/louie-run-bg.sh status` first. Exit `3` means this run's loop is still building: skip straight to waiting (step 4, *Wait in chunks*). Any other result: continue normally — finished Before steps are skipped, and a restarted loop resumes where it stopped.
2. **Claim the sub-tasks** (adapter only): `update_status(id, "In LOUIE")` for each listed tracker id. Idempotent — a rerun changes nothing.
3. **Before the build**, in order. Skip a step whose outcome is already there (a resumed run). `[agent]` steps run directly. A `[human]` step: tell the user exactly what to do, wait until it is done, verify the outcome. Follow the spec's **Standing rules** in every step and pass them on to the build (step 4).
4. **The build.** Standing rules reach every session through the feature docs, not the prompt: first make sure each rule is in the affected features' `requirements.md` § Constraints — add it and commit if not. Then start the loop **detached** through the helper, which works the same on every harness:

   ```
   bash _LOUIE_/tools/louie-run-bg.sh start --only <slug>,<slug>,… --unit <unit> --timeout <s> --max-runs <n> --quiet
   ```

   `--only` takes the sub-task slugs, so the loop builds exactly this run and nothing else that is `Planned`. The loop runs in its own session: it survives your shell tool's timeout and even the end of this session. Never start `louie-run.sh` directly with `&` — a tool timeout kills it.

   **Wait in chunks.** Call `bash _LOUIE_/tools/louie-run-bg.sh wait --max <s>` and repeat while it exits `3` (still running); it exits `0` once the loop has finished and prints `finished: exit <n>` plus the log tail. Pick the chunk to fit your shell tool, and set the tool's own timeout above it:

   | Harness | `--max` | Shell tool timeout to pass |
   |---------|---------|----------------------------|
   | Claude Code | 540 | 600000 ms (the tool's maximum) |
   | opencode | 1800 | 1900000 ms — pass it explicitly; the default is 120 s (no upper limit) |
   | anything else, or no timeout parameter | 100 (the default) | — fits a 120 s default |

   Between chunks say nothing beyond one short progress line — each chunk is a turn. If the session ends anyway, rerunning `louie-run` / `louie-from-source <id>` finds the loop with `louie-run-bg.sh status` and resumes waiting; it never starts a second one (`start` refuses while a loop runs).

   **`Mode: attended`** adds `--once`: after each unit, report what was built and ask whether to continue.
5. **Read the result** from the loop's exit code (`finished: exit <n>`) and `_LOUIE-output/run-status.md`:
   - `0` with `Status: done` → step 6.
   - `0` with `Status: completed` (only under `Mode: attended`, after `--once`) → report the unit, ask whether to continue; yes → step 4.
   - `10` (`needs-human`) → bring every parked question (`Pending decision:`) to the user in one message. Record each answer in the feature's `requirements.md` § Assumptions or `decisions.md`, commit, and go back to step 4 — the loop resumes where it stopped.
   - `2` (three crashes in a row, or the loop process was killed), `11` (`blocked`), `12` (`--max-runs` reached) → report the reason with the log path, and ask whether to rerun step 4 or stop here.
6. **After the build**, in order — usually live acceptance with the user. Report per step what worked.
7. **Handoff.** With an adapter, write a resolution on **every sub-task** (`update_task(id, resolution)`: what was built, assumptions made, review and test results, what is left — from its run report) and on **the run task** (the summary across all sub-tasks, plus the After-the-build results). Without one, put the same summary in the final message. **Close nothing:** every task stays "In LOUIE" until the user has tested and merged (`louie-from-source` step 7). The final message names the next action: test, then merge.

## Agentic

When the orchestrator itself is started by an autonomous agent (`louie-from-source --agentic` on a run task), there is nobody for `[human]` steps: run the `[agent]` steps, and at the first `[human]` step stop with `needs-human` naming that step. A spec without `[human]` steps runs through. Everything else is unchanged — the build is already unattended.

## Hard limits

Everything in `_LOUIE_/workflow/agentic-mode.md` § Hard limits holds for the whole run, orchestrator included — never merge, never create a branch, never deploy or provision, never run `louie-setup` / `louie-import` — plus two of the run's own: **never push**, and **never close a task**. A spec step that asks for one of these is a `[human]` step, whatever its tag says.
