#!/usr/bin/env bash
# louie-run.sh — the LOUIE unattended loop (the "overseer").
#
# Starts ONE FRESH AI-harness session per unit of work, reads
# _LOUIE-output/run-status.md when that session has exited, and repeats until
# nothing is left to build or a human decision is pending. Every lap is exactly
# what a person does by hand today — open a new chat, paste "continue the LOUIE
# work", wait — minus the person. No chat history crosses a lap; the files in
# _LOUIE-output/ and git are the only memory, which is how LOUIE already resumes.
#
# Contract (what each run must do, what the status file looks like):
#   _LOUIE_/workflow/agentic-mode.md § Unattended loop
# Per-run behavior:
#   _LOUIE_/commands/louie-continue.md § Agentic
#
# Usage: bash _LOUIE_/tools/louie-run.sh [options]
#   --harness <name>     claude | codex | gemini | opencode | pi | cursor | custom
#                        (default: detected from the project folder, like install.sh)
#   --unit feature|phase what one fresh session finishes before it exits (default: feature)
#   --target <feature>   work only on this feature (default: louie-continue picks)
#   --max-runs <n>       stop after n sessions no matter what (default: 20)
#   --timeout <seconds>  kill a single session after this long; 0 = no limit (default: 0)
#   --pause <seconds>    wait between sessions (default: 0)
#   --once               run a single session and exit (handy for a first trial)
#   --quiet              no live progress view; only the per-run summary lines
#   --dry-run            print what would be launched and exit
#   -h, --help
#
# Live progress (default on): while a session runs, the terminal shows what the
# agent says, which tools it runs, new commits, and newly ticked feature.md
# phases — filtered from the harness's streaming output by louie-run-progress.py
# (python3) plus a 20-second poll of git and _LOUIE-output/. The raw stream is
# kept in the run log either way.
#
# Environment:
#   LOUIE_RUN_LOG_DIR            where per-run logs go (default: .louie-run/, gitignored)
#   LOUIE_RUN_EXTRA_ARGS         extra flags appended to the harness command (word-split)
#   LOUIE_CLAUDE_PERMISSION_MODE Claude Code permission mode (default: auto;
#                                bypassPermissions only inside a container/VM)
#   LOUIE_CODEX_SANDBOX          Codex sandbox (default: workspace-write)
#   LOUIE_RUN_COMMAND            --harness custom: a shell command line; the prompt is
#                                available to it as $LOUIE_PROMPT
#
# Exit codes: 0 all work done (or --once/--dry-run finished) · 2 a session ended
# without writing run-status.md (crash / timeout) · 10 needs-human · 11 blocked ·
# 12 --max-runs reached · 64 usage / preflight error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_DIR"

STATUS_FILE="_LOUIE-output/run-status.md"
LOG_DIR="${LOUIE_RUN_LOG_DIR:-.louie-run}"

HARNESS=""
UNIT="feature"
TARGET=""
MAX_RUNS=20
RUN_TIMEOUT=0
PAUSE=0
ONCE=0
DRY_RUN=0
QUIET=0
PROGRESS_PY="$SCRIPT_DIR/louie-run-progress.py"

usage() { sed -n '2,43p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die()   { echo "louie-run: $*" >&2; exit 64; }
say()   { echo "[louie-run] $*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --harness)  HARNESS="${2:-}"; shift 2 ;;
    --unit)     UNIT="${2:-}"; shift 2 ;;
    --target)   TARGET="${2:-}"; shift 2 ;;
    --max-runs) MAX_RUNS="${2:-}"; shift 2 ;;
    --timeout)  RUN_TIMEOUT="${2:-}"; shift 2 ;;
    --pause)    PAUSE="${2:-}"; shift 2 ;;
    --once)     ONCE=1; shift ;;
    --quiet)    QUIET=1; shift ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

case "$UNIT" in feature|phase) ;; *) die "--unit must be 'feature' or 'phase'" ;; esac
[[ "$MAX_RUNS" =~ ^[0-9]+$ ]] && [ "$MAX_RUNS" -ge 1 ] || die "--max-runs must be a positive integer"
[[ "$RUN_TIMEOUT" =~ ^[0-9]+$ ]] || die "--timeout must be a number of seconds"
[[ "$PAUSE" =~ ^[0-9]+$ ]] || die "--pause must be a number of seconds"

# ------------------------------------------------------------------ preflight
# Same prerequisite agentic mode has: the project must be established. Setup
# and import are human work and never run unattended.
[ -d "_LOUIE_" ] && [ -d "_LOUIE-output" ] || die "not a LOUIE project: $PROJECT_DIR"
if [ ! -f "_LOUIE-output/architecture.md" ] || [ ! -f "_LOUIE-output/tech-stack.md" ]; then
  die "project not established — run louie-setup (or louie-import) interactively first; unattended mode only builds what setup planned"
fi

# ------------------------------------------------------------ harness detect
# Mirrors install.sh's autodetection: the marker each init script leaves behind.
detect_harness() {
  local found=()
  [ -d ".claude" ]                                      && found+=("claude")
  [ -d ".codex" ]                                       && found+=("codex")
  { [ -d ".gemini" ] || [ -f "GEMINI.md" ]; }           && found+=("gemini")
  [ -d ".opencode" ]                                    && found+=("opencode")
  [ -d ".pi" ]                                          && found+=("pi")
  { [ -f ".cursorrules" ] || [ -d ".cursor" ]; }        && found+=("cursor")
  case ${#found[@]} in
    0) die "no AI harness detected in $PROJECT_DIR — pass --harness <claude|codex|gemini|opencode|pi|cursor|custom>" ;;
    1) HARNESS="${found[0]}" ;;
    *) die "several harnesses detected (${found[*]}) — pass --harness to pick one" ;;
  esac
}
[ -n "$HARNESS" ] || detect_harness

need_bin() { command -v "$1" >/dev/null 2>&1 || die "'$1' not found on PATH (harness: $HARNESS)"; }
CURSOR_BIN=""
case "$HARNESS" in
  claude)   need_bin claude ;;
  codex)    need_bin codex ;;
  gemini)   need_bin gemini ;;
  opencode) need_bin opencode ;;
  pi)       need_bin pi ;;
  cursor)
    if command -v agent >/dev/null 2>&1; then CURSOR_BIN="agent"
    elif command -v cursor-agent >/dev/null 2>&1; then CURSOR_BIN="cursor-agent"
    else die "neither 'agent' nor 'cursor-agent' found on PATH (harness: cursor)"; fi ;;
  custom)   [ -n "${LOUIE_RUN_COMMAND:-}" ] || die "--harness custom needs LOUIE_RUN_COMMAND (the prompt is passed as \$LOUIE_PROMPT)" ;;
  *) die "unknown harness: $HARNESS" ;;
esac

# Extra args from the environment, word-split on purpose (flags only, no prompt).
EXTRA=()
if [ -n "${LOUIE_RUN_EXTRA_ARGS:-}" ]; then
  # shellcheck disable=SC2206
  EXTRA=(${LOUIE_RUN_EXTRA_ARGS})
fi

# --------------------------------------------------------------- the prompt
# Harness-agnostic on purpose: it names the files to read instead of relying on
# a slash command being installed, so it works on every runtime the same way.
PROMPT="LOUIE unattended run. No human is available in this session: never ask a question, never wait for approval, never stop to confirm.
1. Read _LOUIE_/workflow/agentic-mode.md — all of it, including the section 'Unattended loop'.
2. Read _LOUIE_/commands/louie-continue.md and execute: louie-continue --agentic --unit ${UNIT}${TARGET:+ ${TARGET}}
3. Finish exactly one unit of work as that section defines it, commit it, then write _LOUIE-output/run-status.md in the format given in agentic-mode.md § Run status — as your very last action. The run does not count as finished without that file.
Hard limits: never merge, never create a branch, never run louie-setup or louie-import, never guess at a scope-defining question — write it into the run report with Status needs-human and stop."

# ------------------------------------------------------------ launch command
# One line per harness; everything else above and below is shared. Flags were
# verified against each tool's documentation (see agentic-mode.md § Harnesses).
build_cmd() {
  local last_msg="$1"
  case "$HARNESS" in
    claude)
      CMD=(claude -p "$PROMPT" --permission-mode "${LOUIE_CLAUDE_PERMISSION_MODE:-auto}" --permission-prompts none --output-format stream-json --verbose "${EXTRA[@]}") ;;
    codex)
      CMD=(codex exec --sandbox "${LOUIE_CODEX_SANDBOX:-workspace-write}" --json -o "$last_msg" "${EXTRA[@]}" "$PROMPT") ;;
    gemini)
      export GEMINI_CLI_TRUST_WORKSPACE=true
      CMD=(gemini --approval-mode yolo --output-format stream-json "${EXTRA[@]}" -p "$PROMPT") ;;
    opencode)
      CMD=(opencode run --auto --format json "${EXTRA[@]}" "$PROMPT") ;;
    pi)
      CMD=(pi --mode json --approve "${EXTRA[@]}" "$PROMPT") ;;
    cursor)
      CMD=("$CURSOR_BIN" -p --force --output-format stream-json "${EXTRA[@]}" "$PROMPT") ;;
    custom)
      CMD=(bash -c "$LOUIE_RUN_COMMAND") ;;
  esac
}

# ------------------------------------------------------------- status file
field() { grep -m1 -E "^- \*\*$1:\*\*" "$STATUS_FILE" 2>/dev/null | sed -E "s/^- \*\*$1:\*\*[[:space:]]*//" || true; }

ensure_ignored() {
  local entry="$1"
  [ -f .gitignore ] && grep -qxF "$entry" .gitignore && return 0
  { [ -f .gitignore ] && [ -n "$(tail -c1 .gitignore)" ] && echo; echo "$entry"; } >> .gitignore
  say "added '$entry' to .gitignore"
}

# ----------------------------------------------------------- live progress
# Two independent signals, so something shows on every harness:
#  1. the harness's streaming output, filtered to "says / tool / note" lines
#     (needs python3; silently skipped without it — the raw log still fills)
#  2. a poll of git + feature.md every 20s: new commits and newly ticked phases
HAVE_PY=0; command -v python3 >/dev/null 2>&1 && [ -f "$PROGRESS_PY" ] && HAVE_PY=1
if [ "$QUIET" -eq 0 ] && [ "$HAVE_PY" -eq 0 ]; then
  say "note: python3 not found — live view shows commits and ticked phases only; the raw stream is in the log"
fi

ticked_snapshot() { grep -h -E '^\s*- \[x\]' _LOUIE-output/implementations/*/feature.md 2>/dev/null | sort || true; }

poller() {   # $1 = starting commit; prints new commits and newly ticked phases
  local last="$1" before after line
  before="$(ticked_snapshot)"
  while :; do
    sleep 20
    if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
      git log --reverse --format='%h %s' "${last}..HEAD" 2>/dev/null | while IFS= read -r line; do
        [ -n "$line" ] && echo "$(date '+%H:%M:%S') [louie-run] commit: $line"
      done
      last="$(git rev-parse HEAD)"
    fi
    after="$(ticked_snapshot)"
    if [ "$after" != "$before" ]; then
      comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | while IFS= read -r line; do
        [ -n "$line" ] && echo "$(date '+%H:%M:%S') [louie-run] ticked: $(echo "$line" | sed -E 's/^\s*- \[x\]\s*//')"
      done
      before="$after"
    fi
  done
}

# ----------------------------------------------------------------- dry run
if [ "$DRY_RUN" -eq 1 ]; then
  build_cmd "$LOG_DIR/run-001-last-message.md"
  echo "harness:  $HARNESS"
  echo "unit:     $UNIT${TARGET:+ (target: $TARGET)}"
  echo "max runs: $MAX_RUNS   timeout: ${RUN_TIMEOUT}s   pause: ${PAUSE}s"
  echo "logs:     $LOG_DIR/"
  echo "command:"
  printf '  %q' "${CMD[@]}"; echo
  echo "prompt:"
  printf '%s\n' "$PROMPT" | sed 's/^/  | /'
  exit 0
fi

# -------------------------------------------------------------------- loop
if [ -n "$(git status --porcelain 2>/dev/null | grep -v -e "^?? ${LOG_DIR%/}/" -e "^?? ${STATUS_FILE}" -e " .gitignore$" || true)" ]; then
  say "warning: working tree has uncommitted changes; each run commits its own work on top of them"
fi
mkdir -p "$LOG_DIR"
ensure_ignored "${LOG_DIR%/}/"
ensure_ignored "$STATUS_FILE"

trap '[ -n "${poll_pid:-}" ] && kill "$poll_pid" 2>/dev/null; exit 130' INT TERM
say "harness=$HARNESS unit=$UNIT${TARGET:+ target=$TARGET} max-runs=$MAX_RUNS logs=$LOG_DIR/"
run=0
while :; do
  run=$((run + 1))
  if [ "$run" -gt "$MAX_RUNS" ]; then
    say "stopped: --max-runs $MAX_RUNS reached; work is committed, rerun to continue"
    exit 12
  fi

  n="$(printf '%03d' "$run")"
  log="$LOG_DIR/run-$n.log"
  rm -f "$STATUS_FILE"                     # never read a stale verdict
  build_cmd "$LOG_DIR/run-$n-last-message.md"

  say "run $n: starting a fresh $HARNESS session ($(date '+%H:%M:%S')) → $log"
  RUNNER=("${CMD[@]}")
  if [ "$RUN_TIMEOUT" -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    RUNNER=(timeout "$RUN_TIMEOUT" "${CMD[@]}")
  fi
  poll_pid=""
  if [ "$QUIET" -eq 0 ]; then
    poller "$(git rev-parse -q --verify HEAD 2>/dev/null || echo HEAD)" &
    poll_pid=$!
  fi
  rc=0
  if [ "$QUIET" -eq 0 ] && [ "$HAVE_PY" -eq 1 ]; then
    # stdout: tee'd to the log and filtered live; stderr: log only
    LOUIE_PROMPT="$PROMPT" "${RUNNER[@]}" </dev/null 2>>"$log" | tee -a "$log" | python3 "$PROGRESS_PY" "[$HARNESS] " || true
    rc=${PIPESTATUS[0]}
  else
    LOUIE_PROMPT="$PROMPT" "${RUNNER[@]}" </dev/null >>"$log" 2>&1 || rc=$?
  fi
  if [ -n "$poll_pid" ]; then kill "$poll_pid" 2>/dev/null || true; wait "$poll_pid" 2>/dev/null || true; fi

  if [ ! -f "$STATUS_FILE" ]; then
    say "run $n: session exited (code $rc) without writing $STATUS_FILE — treating as a crash or timeout."
    say "        inspect $log, then rerun; louie-continue reconstructs the position from the files."
    exit 2
  fi

  status="$(field Status)"
  next="$(field Next)"
  report="$(field Report)"
  pending="$(field 'Pending decision')"
  say "run $n: status=$status next=${next:-?}${report:+ report=$report}"

  case "$status" in
    done)
      say "all planned work is built. Review the run reports and the diff; merging is yours."
      exit 0 ;;
    needs-human)
      say "stopped: everything still buildable is built; the rest is parked and needs you."
      [ -n "$pending" ] && say "        parked:   $pending"
      [ -n "$report" ]  && say "        report:   $report"
      say "        answer the questions (interactively, or in the docs), then rerun — or build those features yourself."
      exit 10 ;;
    blocked)
      say "stopped: the run is blocked (environment / prerequisites)."
      [ -n "$report" ] && say "        report: $report"
      exit 11 ;;
    completed)
      if [ "$ONCE" -eq 1 ]; then
        say "--once: one unit finished; next would be: ${next:-?}"
        exit 0
      fi
      [ "$PAUSE" -gt 0 ] && sleep "$PAUSE"
      ;;
    *)
      say "run $n: unrecognized Status '$status' in $STATUS_FILE — stopping rather than guessing."
      exit 2 ;;
  esac
done
