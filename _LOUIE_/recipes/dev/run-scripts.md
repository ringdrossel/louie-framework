Add start / stop / restart scripts that run a web app in the background with a PID file, a log, and a readiness check — `.sh` for Linux and macOS, `.bat` + PowerShell for Windows, chosen by detecting the developer's OS.

# Run Scripts (start / stop / restart)

## Overview

Every web app ends up needing the same three commands on a developer machine: start it in the background, stop it cleanly, restart it with the same flags. This recipe produces those scripts with one fixed contract, so they behave identically from project to project and from OS to OS:

- **`start`** — launches the app detached, records its PID, appends output to a log, waits until the app answers over HTTP, and reports the URL. `--prod` builds first and runs the production server.
- **`stop`** — stops the whole process tree (package manager + server + watchers), gracefully first, forced after a timeout.
- **`restart`** — `stop`, then `start` with every flag passed through.

The script **format follows the operating system**, detected when the recipe is loaded:

| Detected OS | Files generated |
|-------------|-----------------|
| Linux, macOS | `start.sh`, `stop.sh`, `restart.sh` (one portable set — bash 3.2 compatible) |
| Windows | `start.bat`, `stop.bat`, `restart.bat` (double-clickable wrappers) calling `scripts/start.ps1`, `scripts/stop.ps1` |
| Mixed team | both sets, sharing one run directory layout |

### Use this when

- The project is a web app (or API) started by one command (`pnpm dev`, `npm start`, `uvicorn …`, `dotnet run`, `go run .`, …) and reachable over HTTP on a local port.
- Developers start and stop it by hand several times a day and want it out of the foreground terminal.

### Do not use this for

- Production process supervision — use systemd, launchd, a Windows service, or `docker:build-push`. These scripts do not restart a crashed app.
- Multi-service local stacks (app + database + cache) — that is a compose concern (planned `dev:docker-compose`). This recipe starts the app only; external services are assumed to be running.
- Apps without an HTTP endpoint (desktop apps, CLIs, workers) — the readiness check needs one. See *Variations* for workers.

### Prerequisites

- A confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
- A known dev command and, for `--prod`, a build command and a production start command.
- Linux/macOS: `bash` and `curl` (both preinstalled on macOS and on mainstream Linux distributions).
- Windows: Windows PowerShell 5.1 (preinstalled on Windows 10/11) and `curl.exe` (bundled with Windows 10 since version 1803).

## OS Detection (do this first)

Before Tom's interview, detect the OS the developer is working on — do not ask what can be measured:

1. The assistant's own environment report (e.g. "Platform: linux / darwin / win32"), if available.
2. Otherwise run `uname -s`: `Linux` → Linux, `Darwin` → macOS, `MINGW*` / `MSYS*` / `CYGWIN*` → **Windows** (Git Bash or similar).
3. Otherwise, in PowerShell or cmd: `$env:OS` / `%OS%` equal to `Windows_NT` → Windows.

Then ask one question (structured choice per `_LOUIE_/guidelines/interaction-guidelines.md`):

> "Detected **<OS>**. Generate scripts for:"

- **<OS> only** *(default)* — `.sh` set for Linux/macOS, `.bat` + `.ps1` set for Windows.
- **All platforms** — both sets; pick this when teammates use other operating systems.

A Windows machine running Git Bash still gets the **Windows** set by default: Git Bash's process handling does not map POSIX process groups onto Windows process trees, so `kill -- -PID` does not reliably stop the server's child processes.

## Requirements Seed

### Functional

1. Three entry points in the project root: `start`, `stop`, `restart` (extension per OS). Each first changes to its own directory, so it works when called from anywhere.
2. Each script starts with a header comment: what it does and its usage line, including every supported flag.
3. Runtime state lives in **one gitignored run directory** (default `data/run/`): `app.pid` and `app.log`. The directory is created on demand and added to `.gitignore`.
4. **Port resolution:** environment variable `PORT` → `PORT=` line in the project's local env file (default `.env.local`; whatever the stack uses) → default (the framework's own default, e.g. 3000). The env file is **parsed, never sourced/executed**: last matching line wins, inline `#` comments, quotes, and spaces are stripped.
5. **Flags:** `--prod` (build, then run the production server). Projects may add their own flags (e.g. `--dev` to select a dev database). An unknown flag prints the usage line and exits 1.
6. **Idempotent start:** if the PID file points at a live process, print "`<App>` is already running (PID n) on http://localhost:PORT" and exit 0.
7. **Port collision:** if the port already answers HTTP before launch, refuse: "Port PORT is already in use by another process" and exit 1. Without this check the readiness poll would succeed against the foreign process.
8. **Optional target line:** if the app has a switchable backing resource (database, tenant, environment), print *which* one it will use — the name only. Credentials, hosts, and full URLs are never printed; anything that does not parse strictly prints `<unparseable>`.
9. **`--prod`:** run the build first with its output written to the log; on failure print "Build failed — see `<log>`" and exit 1. Then start the production server.
10. **Launch:** detached, in **its own process group** (Windows: its own process tree rooted at a recorded PID), stdin from the null device, stdout and stderr **appended** to the log. The PID is written to the PID file.
11. **Readiness:** poll `http://localhost:PORT<health-path>` once per second for up to 30 seconds. Any HTTP response counts as ready.
    - Ready → print "`<App>` (`<mode>`) running on http://localhost:PORT (PID n, log: `<log>`)" and exit 0.
    - Process died → print "`<App>` exited during startup — see `<log>`", remove the PID file, exit 1.
    - Timeout → print "`<App>` started (PID n) but did not answer within 30s — check `<log>`", exit 1 (the process is left running so the log can be inspected; `stop` cleans it up).
12. **Stop:** no PID file → "not running", exit 0. PID file but no live process → "not running (stale PID n) — cleaning up", remove the file, exit 0. Otherwise terminate the whole group/tree gracefully, wait up to 10 seconds, force-kill what remains (printing that it forced), remove the PID file, print "`<App>` stopped."
13. **Restart:** run `stop`, then `start` with all arguments passed through unchanged; stop on the first failure.
14. Non-obvious lines carry a `# WHY:` (PowerShell `# WHY:`, batch `rem WHY:`) comment.

### Non-Functional

- **Strict mode everywhere:** bash `set -euo pipefail`; PowerShell `$ErrorActionPreference = 'Stop'` plus explicit `$LASTEXITCODE` checks after native commands; batch scripts propagate `%ERRORLEVEL%`.
- **One portable `.sh` set for Linux and macOS.** macOS ships bash 3.2 as `/bin/bash` and has no `setsid` command, so the scripts avoid bash ≥4 features (`[[ -v ]]`, associative arrays, `mapfile`, `${var,,}`) and fall back to job control for the process group.
- **No elevated rights.** Nothing requires `sudo` or an administrator shell.
- **The app name, run directory, env file, default port, health path, and the dev / build / prod commands are defined once,** at the top of `start` (and the run directory in `stop`). They are the only lines a project changes.
- **No secrets in output or in the scripts.** The scripts read the port from the env file and nothing else unless requirement 8 applies.

### Out of Scope

- Supervision (auto-restart on crash, start on boot) — see *Variations*.
- Starting databases or other external services.
- Log rotation. The log grows until deleted; `--prod` builds overwrite it.
- Multiple instances of the same app from one checkout.

## Architecture Notes

### Where things are recorded

- **`_LOUIE-output/runbook.md` § Common Commands:** `./start.sh` / `./start.sh --prod` / `./stop.sh` / `./restart.sh` (or the `.bat` forms), plus `tail -f data/run/app.log` (Windows: `Get-Content data\run\app.log -Wait`).
- **`_LOUIE-output/runbook.md` § Ports & Endpoints:** the dev port and its precedence (env → env file → default).
- **`_LOUIE-output/runbook.md` § Debugging:** "start says the port is in use" → find the owner (`lsof -i :PORT` on macOS/Linux, `Get-NetTCPConnection -LocalPort PORT` on Windows); "app exited during startup" → read the log.
- **`.gitignore`:** the run directory.

No change to `architecture.md` — the scripts are tooling, not a system component.

### Things Sophie should validate

- **The dev and production commands.** Derive them from the project — `package.json` scripts plus the lockfile for the package manager (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm, `bun.lock` / `bun.lockb` → bun), `pyproject.toml` / `manage.py`, `*.csproj`, `go.mod`, `Cargo.toml`. Ask when there is no production start command; `--prod` is then dropped rather than invented.
- **How the app receives its port.** Some servers read the `PORT` environment variable; others need a CLI flag (e.g. Vite's `--port`) or a config entry. The scripts must pass the port the way *this* server reads it, or the readiness check polls the wrong port.
- **The health path.** Pick a route that answers without authentication and without side effects (`/`, `/health`, `/login`). A route behind a redirect is fine — any HTTP response counts.
- **The env file name** (`.env.local`, `.env`, `appsettings.Development.json` — the latter is JSON and needs a different parser; ask).
- **A switchable backing resource** for requirement 8, and how its name can be parsed safely.
- **Existing scripts.** If `start.sh` / `start.bat` already exist, decide with the user whether to replace or extend them before Nina writes anything.

## Implementation Guidance

The skeletons below are reference shapes. Nina substitutes the configuration block, adds project flags, and keeps every rule from the Requirements Seed. Placeholders are in `<angle brackets>`.

### `start.sh` (Linux and macOS)

```bash
#!/usr/bin/env bash
# Start <App> in the background. Usage: ./start.sh [--prod]
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="<App>"
RUN_DIR="data/run"
PID_FILE="$RUN_DIR/app.pid"
LOG_FILE="$RUN_DIR/app.log"
ENV_FILE=".env.local"
DEFAULT_PORT=3000
HEALTH_PATH="/"
DEV_CMD=(<pnpm dev>)
BUILD_CMD=(<pnpm build>)
PROD_CMD=(<pnpm start>)

# WHY: parse, never source — sourcing would execute arbitrary lines of the env file.
env_value() {
  grep -E "^$1=" "$ENV_FILE" 2>/dev/null | tail -n1 | cut -d= -f2- | sed 's/[[:space:]]*#.*//' | tr -d '" ' || true
}

PORT="${PORT:-$(env_value PORT)}"
PORT="${PORT:-$DEFAULT_PORT}"
MODE="dev"
for arg in "$@"; do
  case "$arg" in
    --prod) MODE="prod" ;;
    *) echo "Unknown option: $arg (usage: ./start.sh [--prod])"; exit 1 ;;
  esac
done

mkdir -p "$RUN_DIR"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "$APP_NAME is already running (PID $(cat "$PID_FILE")) on http://localhost:$PORT"
  exit 0
fi

# WHY: a foreign process on the port would satisfy the readiness poll below and fake a successful start.
if curl -s -o /dev/null "http://localhost:$PORT$HEALTH_PATH"; then
  echo "Port $PORT is already in use by another process — not starting $APP_NAME."
  exit 1
fi

if [[ "$MODE" == "prod" ]]; then
  echo "Building production bundle..."
  "${BUILD_CMD[@]}" >"$LOG_FILE" 2>&1 || { echo "Build failed — see $LOG_FILE"; exit 1; }
  RUN_CMD=("${PROD_CMD[@]}")
else
  RUN_CMD=("${DEV_CMD[@]}")
fi

# WHY: the app must lead its own process group so stop.sh can signal the package manager
# and every child together. setsid does that on Linux; macOS has no setsid command, and
# job control (set -m) gives a background job its own process group (PGID = $!).
if command -v setsid >/dev/null 2>&1; then
  PORT="$PORT" setsid nohup "${RUN_CMD[@]}" >>"$LOG_FILE" 2>&1 </dev/null &
else
  set -m
  PORT="$PORT" nohup "${RUN_CMD[@]}" >>"$LOG_FILE" 2>&1 </dev/null &
  set +m
fi
echo $! >"$PID_FILE"

for ((i = 0; i < 30; i++)); do
  if curl -s -o /dev/null "http://localhost:$PORT$HEALTH_PATH"; then
    echo "$APP_NAME ($MODE) running on http://localhost:$PORT (PID $(cat "$PID_FILE"), log: $LOG_FILE)"
    exit 0
  fi
  if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "$APP_NAME exited during startup — see $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
  fi
  sleep 1
done

echo "$APP_NAME started (PID $(cat "$PID_FILE")) but did not answer within 30s — check $LOG_FILE"
exit 1
```

Optional target line (requirement 8), placed before the build. The source pattern, generalized for bash 3.2:

```bash
# WHY: a defined (even empty) env var wins over the env file, like most frameworks; prints only the name.
print_target() {
  local variable="DATABASE_URL" url name="<unparseable>"
  if [ -n "${!variable+x}" ]; then url="${!variable}"; else url="$(env_value "$variable")"; fi
  # WHY: only a postgres URL with a /db path yields a name; anything else could echo host or credentials.
  if [[ "$url" =~ ^postgres(ql)?://[^/]+/([A-Za-z0-9_.-]+)(\?.*)?$ ]]; then name="${BASH_REMATCH[2]}"; fi
  echo "Database: $name"
}
```

`[ -n "${!variable+x}" ]` replaces `[[ -v $variable ]]`, which needs bash 4.2 and fails on macOS's bash 3.2.

### `stop.sh`

```bash
#!/usr/bin/env bash
# Stop the background <App> process started by start.sh.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="<App>"
PID_FILE="data/run/app.pid"

if [[ ! -f "$PID_FILE" ]]; then
  echo "$APP_NAME is not running (no PID file)."
  exit 0
fi

PID="$(cat "$PID_FILE")"
if ! kill -0 -- "-$PID" 2>/dev/null && ! kill -0 "$PID" 2>/dev/null; then
  echo "$APP_NAME is not running (stale PID $PID) — cleaning up."
  rm -f "$PID_FILE"
  exit 0
fi

is_group_alive() { kill -0 -- "-$PID" 2>/dev/null; }

# WHY: signal the negative PID (the whole process group) so watchers and child servers stop too.
kill -TERM -- "-$PID" 2>/dev/null || kill -TERM "$PID" 2>/dev/null || true
for ((i = 0; i < 10; i++)); do
  is_group_alive || break
  sleep 1
done
if is_group_alive; then
  echo "Processes did not stop after 10s — forcing."
  kill -KILL -- "-$PID" 2>/dev/null || true
fi

rm -f "$PID_FILE"
echo "$APP_NAME stopped."
```

### `restart.sh`

```bash
#!/usr/bin/env bash
# Restart <App>. Flags are passed to start.sh (e.g. --prod).
set -euo pipefail
cd "$(dirname "$0")"

./stop.sh
./start.sh "$@"
```

Mark all three executable (`chmod +x start.sh stop.sh restart.sh`) and commit the mode bit (`git update-index --chmod=+x` when committing from Windows).

### Windows — `.bat` wrappers

The `.bat` files exist so the scripts can be double-clicked and run from `cmd`; all logic lives in PowerShell, because batch alone cannot reliably capture the PID of a detached process.

`start.bat`:

```bat
@echo off
rem Start <App> in the background. Usage: start.bat [--prod]
rem WHY: -ExecutionPolicy Bypass applies to this one PowerShell process only; it changes no machine setting.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start.ps1" %*
exit /b %ERRORLEVEL%
```

`stop.bat` is identical with `stop.ps1` and its own header. `restart.bat`:

```bat
@echo off
rem Restart <App>. Flags are passed to start.bat (e.g. --prod).
call "%~dp0stop.bat" || exit /b 1
call "%~dp0start.bat" %*
exit /b %ERRORLEVEL%
```

The `.ps1` files live in `scripts/` so the project root shows only the three entry points. Use `powershell.exe` (Windows PowerShell 5.1, always present), not `pwsh` (PowerShell 7, optional install).

### `scripts/start.ps1`

```powershell
# Start <App> in the background. Called by start.bat. Usage: start.bat [--prod]
# WHY: no param() block — an advanced-function parameter binder would reject '--prod' as an unknown
# parameter; a plain script receives every argument verbatim in $args.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

$AppName     = '<App>'
$RunDir      = 'data\run'
$PidFile     = "$RunDir\app.pid"
$LogFile     = "$RunDir\app.log"
$EnvFile     = '.env.local'
$DefaultPort = '3000'
$HealthPath  = '/'
$DevCmd      = '<pnpm dev>'
$BuildCmd    = '<pnpm build>'
$ProdCmd     = '<pnpm start>'

# WHY: parse, never dot-source — the env file is data, not code.
function Get-EnvValue([string]$Key) {
  if (-not (Test-Path -LiteralPath $EnvFile)) { return '' }
  $hit = Select-String -LiteralPath $EnvFile -Pattern "^$Key=" | Select-Object -Last 1
  if (-not $hit) { return '' }
  return (($hit.Line.Substring($Key.Length + 1)) -replace '\s*#.*$', '') -replace '["\s]', ''
}

function Test-Alive([string]$Id) {
  return [bool]($Id -and (Get-Process -Id $Id -ErrorAction SilentlyContinue))
}

function Test-Answers([string]$Port) {
  # WHY: curl.exe, not the PowerShell 'curl' alias (Invoke-WebRequest); exit code 0 = any HTTP response.
  & curl.exe -s -o NUL "http://localhost:$Port$HealthPath"
  return ($LASTEXITCODE -eq 0)
}

$Port = $env:PORT
if (-not $Port) { $Port = Get-EnvValue 'PORT' }
if (-not $Port) { $Port = $DefaultPort }
$Mode = 'dev'
foreach ($arg in $args) {
  switch ($arg) {
    '--prod' { $Mode = 'prod' }
    default  { Write-Host "Unknown option: $arg (usage: start.bat [--prod])"; exit 1 }
  }
}

New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

if ((Test-Path -LiteralPath $PidFile) -and (Test-Alive (Get-Content -LiteralPath $PidFile))) {
  Write-Host "$AppName is already running (PID $(Get-Content -LiteralPath $PidFile)) on http://localhost:$Port"
  exit 0
}

if (Test-Answers $Port) {
  Write-Host "Port $Port is already in use by another process - not starting $AppName."
  exit 1
}

if ($Mode -eq 'prod') {
  Write-Host 'Building production bundle...'
  & cmd.exe /c "$BuildCmd > `"$LogFile`" 2>&1"
  if ($LASTEXITCODE -ne 0) { Write-Host "Build failed - see $LogFile"; exit 1 }
  $RunCmd = $ProdCmd
} else {
  $RunCmd = $DevCmd
}

$env:PORT = $Port
# WHY: cmd.exe does the redirection so stdout and stderr append to ONE log; Start-Process's own
# -RedirectStandardOutput/-RedirectStandardError take two separate files and overwrite them.
# The recorded PID is the cmd.exe root of the tree; stop.ps1 kills that tree.
$proc = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "$RunCmd >> `"$LogFile`" 2>&1" `
  -WindowStyle Hidden -PassThru
Set-Content -LiteralPath $PidFile -Value $proc.Id

for ($i = 0; $i -lt 30; $i++) {
  if (Test-Answers $Port) {
    Write-Host "$AppName ($Mode) running on http://localhost:$Port (PID $($proc.Id), log: $LogFile)"
    exit 0
  }
  if (-not (Test-Alive $proc.Id)) {
    Write-Host "$AppName exited during startup - see $LogFile"
    Remove-Item -LiteralPath $PidFile -Force
    exit 1
  }
  Start-Sleep -Seconds 1
}

Write-Host "$AppName started (PID $($proc.Id)) but did not answer within 30s - check $LogFile"
exit 1
```

Messages use a plain hyphen instead of an em dash: Windows PowerShell 5.1 reads a BOM-less `.ps1` in the system's ANSI code page, so non-ASCII characters can garble. Keep the `.ps1` files ASCII-only.

### `scripts/stop.ps1`

```powershell
# Stop the background <App> process started by start.ps1. Called by stop.bat.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

$AppName = '<App>'
$PidFile = 'data\run\app.pid'

function Test-Alive([string]$Id) {
  return [bool]($Id -and (Get-Process -Id $Id -ErrorAction SilentlyContinue))
}

if (-not (Test-Path -LiteralPath $PidFile)) {
  Write-Host "$AppName is not running (no PID file)."
  exit 0
}

$ProcId = (Get-Content -LiteralPath $PidFile).Trim()
if (-not (Test-Alive $ProcId)) {
  Write-Host "$AppName is not running (stale PID $ProcId) - cleaning up."
  Remove-Item -LiteralPath $PidFile -Force
  exit 0
}

# WHY: /T includes every child (package manager, server, watchers). Without /F, taskkill asks
# politely; console processes without a window usually refuse, so the forced pass is expected.
# Output is redirected inside cmd.exe: in Windows PowerShell 5.1 a native command's stderr
# redirected with 2> becomes error records, which $ErrorActionPreference = 'Stop' turns fatal.
& cmd.exe /c "taskkill /PID $ProcId /T >NUL 2>&1"
for ($i = 0; $i -lt 10 -and (Test-Alive $ProcId); $i++) { Start-Sleep -Seconds 1 }
if (Test-Alive $ProcId) {
  Write-Host 'Processes did not stop after 10s - forcing.'
  & cmd.exe /c "taskkill /PID $ProcId /T /F >NUL 2>&1"
}

Remove-Item -LiteralPath $PidFile -Force
Write-Host "$AppName stopped."
```

`$ProcId` instead of `$Pid`: `$PID` is a read-only automatic variable in PowerShell (the current process ID), and variable names are case-insensitive.

### Pitfalls

- **Don't `source` / dot-source the env file.** It executes every line; parse the one key needed.
- **Don't signal only the PID.** The recorded PID is the package manager (or `cmd.exe`); the server is a child. Signal the process group (`kill -- -PID`) or the tree (`taskkill /T`), or the server keeps the port and the next start reports "port in use".
- **Don't rely on `setsid` on macOS** — it is not installed. Keep the `set -m` fallback.
- **Don't use bash ≥4 features** in the `.sh` set; macOS `/bin/bash` is 3.2.
- **Don't call `curl` inside PowerShell** — it is an alias for `Invoke-WebRequest` in Windows PowerShell 5.1. Call `curl.exe`. Likewise call `taskkill`, not `kill` (an alias for `Stop-Process`).
- **Don't skip the port-collision check.** The readiness poll cannot tell your app from another one on the same port.
- **Don't print connection strings** in the target line — name only, strict parse, `<unparseable>` otherwise.
- **Don't treat a readiness timeout as "stopped".** Leave the process and PID file in place so the log can be read; `stop` handles it.
- **PID reuse.** A stale PID file can point at an unrelated process that later received the same PID (more likely on Windows, which reuses PIDs quickly). The scripts accept this small risk, as the source did; see *Variations* for a stricter check.

## Test Guidance

These are operational scripts — the checks are a **verification checklist** Ava runs with Nina on each generated platform, not a unit-test suite.

### Start

- `start` on a stopped app prints the running line with URL, PID, and log path, and the app answers in a browser.
- `start` a second time prints "already running" and exits 0 without launching a second instance.
- `start --prod` runs the build, then the production server; a deliberately broken build prints "Build failed — see …" and exits 1.
- `start --bogus` prints the usage line and exits 1.
- With another server already listening on the port, `start` refuses with "port in use" and exits 1.
- An app that crashes on boot (e.g. a syntax error) yields "exited during startup", exit 1, and no PID file.
- `PORT=4123 ./start.sh` (Windows: `set PORT=4123` then `start.bat`) overrides the env file; with neither set, the default port is used.
- The target line (if present) shows only a name; a malformed URL prints `<unparseable>`.

### Stop and restart

- `stop` on a running app ends **every** process of the tree — verify with `pgrep -g <PGID>` on Linux/macOS, `tasklist` on Windows — and frees the port.
- `stop` with no PID file and with a stale PID file both exit 0 with the matching message.
- An app that ignores SIGTERM is force-killed after 10 seconds with the "forcing" message.
- `restart --prod` ends in prod mode (flag pass-through).
- `start`, `stop`, and `restart` work when invoked from another directory (`../project/start.sh`, double-click for `.bat`).

### Platform

- **macOS:** run the `.sh` set under `/bin/bash` (3.2) on a machine without `setsid` and confirm `stop` still ends the whole group (the `set -m` branch).
- **Windows:** run from `cmd`, from PowerShell, and by double-click; confirm no console window stays open for the background app and that the app survives closing the window that started it.
- The run directory is ignored by git after the first start (`git status` stays clean).

## Variations

### Status and logs helpers

Add `status` (reads the PID file, prints running/stopped + URL) and `logs` (`tail -f` / `Get-Content -Wait` on the log). Same configuration block, same run directory.

### Multiple processes (web + worker)

One PID file and one log per process (`web.pid`, `worker.pid`, …), started and stopped in a fixed order. Readiness applies only to processes with an HTTP endpoint; for a worker, "still alive after N seconds" is the readiness signal.

### Supervision and start on boot

Hand the same commands to a supervisor instead: a systemd user unit (Linux), a launchd agent (macOS), or a scheduled task / service wrapper (Windows). The supervisor then owns PID tracking and the scripts become thin `systemctl --user start …` wrappers.

### Stricter PID check

Store the process start time next to the PID (`ps -o lstart= -p PID`, `(Get-Process -Id PID).StartTime`) and treat a mismatch as stale. Removes the PID-reuse edge case at the cost of a second state value.

### Custom env file or port flag

If the stack reads its port from a JSON settings file or only from a CLI flag, swap `env_value` / `Get-EnvValue` for a matching reader, or append the port flag to the run command (`--port "$PORT"`). The precedence rule (environment → file → default) stays.
