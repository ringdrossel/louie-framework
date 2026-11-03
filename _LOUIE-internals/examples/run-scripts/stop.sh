#!/usr/bin/env bash
# Stop the background GameLog process started by start.sh.
set -euo pipefail
cd "$(dirname "$0")"

PID_FILE="data/run/app.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "GameLog is not running (no PID file)."
  exit 0
fi

PID="$(cat "$PID_FILE")"
if ! kill -0 -- "-$PID" 2>/dev/null && ! kill -0 "$PID" 2>/dev/null; then
  echo "GameLog is not running (stale PID $PID) — cleaning up."
  rm -f "$PID_FILE"
  exit 0
fi

is_group_alive() { kill -0 -- "-$PID" 2>/dev/null; }

kill -TERM -- "-$PID" 2>/dev/null || kill -TERM "$PID" 2>/dev/null || true
for _ in $(seq 1 10); do
  is_group_alive || break
  sleep 1
done
if is_group_alive; then
  echo "Processes did not stop after 10s — forcing."
  kill -KILL -- "-$PID" 2>/dev/null || true
fi

rm -f "$PID_FILE"
echo "GameLog stopped."
