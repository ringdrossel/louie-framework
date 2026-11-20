#!/usr/bin/env bash
# louie-run-bg.sh — run the unattended loop detached, and wait for it in
# bounded chunks. Used by the louie-run orchestrator on every harness.
#
# Why: an orchestrator session must wait hours for louie-run.sh, but agent
# shell tools kill long commands (opencode: 120 s default; Claude Code: 10 min
# max) and most cannot notify a session when a background job ends. So the loop
# runs in its own session (setsid — it survives the tool's kill and the
# orchestrator's exit) and `wait` returns after at most --max seconds; the
# orchestrator simply calls it again until the loop has finished.
#
# Usage: bash _LOUIE_/tools/louie-run-bg.sh start [louie-run.sh options]
#        bash _LOUIE_/tools/louie-run-bg.sh wait [--max <seconds>]   (default 100)
#        bash _LOUIE_/tools/louie-run-bg.sh status
#
# Files (in .louie-run/, gitignored by louie-run.sh): loop.log (all output),
# loop.pid, loop.exit (the loop's exit code, written when it ends).
#
# Exit codes of `wait` / `status`: 0 the loop has finished (its own exit code is
# printed as "finished: exit <n>") · 3 still running · 4 no loop started ·
# 64 usage error. `start`: 0 started · 1 a loop is already running · 64 usage.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_DIR"

DIR="${LOUIE_RUN_LOG_DIR:-.louie-run}"
LOG="$DIR/loop.log"; PIDF="$DIR/loop.pid"; EXITF="$DIR/loop.exit"

die() { echo "louie-run-bg: $*" >&2; exit 64; }
alive() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; }

report() {   # prints the state; returns 0 finished / 3 running / 4 none
  if [ -f "$EXITF" ]; then
    echo "finished: exit $(cat "$EXITF")"
    tail -n 15 "$LOG" 2>/dev/null
    return 0
  fi
  if alive; then
    echo "running (pid $(cat "$PIDF")); last lines of $LOG:"
    tail -n 5 "$LOG" 2>/dev/null
    return 3
  fi
  if [ -f "$PIDF" ]; then
    # Killed from outside (reboot, kill -9) before it could record an exit code.
    echo "finished: exit 2 (the loop process is gone without an exit code — treat as a crash; see $LOG)"
    return 0
  fi
  echo "no loop started (no $PIDF)"
  return 4
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  start)
    mkdir -p "$DIR"
    if alive; then echo "a loop is already running (pid $(cat "$PIDF")); use: wait"; exit 1; fi
    rm -f "$EXITF" "$PIDF"
    : > "$LOG"
    # The child records its own pid (setsid may fork, so $! is not it) and,
    # when the loop ends, the loop's exit code.
    runner=(bash -c 'echo $$ >"$LOUIE_BG_PID"; bash "$0" "$@" >>"$LOUIE_BG_LOG" 2>&1; echo $? >"$LOUIE_BG_EXIT"' "$SCRIPT_DIR/louie-run.sh" "$@")
    export LOUIE_BG_LOG="$LOG" LOUIE_BG_EXIT="$EXITF" LOUIE_BG_PID="$PIDF"
    if command -v setsid >/dev/null 2>&1; then
      setsid nohup "${runner[@]}" </dev/null >/dev/null 2>&1 &
    else
      # macOS ships no setsid: job control gives the child its own process group.
      set -m; nohup "${runner[@]}" </dev/null >/dev/null 2>&1 & set +m
    fi
    for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$PIDF" ] && break; sleep 0.2; done
    [ -s "$PIDF" ] || { echo "louie-run-bg: the loop did not start; see $LOG" >&2; exit 1; }
    echo "started (pid $(cat "$PIDF")); log: $LOG — now call: bash _LOUIE_/tools/louie-run-bg.sh wait"
    ;;
  wait)
    max=100
    while [ $# -gt 0 ]; do
      case "$1" in
        --max) max="${2:-}"; shift 2 ;;
        *) die "unknown option: $1" ;;
      esac
    done
    [[ "$max" =~ ^[0-9]+$ ]] || die "--max must be a number of seconds"
    end=$(( $(date +%s) + max ))
    while :; do
      if [ -f "$EXITF" ] || ! alive; then report; exit $?; fi
      [ "$(date +%s)" -ge "$end" ] && break
      sleep 5
    done
    report; exit $?
    ;;
  status) report; exit $? ;;
  ""|-h|--help) sed -n '2,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) die "unknown command: $cmd (start | wait | status)" ;;
esac
