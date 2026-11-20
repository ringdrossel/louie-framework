# louie-spec-run

Write a **run spec**: the plan for building a set of features unattended from one orchestrator session (`_LOUIE_/commands/louie-run.md`). This command only writes and files the spec — **nothing is built and no run starts here.** The run is executed later, in a new session, with `louie-from-source <id>` or `louie-run <file>`.

## When it applies

- The user types `louie-spec-run`.
- **Or the user asks for it in their own words during a conversation** — "make a run task from these parts", "add this as a runner task that executes the sub-tasks", "turn the sub-tasks into a run". Treat that as this command: the parts discussed so far are the sub-tasks. Do not start building them, and do not write the spec freehand — follow the steps below so the spec has the shape `louie-run` reads.

Prerequisite: a set-up project (`architecture.md` + `tech-stack.md`, Critical Rule #2) — a run only builds features of an established project.

## Steps

1. **Collect the sub-tasks** from the conversation, the overview (`_LOUIE-output/implementations/overview.md`) and — with an adapter — the tracker. For each: the feature slug, its dependencies, and its tracker id if it has a task.
2. **Make every sub-task buildable.** The unattended build needs a task spec per feature (`louie-continue.md` § Agentic, rule 6). For a sub-task with no `implementations/<slug>/requirements.md`, run Tom (`_LOUIE_/agents/analyst.md`) for it now — interview or concept intake, playback, approval — and write `requirements.md` plus a `Planned` overview row with its `Depends on`. With an adapter, a sub-task that has no tracker task gets one via `create_task` (`louie_type: feature`); leave it in the state creation yields, so another session's `louie-from-source` cannot pick it up — the run claims it.
3. **Fill the template** `_LOUIE_/templates/run-template.md`: goal, `Mode: unattended` unless the user asks for `attended`, sub-tasks in dependency order, standing rules from the conversation, the `[human]` / `[agent]` steps before and after the build. Write every Before step so its outcome can be checked — that is what makes a rerun safe.
4. **Show the spec and get approval** (two-turn gate: the spec in one turn, the question in the next — `_LOUIE_/guidelines/interaction-guidelines.md`). The spec is the plan the night runs on; nothing is filed before the user approves it.
5. **File it.**
   - **With an adapter:** `create_task` with the spec as `description`, `louie_type: run`, title `RUN: <goal>`; then `update_status(id, "Ready")`. Tell the user the id and the next step: a new session with `louie-from-source <id>`.
   - **Without one:** write `_LOUIE-output/runs/<slug>.md` and commit it. Next step: a new session with `louie-run _LOUIE-output/runs/<slug>.md`.

   A new session is recommended, not required — it starts the orchestrator with a clean context. Either way, this command ends here: it never starts `louie-run` itself.

## Notes

- The spec is a filled `_LOUIE_/templates/run-template.md`. With a source adapter it lives in the **task description** (`louie_type: run`), so it is visible in the tracker and the executing session reads it from there; without one it is the local file.
- Changing a filed spec later: edit the task description (adapter `update_task`, field `description`) or the file, after showing the change to the user. A running orchestrator is not affected until it is started again.
