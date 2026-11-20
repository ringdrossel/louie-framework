# Unattended Loop

**Audience:** AI assistants working on the LOUIE framework. Design notes for the unattended loop — `_LOUIE_/tools/louie-run.sh` plus the `run-status.md` contract and `louie-continue --agentic`. Companion to `agentic.md` (which governs how gates resolve *inside* one run); this file governs how runs are *chained*.

## Problem

A new project with a written concept goes through `louie-setup` and leaves N features `Planned`. Building them interactively meant, per feature: confirm, confirm, confirm; the chain runs; the runtime (Claude Code in the maintainer's case) recommends a fresh chat for the next phase because the context is contaminated; the user asks for a continuation prompt, copies it, opens a new chat, pastes, confirms again. Each handoff waited for a human who was not at the keyboard — hours lost per night on a mechanical ritual.

Two separate things were being confirmed, which is why neither auto-pilot nor agentic mode alone fixed it:

1. **Harness permission prompts** (edit this file? run this command?) — the runtime's layer, outside LOUIE's reach.
2. **LOUIE's own gates** — already solvable with `--agentic`, but agentic mode was designed for an *external* orchestrator (OpenClaw, Hermes, a tracker queue) to drive. Nothing in LOUIE *started* the next run.

And the "start a new chat" step had no automation at all: a running session cannot open a new one.

## The mental model: files are the memory, so the overseer can be dumb

The key constraint, checked against each runtime's documentation (2026-11): **no harness lets a running session spawn a new top-level session or clear its own context.** Stop hooks can refuse to stop and inject a follow-up, but that continues the *same* context. Scheduled tasks fire into the same session. So an "overseer agent inside the chat" cannot do the one thing wanted.

What every harness *does* document is a non-interactive one-shot mode (`claude -p`, `codex exec`, `gemini -p`, `opencode run`, `pi -p`, `agent -p`) that starts a **fresh session by default** when no resume flag is passed. A shell loop over such invocations *is* "open a new chat and paste the prompt", minus the person.

That loop can be a dumb script because LOUIE already made the handoff file-based: `checkpoint.md`, the `feature.md` phase ticks, the overview statuses, git, the run report. `louie-continue` reconstructs the position cold from those — by design, without chat history. The loop adds one more file (`run-status.md`) and otherwise reuses everything. This is the same reasoning as `execution-guidelines.md` § Seeding a subagent: if a fresh context needs something that is not in the artifacts, that is a handoff gap to fix in the docs, not a reason to pass chat history.

The overseer being a script rather than an agent is a feature: zero tokens, deterministic, and it cannot talk itself into a different plan at 3 a.m.

## Layering (why this generalizes across harnesses)

| Layer | Lives in | Harness-specific? |
|-------|----------|-------------------|
| The per-run procedure (`louie-continue --agentic`, units, selection order) | `_LOUIE_/commands/louie-continue.md` § Agentic | No |
| The handoff file (`run-status.md`), written by every `--agentic` run | `_LOUIE_/workflow/agentic-mode.md` § Run status; one bullet in each chain command's § Agentic | No |
| The loop (launch, wait, read, decide) | `_LOUIE_/tools/louie-run.sh` | No |
| **The launch line** (how to start one fresh non-interactive session with approvals handled) | `build_cmd()` in the script — one `case` arm per harness | **Yes — the only one** |

The prompt the script sends names the files to read (`agentic-mode.md`, `louie-continue.md`) instead of a slash command, so it does not depend on each harness's command-install location (`.claude/commands`, `.codex/skills`, `.pi/prompts`, …). Same shape as the `*-init.sh` family: real per-tool differences stay in one small table.

`--harness custom` + `LOUIE_RUN_COMMAND` (prompt in `$LOUIE_PROMPT`) is the escape hatch for any tool with a one-shot mode — and the test seam: the loop was verified with a fake harness that walks every exit path (completed → completed → done, needs-human, crash, `--once`, `--max-runs`).

## Per-harness launch lines and their evidence

All verified against official documentation or source on 2026-11-06, except Cursor.

| Harness | Line | Evidence and caveats |
|---------|------|----------------------|
| Claude Code | `claude -p … --permission-mode auto --permission-prompts none --output-format json` | code.claude.com/docs/en/headless, permission-modes, cli-reference. Auto mode = a classifier approves instead of the user; still prompts for a short "no mode auto-approves" list, which `--permission-prompts none` (v2.1.259+) turns into denials so nothing hangs. `AskUserQuestion` is on that list for *every* mode — hence the hard rule that agentic runs never call the structured-choice tool. `--bare` "will become the default for -p in a future release" and skips CLAUDE.md/hooks/skills — watch for the flag that disables it. `bypassPermissions` is documented as "isolated containers and VMs only", exposed via `LOUIE_CLAUDE_PERMISSION_MODE`. |
| Codex CLI | `codex exec --sandbox workspace-write -o <file> …` | v0.50 `docs/exec.md` ("Non-interactive mode does not ask for command or edit approvals") + current `codex-rs` source. Default exec sandbox is read-only. `--full-auto`, present in older docs, is absent from current source — not used. Approval requests in exec are rejected and the run continues. Whether `exec` loads AGENTS.md identically to the TUI is not documented — the prompt therefore names the LOUIE files explicitly. |
| Gemini CLI | `gemini --approval-mode yolo --output-format json -p …`, env `GEMINI_CLI_TRUST_WORKSPACE=true` | `docs/cli/headless.md`, `reference/policy-engine.md` (`ask_user` → deny when non-interactive), `cli/trusted-folders.md` (untrusted folder is fatal headless). `-y/--yolo` is deprecated in favour of `--approval-mode`. Exit codes documented (0/1/42/53) but the script does not rely on them. |
| opencode | `opencode run --auto --format json …` (`--dangerously-skip-permissions` on some releases) | `packages/web/src/content/docs/{cli,permissions}.mdx` (docs source) named `--auto`. **2026-11-20, opencode 1.15.13 installed locally: `--auto` no longer exists** — `opencode run --auto` prints the help and exits 1, which the loop would have counted as a crash three times and stopped. The flag is now `--dangerously-skip-permissions` ("auto-approve permissions that are not explicitly denied"). Upgrading to 1.19.6 the same day: `--auto` is back and `--dangerously-skip-permissions` is gone again — the flag is not stable across releases, so the script asks `opencode run --help` which one the installed version has instead of pinning either. The shell-tool facts below (no background mode, 120 s default, kill on timeout) were re-checked on 1.19.6 and are unchanged. Exit codes undocumented. |
| pi | `pi -p --approve …` | `packages/coding-agent/docs/{cli,security,cli-integration}.md`. pi never prompts per tool call; project trust (`.pi/prompts` etc.) cannot be asked for in print mode, so `--approve` is required or LOUIE's prompts are silently skipped. |
| Cursor CLI | `agent -p --force --output-format json …` | **Unverified.** cursor.com was unreachable from the research session; flags come from search-engine summaries of the official pages. Marked as such in every user-facing table. |

The script never trusts exit codes (undocumented on three of six harnesses). The verdict is `run-status.md`; a missing file is a crash; `--timeout` and `--max-runs` bound the rest.

## Units

`--unit feature` (default) is one whole remaining feature chain per session — the granularity the plan-agreement gate normally approves. `--unit phase` exists because the original pain was Claude Code recommending a fresh chat *per phase*: a large feature can exhaust a context mid-build. A `phase`-unit session finishes exactly one of plan / one Implementation Plan phase / finish (Max → Ava → report), each a boundary `louie-continue` already infers (step 6 of its procedure). No new state: `feature.md` ticks + `run-status.md` are the handoff. Agentic runs write no `checkpoint.md` — there are no mid-chain stops to record chat-only decisions from.

## `run-status.md` vs. the run report

Why a second file: the run report is per feature (`implementations/<feature>/run-report.md`) and the driver would have to *find* the latest one. `run-status.md` is one fixed path, five lines, with `Report:` pointing at the prose. The run report header gained a matching `Next:` line so a report read on its own still says what follows.

Lifecycle rules, and why:

- **Written by every `--agentic` run, in or out of the loop.** A conditional contract ("only when driven by the script") would be invisible to the agent writing it; a uniform one is cheap.
- **Deleted by the script before every launch.** A session that dies must not leave the previous verdict to be re-read.
- **Gitignored by the script** (together with `.louie-run/`). Agentic runs commit; without the ignore, the file would churn through every commit.
- **Not consumed by interactive commands.** It is the driver's file. `louie-status` may show it; nothing else reads it.

## Live progress

First test, third finding: with `--output-format json` the run log stayed empty until the session ended, and a person in a `tmux` pane saw nothing for the length of a feature. Two signals were added, chosen so that at least one works everywhere. (1) Every harness is started in its line-delimited streaming format (Claude Code `stream-json --verbose`, Codex `--json`, Gemini `stream-json`, opencode `--format json`, pi `--mode json`, Cursor `stream-json`) and tee'd through `louie-run-progress.py`. The filter is deliberately **shape-based, not harness-based**: it walks each JSON object and reacts to `text`, `tool_use{name,input}`, `agent_message`, `command_execution{command}`, `file_change`, `system/task_summary{detail}` and `result` wherever they occur, prints each distinct text once, and prints nothing for anything else. Claude Code's shapes were confirmed by running `claude -p … --output-format stream-json --verbose` and reading the events (the docs give the SDK types but no CLI examples); the other harnesses' event names come from their docs and degrade to silence if the field names differ. (2) A 20-second poller prints new commits (`git log last..HEAD`) and newly ticked `- [x]` lines across `implementations/*/feature.md` — harness-independent, zero schema. `--quiet` disables both; the raw stream is always in the log. Without `python3` only the poller runs, and the script says so once.

## Review mode in unattended runs

First real test (2026-11-07): the project was on `auto-fix-all`, yet the unattended session ran Max at `auto-fix-critical`. `reviewer.md` had the floor right ("never downgrades"), but `agentic-mode.md` — the file the loop's prompt tells every session to read first — said literally "Max (`auto-fix-critical` loop)", and the shorter sentence won. Lesson recorded: **the contract doc a fresh session reads first must carry the full rule, not a shorthand that is only correct with another file in mind.**

The rule itself was also changed, not just restated. Interactive auto-pilot floors at `auto-fix-critical` because a person reads the pre-merge summary and can approve the deferred Suggestions. In an unattended run nobody does, and the maintainer's stated goal is *a finished application to test in the morning*. So agentic runs floor at **`auto-fix-all`**: `auto-fix-all` stays, an explicit `auto-fix-critical` is honoured (the user chose less churn on purpose; Suggestions are listed as deferred in the run report), `manual` or unset becomes `auto-fix-all`. Per-run effective value, runbook untouched — same discipline as every other mode composition.

## Parking (why one stuck feature does not stop the night)

Same first test: the scope split had produced a `docker-deploy` feature. Tom's evidential gate correctly refused to guess the container registry and the NAS's CPU architecture and halted with `needs-human` — and the script, as first shipped, stopped the whole loop on the first `needs-human`. That wasted the night over a feature the user never wanted built unattended: deploying is their job, after they have tested the finished application.

Two changes. **A hard limit:** agentic runs never deploy, publish, or provision infrastructure, and never guess or probe operator facts (registries, hosts, credentials, target hardware). Deployment features are therefore `needs-human` by construction. **Parking:** `louie-continue --agentic` skips a feature whose run report is an unanswered `needs-human` — and anything depending on it — and builds the next ready feature. The loop reports `needs-human` only when nothing else can proceed, with every parked `<feature>: <question>` in one `Pending decision:` line. The morning review then answers all of them in one sitting instead of one per night. No new state: the parked feature's run report *is* the parking record, and an answer written into `decisions.md` / `requirements.md` § Assumptions makes it an ordinary candidate again.

## Selection order in `louie-continue --agentic`

Deliberately conservative: setup → `blocked`; an unanswered `needs-human` → parked (skipped with its dependants), never redone or guessed, re-surfaced only when nothing else is ready; in-progress before `Planned`; `Planned` only when dependencies are satisfied **and** a `requirements.md` exists (otherwise there is no task spec for Tom's evidential gate → `needs-human`, not a guess); content rows (game profile) after all features; nothing left → `done`. Every rule has a non-guessing failure mode, which is what lets the loop run unsupervised.

## Run tasks

Second real use (2026-11-20): the maintainer built four dependent features of one project overnight from a hand-written tracker task (typed `feature`, opening with "This is a run task, not a feature…") plus a project-local `overnight.sh` wrapping `louie-run.sh`. Each such night needed the same explanation to the AI: one orchestrator session, every sub-task in its own fresh session, unattended until ready for human testing. `louie-spec-run` (writes the spec), `louie-run` (executes it) and `_LOUIE_/templates/run-template.md` make that a task type.

**Two commands, not one with a `new` mode.** First cut was `louie-run new`; the maintainer rejected it because `louie-run …` reads as "a run starts now". Writing the spec and running it happen in different sessions anyway (the spec closes the ideation conversation; the run starts cold), so they are separate commands, and `louie-spec-run` states that it never starts `louie-run`.

**Natural-language trigger, in the always-loaded file.** The maintainer's flow is to ask mid-conversation — "make a run task from these parts" — not to remember a command. Only the context file (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `.cursorrules`) is loaded in every session (`core.md` § lazy loading), so the trigger sentence lives there, in root `CLAUDE.md` and every init script's generated block, next to the "Operating autonomously?" line it mirrors. The same sentence names the other direction: a description starting `# RUN` is executed with `louie-run`; the template's first paragraph says so too, so an AI handed the task outside `louie-from-source` still recognises it.

**Shape: an agent orchestrator around the dumb loop.** The parts that need a person — a login in a browser window, recording fixtures, live acceptance — sit before and after the build and need conversation, so the orchestrator is an agent session: the user's own, opened with `louie-from-source <id>`. The build in the middle stays the script, for the reasons in § The mental model: an agent driving every sub-task in-session would fill its context over a night and sit in permission prompts. The orchestrator never builds anything itself; it starts the script detached and waits on the runtime's background-job notification.

**The spec lives in the task description**, not in a repo file (maintainer's call: transparency in the tracker, and the AI reads it from there). Without a tracker the same template is a local file — the framework does not depend on a tracker for runs. Steps are tagged `[human]` / `[agent]` and must be written so their outcome is checkable; that is what makes rerunning the orchestrator safe without a progress file.

**Scoping: `--only`.** Without it the loop builds whatever `Planned` feature is next, which may not belong to the run. `--only a,b,…` is passed through the prompt to `louie-continue --agentic`, whose selection rules then see only those features; a listed feature depending on an unbuilt feature outside the list is parked with that as its question, never silently extended into the dependency. `--target` and `--only` exclude each other.

**Standing rules reach sessions through `requirements.md` § Constraints**, not the prompt. The prompt is fixed and harness-agnostic; every fresh session already reads the feature's requirements, and a rule written there also survives a manual rerun without the orchestrator.

**Crash retry moved into the script.** `overnight.sh` retried a crashed session up to three times in a row; every run needs that, so `louie-run.sh` now does it (`--max-crashes`, default 3; `--once` never retries). A retry is safe because a fresh session reconstructs from files — the same argument as the loop itself.

**Waiting: `louie-run-bg.sh`, chunked, on every harness.** The first cut said "start the loop detached and wait for the runtime's background-job notification (Claude Code)". Checked against opencode 1.15.13 (tool schema and source read from the installed binary, 2026-11-20): the shell tool has only `command`, `timeout` (ms), `workdir`, `description` — no background mode, no completion notification; the default timeout is 120 s (`OPENCODE_EXPERIMENTAL_BASH_DEFAULT_TIMEOUT_MS`), a passed `timeout` has no upper cap, and on timeout the tool kills the command it spawned. So an orchestrator on opencode could neither be woken nor safely `&` the loop. The fix is harness-independent: `_LOUIE_/tools/louie-run-bg.sh start` runs `louie-run.sh` under `setsid nohup` (own session — survives the tool's kill and the orchestrator's exit; `set -m` fallback on macOS), the child writes its own pid (setsid may fork, so `$!` is wrong) and the loop's exit code to `.louie-run/loop.exit`; `wait --max <s>` blocks at most that long and exits 3 while running, 0 when finished; `start` refuses while a loop runs, so a rerun of the orchestrator resumes waiting instead of starting a second loop. Chunk sizes per harness are a table in `louie-run.md` (Claude Code 540 s / 600 s tool max; opencode 1800 s with an explicit timeout; unknown 100 s). Tested: loop survives a SIGKILL of the calling process group; double start refused; chunked wait returns the loop's exit code (0 on done, 2 on three crashes); a loop killed from outside reports `exit 2`. A real opencode + GLM run of the orchestrator was attempted but blocked by the test sandbox (opencode downloads ripgrep from GitHub on first start); still to do on the maintainer's machine.

**No tracker sub-tasks — the spec's `## Sub-tasks` list is the relationship** (decided 2026-11-20 with the maintainer). Real parent/child links in the tracker were considered and rejected for now:

- *Two sources of truth.* The spec must keep the dependencies and build order anyway (a parent/child link cannot say "`f95-updates` waits for `f95-discover`"), so tracker links would duplicate the list and drift from it — a task moved in the UI, the spec unchanged, and `louie-run` forced to decide which wins.
- *Cost in three places.* Tracker schema/API/UI, new optional adapter operations (link, list children), and reconciliation logic in `louie-run` — for every tracker, since `_LOUIE_/` stays tracker-agnostic.
- *What links would buy* — navigation and an "n of m done" view, protection against a Ready sub-task being claimed by another session before the run claims it, visible progress during the night — is mostly reachable without them: the tracker can **derive** the link from the spec (render `#123` as links; for a `run` task, parse `## Sub-tasks` and show "part of run #N" on each sub-task — display only, so it cannot drift); `louie-spec-run` already leaves new sub-tasks in their creation state (not pickup-able); progress is a separate, small orchestrator change (BACKLOG).
- *Revisit when* runs grow large (10+ sub-tasks), several runs share tasks, or the user wants to start/stop individual sub-tasks from the tracker UI — then the tracker steers rather than displays, and real links pay off.

**Not taken from `overnight.sh`:** mirroring each run report into its tracker task after every session. The maintainer found a sync hook overcomplicated; the orchestrator writes every sub-task's resolution once, at handoff, through the adapter's `update_task`. Parallel sub-tasks are also out (one working tree; would need a worktree per feature and sequential merges).

## What was deliberately not built

- **A Windows driver (`.ps1`/`.bat`).** No PowerShell in the dev loop to test it; parked in `BACKLOG.md`.
- **A notification channel.** The script prints and exits with a distinct code per outcome; wiring that to a phone is the user's shell, per `agentic.md` § Non-goals.
- **A stored "unattended" setting.** Same reason agentic mode has none: a runbook flag would leak into a human session and strip its gates. The script passes `--agentic` on every invocation.
- **Running setup unattended.** Deciding what the project *is* stays a human sitting (Critical Rule #2); the script refuses to start without `architecture.md` + `tech-stack.md`.
- **In-session alternatives** (Stop-hook block loops, `/goal`, a subagent per phase). All keep the user in interactive permission prompts and none gives a new top-level session; documented in the research but not shipped.

## Files touched

- `_LOUIE_/tools/louie-run.sh` — the loop (new folder; `install.sh` chmods it, `louie-update-framework` replaces it)
- `_LOUIE_/tools/louie-run-progress.py` — the shape-based live-progress filter
- `_LOUIE_/tools/louie-run-bg.sh` — detached start + bounded wait for the `louie-run` orchestrator
- `_LOUIE_/commands/louie-spec-run.md`, `_LOUIE_/commands/louie-run.md`, `_LOUIE_/templates/run-template.md` — run tasks
- `_LOUIE_/workflow/agentic-mode.md` § Unattended loop / § Run status / § Harnesses
- `_LOUIE_/commands/louie-continue.md` § Agentic (+ usage)
- `_LOUIE_/commands/louie-{feature,extend,update,bugfix,content}.md` § Agentic — the run-status bullet; `louie-feature` also `--unit phase`
- `_LOUIE_/commands/louie-setup.md` step 13 — names the option
- `_LOUIE_/templates/run-report-template.md` — `Next:` header line
- `README.md`, `_LOUIE_/setup/project-setup.md`, `_LOUIE_/workflow/ai-workflow.md` — user docs
