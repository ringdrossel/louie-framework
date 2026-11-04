Source material for the `dev:run-scripts` recipe — captured from a real project (GameLog: Next.js app run with pnpm, Postgres, `.env.local`).

## Purpose

These three files are the hand-written scripts the maintainer had been copying into every new web app. The recipe `_LOUIE_/recipes/dev/run-scripts.md` turns their rules into a stack-agnostic, cross-platform contract. They are **reference only** — not distributed, not referenced from the recipe, not to be edited during normal framework work.

## Files

| File | Purpose |
|------|---------|
| `start.sh` | Start the app in the background: `--prod` builds first, `--dev` selects a dev database. PID + log in `data/run/`; port from env → `.env.local` → 3000; "already running" short-circuit; prints the target DB name only (never the URL); waits up to 30s for HTTP; detects early exit. |
| `stop.sh` | Stop the process group: SIGTERM, wait up to 10s, SIGKILL fallback; stale-PID cleanup. |
| `restart.sh` | `stop.sh` then `start.sh "$@"` — flags pass through. |

## Rules the recipe extracted

Each became a numbered requirement in the recipe's Requirements Seed: script-dir `cd`, strict mode, one gitignored run dir, port precedence, never sourcing the env file, unknown-flag rejection, idempotent start, credential-safe target print, prod build into the log, own process group, readiness poll with early-exit detection, graceful-then-forced stop, flag pass-through on restart, `# WHY` comments.

## What the recipe changes relative to the source

1. **macOS portability.** `setsid` is not shipped on macOS and `/bin/bash` there is 3.2, which lacks `[[ -v ]]` (bash 4.2+). The recipe uses `setsid` when present and falls back to `set -m` (job control puts the background job in its own process group), and replaces `[[ -v name ]]` with `[ -n "${!name+x}" ]`.
2. **Windows.** No source equivalent existed. The recipe adds `.bat` wrappers that call PowerShell scripts (`Start-Process -PassThru` for the PID, `taskkill /T` for the tree).
3. **Port-collision check.** The source's readiness poll would report success if *another* process already answered on the port. The recipe refuses to start when the port answers before launch.
4. **App-specific parts generalized.** `GAMELOG_DB`, the `/login` health path, and `pnpm` become project-detected values.
