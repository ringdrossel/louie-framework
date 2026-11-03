#!/usr/bin/env bash
# Start GameLog in the background. Usage: ./start.sh [--prod] [--dev]  (--dev = GAMELOG_DB=dev: use gamelog_dev)
set -euo pipefail
cd "$(dirname "$0")"

RUN_DIR="data/run"
PID_FILE="$RUN_DIR/app.pid"
LOG_FILE="$RUN_DIR/app.log"

env_value() {
  grep -E "^$1=" .env.local 2>/dev/null | tail -n1 | cut -d= -f2- | sed 's/[[:space:]]*#.*//' | tr -d '" ' || true
}

PORT="${PORT:-$(env_value PORT)}"
PORT="${PORT:-3000}"
MODE="dev"
for arg in "$@"; do
  case "$arg" in
    --prod) MODE="prod" ;;
    --dev) export GAMELOG_DB="dev" ;;
    *) echo "Unknown option: $arg (usage: ./start.sh [--prod] [--dev])"; exit 1 ;;
  esac
done

mkdir -p "$RUN_DIR"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "GameLog is already running (PID $(cat "$PID_FILE")) on http://localhost:$PORT"
  exit 0
fi

# WHY: like Next, a defined (even empty) env var wins over .env.local; prints only the DB name.
print_target_database() {
  local selection="${GAMELOG_DB-$(env_value GAMELOG_DB)}" variable="DATABASE_URL" url name
  [[ "$selection" == "dev" ]] && variable="DEV_DATABASE_URL"
  if [[ -v $variable ]]; then url="${!variable}"; else url="$(env_value "$variable")"; fi
  # WHY: only a postgres URL with a /db path yields a name; anything else could echo host or credentials.
  name="<unparseable>"
  if [[ "$url" =~ ^postgres(ql)?://[^/]+/([A-Za-z0-9_.-]+)(\?.*)?$ ]]; then name="${BASH_REMATCH[2]}"; fi
  echo "Database: $name (GAMELOG_DB=${selection:-unset})"
}

print_target_database

if [[ "$MODE" == "prod" ]]; then
  echo "Building production bundle..."
  pnpm build >"$LOG_FILE" 2>&1 || { echo "Build failed — see $LOG_FILE"; exit 1; }
  COMMAND="start"
else
  COMMAND="dev"
fi

# WHY: setsid gives the app its own process group so stop.sh can kill pnpm + next together.
PORT="$PORT" setsid nohup pnpm "$COMMAND" >>"$LOG_FILE" 2>&1 </dev/null &
echo $! >"$PID_FILE"

for _ in $(seq 1 30); do
  if curl -s -o /dev/null "http://localhost:$PORT/login"; then
    echo "GameLog ($MODE) running on http://localhost:$PORT (PID $(cat "$PID_FILE"), log: $LOG_FILE)"
    exit 0
  fi
  if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "GameLog exited during startup — see $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
  fi
  sleep 1
done

echo "GameLog started (PID $(cat "$PID_FILE")) but did not answer within 30s — check $LOG_FILE"
exit 1
