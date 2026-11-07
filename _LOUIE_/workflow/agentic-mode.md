# Agentic Mode

**Audience:** autonomous agents (orchestrators, unattended harnesses) operating LOUIE without a human who can answer prompts in-session. Read this once before invoking any `louie-*` command autonomously.

If a human **is** driving this session — even through you — do not use agentic mode. The normal interactive commands apply.

## When agentic mode applies

Use agentic mode when **no human can answer a prompt during this run**. The test is simple: if you raised a structured choice right now, would a person answer it? No → agentic mode.

Declare it explicitly by appending `--agentic` to the command:

```
louie-feature --agentic <task description or spec>
louie-bugfix --agentic <feature> <bug description>
```

LOUIE never infers agentic mode, and it is never stored as a project setting — each invocation declares it. `--agentic` supersedes the auto-pilot resolution order entirely; combining it with `--manual` is a contradiction and stops the run.

## Prerequisites

- The project must be **established**: a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md` exist (Critical Rule #2). If they don't, stop with `status: blocked` — project setup (`louie-setup` / `louie-import`) is human work and never runs agentically.
- You have a task in hand. If your task comes from an external tracker, fetch it via `louie-from-source` (see Composition below) and run the routed command with `--agentic`.

## What your task spec must contain

In agentic mode Tom's interview becomes an **evidential gate**: he maps his checklist against your task input instead of asking questions. Your task spec must answer:

1. **What** — what exactly should be built or changed, with expected inputs/outputs
2. **For whom** — who uses it (a persona sketch is enough)
3. **Done-when** — how success is verified; testable acceptance criteria
4. **Scope edges** — what is explicitly out of scope

How gaps are handled:

- **Low-stakes gaps** (a default value, a naming choice, an edge-case policy that any reasonable pick satisfies) → the run proceeds and records each as an explicit entry under `requirements.md` § Assumptions.
- **Scope-defining gaps** (what the thing fundamentally is, who it's for, what done means) → the run **halts** with `status: needs-human` and the unanswered questions in the run report. LOUIE does not guess scope.
- **Operator facts** (a registry URL, a hostname, credentials, the target machine's CPU architecture, anything only the person running the system knows) are never guessed and never probed from the environment → `status: needs-human` as well. Under the unattended loop such a feature is parked and the rest keeps building (§ Unattended loop → Parking).

Write task specs to pass this gate: a spec that answers the four points above runs straight through.

## Routing: task shape → command

| Your task is... | Run |
|-----------------|-----|
| A new capability the project doesn't have | `louie-feature --agentic` |
| A change/addition to an existing feature | `louie-extend --agentic` |
| A small contained change (< 50 lines) | `louie-update --agentic` |
| A defect — behavior diverges from documented intent | `louie-bugfix --agentic` |

When unsure between `update` and `extend`, pick `extend` — `update`'s 50-line escalation would halt the run anyway. This table routes tasks you already have in hand; adapter-fetched tasks carry their own `louie_type` routing (see Composition).

## What happens during the run

The command runs its full chain with auto-pilot implied `on` — Tom (evidential gate) → Sophie → Leo (if UI) → Nina → Max (auto-fix loop at the project's review mode, see below) → Ava — and these gate resolutions:

- **Recommended defaults auto-apply** and are recorded in the run report (Sophie's minimal changes, Leo's UI direction).
- **The deviation tripwire halts instead of asking.** If the run materially diverges from the task spec (non-trivial architecture change, undiscussed scope, a fundamentally different UX, `update` crossing 50 lines), it stops with `status: needs-human` and the fork written into the run report.
- **Branch mode `ask` resolves to `current`** — no branch is created unless your invocation explicitly requests one.
- **A scope split** (the task is really several features) builds the **first** feature and lists the rest as follow-up tasks in the run report.
- **Max runs at the project's review mode — never below `auto-fix-all` by default.** Read `_LOUIE-output/runbook.md` § Review Mode: `auto-fix-all` → `auto-fix-all`; an explicit `auto-fix-critical` → honoured (Suggestions are listed as deferred in the run report, not applied); `manual` or unset → **`auto-fix-all`**, because nobody is there to approve a fix and the goal of an unattended run is a finished application. This is a per-run effective value; the runbook setting is never edited. (Interactive auto-pilot keeps its own floor of `auto-fix-critical` — see `_LOUIE_/agents/reviewer.md`.)

## Hard limits (never overridden)

- **Never merges.** The run always ends with work committed but unmerged. The merge decision belongs to a human (Critical Rule #3).
- **Never runs `louie-setup` / `louie-import`.**
- **Never creates a branch on its own.**
- **Halts rather than guesses** on scope-defining ambiguity and material deviations.
- **Never deploys, publishes, or provisions infrastructure.** Building and testing the application is the job. Pushing images, deploying to a host, creating registries, databases, or cloud resources, and anything that needs operator facts only a human has — registry URLs, hostnames, credentials, the target machine's CPU architecture — are human steps, run interactively afterwards (for example the `docker:build-push` recipe). Such facts are never guessed and never probed from the environment; a feature whose substance is deployment is parked as `needs-human` (see § Unattended loop → Parking) and the rest of the queue keeps building.

## What comes back

Every agentic run writes a **run report**:

- Feature-scoped runs: `_LOUIE-output/implementations/<feature>/run-report.md`
- Cross-cutting bugfixes: `_LOUIE-output/bugfixes/<YYYY-MM-DD>-<slug>-run-report.md`

The report starts with a machine-readable header — branch on `Status`:

| Status | Meaning | Your next move |
|--------|---------|----------------|
| `completed` | Chain finished through Ava; work committed, unmerged | Hand to a human for review + merge decision |
| `needs-human` | A decision fork (tripwire, scope-defining gap); resumable | Surface the `Pending decision` line to a human; resume after it's answered |
| `blocked` | Environmental/hard failure (missing prerequisites, tests can't run) | Escalate; not resolvable by re-running |

The prose body is the pre-merge summary for the human reviewer: Tom's playback + assumptions, Sophie's decision, Leo's direction, Max's rounds, Ava's verdict, files changed, follow-up tasks. Template: `_LOUIE_/templates/run-report-template.md`.

## Resuming

A `needs-human` run is left in a resumable state. Once the pending decision is answered, run `louie-continue <feature>` (interactively or with `--agentic` plus the answer in the invocation) — it reconstructs the position from artifacts + git; the run report is one more breadcrumb.

To chain many agentic runs without a person between them — one fresh session per feature, overnight — see § Unattended loop below.

## Unattended loop (one fresh session per unit of work)

Agentic mode resolves the gates *inside* one run. The **unattended loop** chains runs: a shell script that lives outside the AI harness — `_LOUIE_/tools/louie-run.sh` — starts a brand-new session, waits for it to exit, reads `_LOUIE-output/run-status.md`, and starts the next one. Each lap is what a person does by hand today — open a fresh chat, say "continue the LOUIE work", wait — minus the person. Nothing crosses a lap except the files in `_LOUIE-output/` and git, which is exactly the cold start `louie-continue` is built for. A fresh context per unit is the point, not a limitation: it is why the script never passes chat history forward.

The overseer is deliberately a script, not an agent. No harness documents a way for a running session to start a new top-level session or clear its own context, and a script costs no tokens and cannot talk itself into a different plan.

### Setting it up

1. **Setup stays a human sitting.** Run `louie-setup` (or `louie-import`) interactively and confirm the architecture gate. The scope split leaves one `Planned` row per feature in `_LOUIE-output/implementations/overview.md`, each with a `requirements.md` — those are the task specs the loop builds from. The loop never runs setup: it refuses to start on a project without `architecture.md` + `tech-stack.md`.
2. **Start the loop from the project root:**

   ```
   bash _LOUIE_/tools/louie-run.sh --once      # one fresh session, see how it goes
   bash _LOUIE_/tools/louie-run.sh             # then the whole queue
   ```

   `--harness` is detected from the project folder the same way `install.sh` detects it (pass it explicitly when several are installed). `--unit phase` splits large features across sessions (below). `--max-runs` (default 20), `--timeout <seconds>` and the per-run logs in `.louie-run/` are the safety net. `--help` lists everything.
3. **Afterwards**, read the run reports (`implementations/<feature>/run-report.md`) and `louie-status`, review the diff, and decide what to merge. The loop never merges.

### What one run does

Every session executes `louie-continue --agentic --unit <feature|phase>` (the full per-run procedure is `_LOUIE_/commands/louie-continue.md` § Agentic): consume the checkpoint if any, pick the target **without asking** (in-progress work first, then the next `Planned` feature whose `Depends on` are satisfied, in overview order), hand off to the routed command's `--agentic` path at the inferred chain position, finish exactly one unit, commit, write `run-status.md`, stop.

**Units** — what "one unit" means is the only thing the `--unit` flag changes:

| `--unit` | One session finishes… | Use when |
|----------|----------------------|----------|
| `feature` (default) | The whole remaining chain of one feature: Tom's evidential gate on `requirements.md` → Sophie → Leo (if UI) → `feature.md` → Nina (all phases) → Max loop → Ava → run report. One session per feature. | Features are the size the plan-agreement gate normally approves. |
| `phase` | Exactly one of: **plan** (through `feature.md` written, overview row still `Planned`); **implement** one unticked Implementation Plan phase whose dependencies are ticked — tick it, commit; **finish** (Max loop → Ava → overview sync → run report) once every phase is ticked. | A feature is large enough that one session would hit context compaction mid-build. Each lap starts cold at a phase boundary. |

Agentic runs write no `checkpoint.md` — under auto-pilot there are no mid-chain stops, and under `--unit phase` the phase ticks in `feature.md` plus `run-status.md` are the handoff. If a session dies, the next `louie-continue` reconstructs the position from artifacts + git as always.

**Parking — one stuck feature does not stop the night.** When a run ends in `needs-human` (scope-defining gap, deviation tripwire, operator facts such as a registry or target hardware), that feature is *parked*: its run report holds the question, and the next `louie-continue --agentic` skips it — and anything that depends on it — and picks the next ready feature. The loop reports `needs-human` only when **nothing else can proceed**; its `Pending decision:` then lists every parked feature with its question, one per `<feature>: <question>` item separated by ` | `. The human answers them in the morning, in one sitting, and either builds those features interactively or lets the loop pick them up again. Deployment features are the typical case: the application gets built and tested overnight; the deploy stays yours.

### Run status (the handoff file)

`_LOUIE-output/run-status.md` is the one file the script reads. **Every `--agentic` run of every chain command writes it as its very last action** — in or out of the loop; a uniform contract is cheaper than a conditional one. Full overwrite, never append:

```markdown
# Run Status
- **Status:** completed | needs-human | blocked | done
- **Next:** feature <slug> | phase <n> of <slug> | review <slug> | none
- **Report:** <path of the run report this run wrote, or — >
- **Pending decision:** <only when needs-human: `<feature>: <question>`, several items separated by ` | `; else — >
- **Written:** <date> at <git HEAD short SHA>
```

| Status | Meaning | The script… |
|--------|---------|-------------|
| `completed` | This unit is finished and committed; `Next:` names what a fresh session should do | starts the next session |
| `done` | Nothing left: no in-progress work, no `Planned` feature with satisfied dependencies and a `requirements.md` | stops, exit 0 |
| `needs-human` | Nothing else can proceed: every remaining feature is parked (deviation tripwire, scope-defining gap, operator facts, missing task spec) or depends on a parked one; `Pending decision:` lists every parked `<feature>: <question>`, each run report has the detail | stops, prints the decisions, exit 10 |
| `blocked` | Environmental failure (prerequisites missing, tests can't run, setup would be needed) | stops, exit 11 |

A session that exits without writing the file is treated as a crash or timeout (exit 2) — the log in `.louie-run/` tells why; rerunning is safe. The script deletes the file before every launch so a stale verdict is never re-read, and it gitignores both the file and the log directory so no commit ever sweeps them up. Interactive commands ignore the file. The run report header carries the same `Next:` line (template: `_LOUIE_/templates/run-report-template.md`) so a report read on its own still says what follows.

### Harnesses

The script has exactly one harness-specific line: how to start a fresh non-interactive session with approvals handled. Everything else — the prompt, the status file, the loop — is shared. The prompt names the files to read (`agentic-mode.md`, `louie-continue.md`) instead of relying on an installed slash command, so it behaves identically on every runtime.

| Harness | Fresh unattended session | Approval handling | Source |
|---------|--------------------------|-------------------|--------|
| Claude Code | `claude -p "<prompt>" --permission-mode auto --permission-prompts none --output-format json` | Auto mode's classifier approves; anything that would still prompt is denied, never waited on. `LOUIE_CLAUDE_PERMISSION_MODE=bypassPermissions` only inside a container/VM. | Official docs |
| Codex CLI | `codex exec --sandbox workspace-write -o <file> "<prompt>"` | `exec` never prompts; approval requests are rejected and the run continues. Default sandbox is read-only, so the flag is required. | Docs + current source |
| Gemini CLI | `gemini --approval-mode yolo --output-format json -p "<prompt>"` (with `GEMINI_CLI_TRUST_WORKSPACE=true`) | `ask_user` resolves to deny when non-interactive; untrusted folders are fatal, hence the env var. | Official docs |
| opencode | `opencode run --auto --format json "<prompt>"` | `--auto` approves anything not explicitly denied in `opencode.json`. | Official docs |
| pi | `pi -p --approve "<prompt>"` | pi never prompts per tool call; `--approve` settles the project-trust decision headless mode cannot ask for (LOUIE's `.pi/prompts` are trust-gated). | Official docs |
| Cursor CLI | `agent -p --force --output-format json "<prompt>"` | `--force` approves non-denied commands and trusts the workspace. **Unverified** — flags come from search summaries of cursor.com; confirm before relying on it. | Second-hand |
| `custom` | `LOUIE_RUN_COMMAND='<your command>'`; the prompt arrives as `$LOUIE_PROMPT` | Yours. Any harness with a non-interactive mode plugs in here. | — |

`LOUIE_RUN_EXTRA_ARGS` appends flags to any of these (a budget cap, a model pin). Each tool starts a new session when no resume/continue flag is passed — Claude Code and Codex document that explicitly; for the others it follows from resume being opt-in.

### Hard limits (inherited, plus the loop's own)

- Everything under *Hard limits* above: never merges, never branches, never runs setup/import, halts rather than guesses.
- **Never calls the structured-choice tool.** No harness auto-approves a user-interaction tool in unattended mode; a call would hang or be denied. Agentic runs decide from the task spec or write `needs-human`.
- **Bounded.** `--max-runs` (default 20) caps sessions per invocation; `--timeout` caps one session. Both end with the work committed — rerun to continue.
- **Narrate anyway.** Chat output lands in the per-run log; it is the only trace of *how* a decision was reached.

## Composition with source adapters

`louie-from-source` (fetching tasks from an external tracker) and agentic mode are orthogonal layers that compose:

1. Fetch the task via `louie-from-source` — the adapter supplies `louie_type` routing and a concept document.
2. Run the routed command with `--agentic`; the concept is the task spec for the evidential gate.
3. Mirror the run-report `Status` back to the source system (`update_status`): `completed` → your "done/review" state, `needs-human`/`blocked` → your escalation state.

See `_LOUIE_/adapters/louie-source-adapter.md` and `_LOUIE_/commands/louie-from-source.md`.
