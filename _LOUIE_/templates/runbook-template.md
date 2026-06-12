# Runbook

Last Updated: YYYY-MM-DD

> **What this is:** the operational reference for running, debugging, and maintaining this project. Read this when you need to *run* the system or figure out why it's broken — not when you're designing it. For design-time concerns, see `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.

> **Editing policy — READ BEFORE EDITING.** This file is operational reference only: ports, env vars, external services, common commands, first-check debugging. **Implementation learnings** (framework quirks, cache rules, "this API silently defaults", "I discovered X during Phase 4") belong in code-local `// WHY` comments + the per-feature `_LOUIE-output/implementations/<feature>/bugfixes/<slug>.md` § Detect / Avoid — **not here**. There is no `## Common Gotchas` section; do not create one. Operational caveats go **inline** as parentheticals in the Notes column / bullet next to the entry they affect. This rule applies to every agent and every edit path, including ad-hoc "update the specs" requests that don't route through a `louie-*` command.

## Deployment Model

[How the system actually runs in this environment. Examples: "App on host via systemd, PostgreSQL in Docker", "Containerized — docker-compose with 3 services", "Serverless — AWS Lambda + API Gateway", "Bare process via npm start during development".]

[Include the host(s), the orchestrator (systemd / docker / k8s / pm2 / none), and how restarts happen.]

## Ports & Endpoints

| Service | Host port | Internal | Notes |
|---------|-----------|----------|-------|
| [App] | [3000] | [3000] | [Web UI / API] |
| [DB] | [5433] | [5432] | [Container internal differs from host] |
| [...] | | | |

[List every port the system or its dependencies bind. Note any port collisions handled (e.g. host 5433 → container 5432). Include external endpoints the system *calls* — LLM APIs, third-party services — with their URLs.]

[**Operational caveats live inline as a parenthetical in the Notes column** — e.g. "host 5433 → container 5432; binding to host 5432 collides with Postgres.app", or "Ollama endpoint must be `http://` only, TLS unsupported". Don't accumulate a separate gotchas section.]

## Common Commands

[The commands a developer or operator actually types. Group by purpose. Use real, working commands — not placeholders.]

### Run / Restart

```bash
# Start the app
[command]

# Restart after code change
[command]

# Stop
[command]
```

### Status & Health

```bash
# Is it up?
[command]

# Health endpoint
curl http://localhost:[port]/[health-path]
```

### Logs

```bash
# Tail logs
[command]

# Last N minutes
[command]
```

### Database / Storage

```bash
# Connect
[command]

# Migrations
[command]
```

## Environment & Dependencies

[Runtime environment variables and external services this project depends on at run time — distinct from the build-time stack in `tech-stack.md`.]

### Required Env Vars

| Name | Purpose | Example |
|------|---------|---------|
| [DATABASE_URL] | [Postgres connection] | [postgres://...] |
| [...] | | |

### External Services

- **[Name]** — [endpoint], [purpose], [auth method]
- [...]

[**Operational caveats go inline in the bullet** — e.g. "expects HTTP, not HTTPS", "rate-limited to 1k req/day on anonymous tier". Implementation learnings (cache invalidation rules, framework quirks) belong in a code-local `// WHY` comment + the relevant `bugfixes/<slug>.md`, **not here**.]

## Review Mode

Controls how `louie-review` behaves. See `_LOUIE_/commands/louie-review-mode.md` for full details.

**Mode:** [unset — defaults to `manual` until configured via `louie-setup` or `louie-review-mode`]
**Loop cap:** 3
**Set:** YYYY-MM-DD

Valid values: `manual` (default, asks before fixing), `auto-fix-critical` (auto-applies Critical + Should Fix in a loop), `auto-fix-all` (also auto-applies Suggestions). Per-call overrides: `louie-review manual` / `louie-review auto` / `louie-review auto-fix-all`.

## Branch Mode

Controls whether `louie-feature` creates a branch per feature. See `_LOUIE_/commands/louie-branch-mode.md` for full details.

**Mode:** [unset — defaults to `current`]
**Set:** YYYY-MM-DD

Valid values: `current` (default — work on the current branch, including `main`; never auto-branch, never prompt), `ask` (ask before each new feature whether to create a `feature/<name>` branch). A branch is never created automatically; in either mode you can ask for one on demand. Affects `louie-feature` only.

## Auto-Pilot

Controls how far each command runs unattended after the plan is approved. See `_LOUIE_/commands/louie-autopilot-mode.md` for full details.

**feature:** off
**extend:** off
**update:** off
**bugfix:** off
**Set:** YYYY-MM-DD

Valid values per command: `on` / `off` (default `off`). When `on`, the command runs the chain unattended after the plan-agreement gate (for `feature`/`extend`, that's Tom's playback confirmation, before `feature.md` is written) through to a final pre-merge summary. Auto-pilot stops before merge, never auto-creates a branch, runs Max at an `auto-fix-critical` floor, and pauses anyway if the written plan materially diverges from what was agreed. Per-call override: `louie-<command> --auto` / `--manual` (does not change this setting). `update`/`bugfix` have thin leverage (no pre-code gates).

## Debugging

[Where to look first when specific symptoms appear. One row per common symptom.]

| Symptom | First thing to check |
|---------|---------------------|
| [App won't start] | [DB up? Run `[command]`. Check logs: `[command]`.] |
| [Auth fails] | [JWT secret env var set? Token expired?] |
| [Slow response] | [Connection pool exhausted? Check `[command]`.] |
| [...] | |

## Notes for Maintainers

- **Keep this file operational and short.** It exists to answer "how do I run, deploy, or first-pass-debug this system?" — nothing else. Implementation learnings (framework quirks, cache invalidation rules, "I learned X during Phase 4") belong in three places that already exist and serve the LLM better:
  - a one-line `// WHY` comment next to the code that bites,
  - the relevant `_LOUIE-output/implementations/<feature>/bugfixes/<slug>.md`,
  - and/or an ADR in the feature's `decisions.md`.
- Operational caveats (a port collision, an env var that silently defaults, a service that only accepts HTTP) go **inline** as a parenthetical Note column entry or bullet sub-note next to the port / env var / command they affect — not in a flat list.
- The Debugging table is for symptoms an operator hits at runtime, not for accumulated dev-time learnings. Cap at ~10 rows; prune older rows whose symptoms are now caught by tests, monitoring, or a code-comment WHY.
- Cross-reference: detailed architecture is in `_LOUIE-output/architecture.md`. Tech stack is in `_LOUIE-output/tech-stack.md`. Per-feature details are in `_LOUIE-output/implementations/[feature]/feature.md`. Bug-fix history is in each feature's `bugfixes/` folder and the cross-project index at `_LOUIE-output/bugfixes/overview.md`.
- Sophie creates this file at project setup. Nina updates it only when a change genuinely altered operational surface (new port, new env var, new command, new external service). Max verifies during review.
