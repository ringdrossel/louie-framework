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
| opencode | `opencode run --auto --format json …` | `packages/web/src/content/docs/{cli,permissions}.mdx` (docs source). `--auto` approves anything not explicitly denied; exit codes undocumented. |
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

## Review mode in unattended runs

First real test (2026-11-07): the project was on `auto-fix-all`, yet the unattended session ran Max at `auto-fix-critical`. `reviewer.md` had the floor right ("never downgrades"), but `agentic-mode.md` — the file the loop's prompt tells every session to read first — said literally "Max (`auto-fix-critical` loop)", and the shorter sentence won. Lesson recorded: **the contract doc a fresh session reads first must carry the full rule, not a shorthand that is only correct with another file in mind.**

The rule itself was also changed, not just restated. Interactive auto-pilot floors at `auto-fix-critical` because a person reads the pre-merge summary and can approve the deferred Suggestions. In an unattended run nobody does, and the maintainer's stated goal is *a finished application to test in the morning*. So agentic runs floor at **`auto-fix-all`**: `auto-fix-all` stays, an explicit `auto-fix-critical` is honoured (the user chose less churn on purpose; Suggestions are listed as deferred in the run report), `manual` or unset becomes `auto-fix-all`. Per-run effective value, runbook untouched — same discipline as every other mode composition.

## Parking (why one stuck feature does not stop the night)

Same first test: the scope split had produced a `docker-deploy` feature. Tom's evidential gate correctly refused to guess the container registry and the NAS's CPU architecture and halted with `needs-human` — and the script, as first shipped, stopped the whole loop on the first `needs-human`. That wasted the night over a feature the user never wanted built unattended: deploying is their job, after they have tested the finished application.

Two changes. **A hard limit:** agentic runs never deploy, publish, or provision infrastructure, and never guess or probe operator facts (registries, hosts, credentials, target hardware). Deployment features are therefore `needs-human` by construction. **Parking:** `louie-continue --agentic` skips a feature whose run report is an unanswered `needs-human` — and anything depending on it — and builds the next ready feature. The loop reports `needs-human` only when nothing else can proceed, with every parked `<feature>: <question>` in one `Pending decision:` line. The morning review then answers all of them in one sitting instead of one per night. No new state: the parked feature's run report *is* the parking record, and an answer written into `decisions.md` / `requirements.md` § Assumptions makes it an ordinary candidate again.

## Selection order in `louie-continue --agentic`

Deliberately conservative: setup → `blocked`; an unanswered `needs-human` → parked (skipped with its dependants), never redone or guessed, re-surfaced only when nothing else is ready; in-progress before `Planned`; `Planned` only when dependencies are satisfied **and** a `requirements.md` exists (otherwise there is no task spec for Tom's evidential gate → `needs-human`, not a guess); content rows (game profile) after all features; nothing left → `done`. Every rule has a non-guessing failure mode, which is what lets the loop run unsupervised.

## What was deliberately not built

- **A Windows driver (`.ps1`/`.bat`).** No PowerShell in the dev loop to test it; parked in `BACKLOG.md`.
- **A notification channel.** The script prints and exits with a distinct code per outcome; wiring that to a phone is the user's shell, per `agentic.md` § Non-goals.
- **A stored "unattended" setting.** Same reason agentic mode has none: a runbook flag would leak into a human session and strip its gates. The script passes `--agentic` on every invocation.
- **Running setup unattended.** Deciding what the project *is* stays a human sitting (Critical Rule #2); the script refuses to start without `architecture.md` + `tech-stack.md`.
- **In-session alternatives** (Stop-hook block loops, `/goal`, a subagent per phase). All keep the user in interactive permission prompts and none gives a new top-level session; documented in the research but not shipped.

## Files touched

- `_LOUIE_/tools/louie-run.sh` — the loop (new folder; `install.sh` chmods it, `louie-update-framework` replaces it)
- `_LOUIE_/workflow/agentic-mode.md` § Unattended loop / § Run status / § Harnesses
- `_LOUIE_/commands/louie-continue.md` § Agentic (+ usage)
- `_LOUIE_/commands/louie-{feature,extend,update,bugfix,content}.md` § Agentic — the run-status bullet; `louie-feature` also `--unit phase`
- `_LOUIE_/commands/louie-setup.md` step 13 — names the option
- `_LOUIE_/templates/run-report-template.md` — `Next:` header line
- `README.md`, `_LOUIE_/setup/project-setup.md`, `_LOUIE_/workflow/ai-workflow.md` — user docs
