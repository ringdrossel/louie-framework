# Runbook

Last Updated: YYYY-MM-DD

> **What this is:** the operational reference for running, debugging, and maintaining this project. Read this when you need to *run* the system or figure out why it's broken — not when you're designing it. For design-time concerns, see `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.

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

## Review Mode

Controls how `louie-review` behaves. See `_LOUIE_/commands/louie-review-mode.md` for full details.

**Mode:** [unset — defaults to `manual` until configured via `louie-setup` or `louie-review-mode`]
**Loop cap:** 3
**Set:** YYYY-MM-DD

Valid values: `manual` (default, asks before fixing), `auto-fix-critical` (auto-applies Critical + Should Fix in a loop), `auto-fix-all` (also auto-applies Suggestions). Per-call overrides: `louie-review manual` / `louie-review auto` / `louie-review auto-fix-all`.

## Common Gotchas

[Accumulated pitfalls discovered during development and operation. **Append, don't rewrite** — old gotchas stay (they may resurface). New entries go on top with a date.]

> Format: `**[YYYY-MM-DD] [Short title]** — [What goes wrong, how to detect, how to avoid/fix]`

- **[YYYY-MM-DD] [Example: Cache-bust ?v= after frontend changes]** — [Browser caches index.html aggressively; bump the `?v=` query param on script tags after every frontend change or the user sees stale UI.]

[Add new gotchas as Nina (Coder) discovers them during feature work or bugfixes.]

## Debugging

[Where to look first when specific symptoms appear. One row per common symptom.]

| Symptom | First thing to check |
|---------|---------------------|
| [App won't start] | [DB up? Run `[command]`. Check logs: `[command]`.] |
| [Auth fails] | [JWT secret env var set? Token expired?] |
| [Slow response] | [Connection pool exhausted? Check `[command]`.] |
| [...] | |

## Notes for Maintainers

- This file grows over time. **Don't delete old gotchas** — they may resurface. Move stale ones to a "Resolved" subsection at the bottom of *Common Gotchas* if they no longer apply, but keep them visible for context.
- Cross-reference: detailed architecture is in `_LOUIE-output/architecture.md`. Tech stack is in `_LOUIE-output/tech-stack.md`. Per-feature details are in `_LOUIE-output/implementations/[feature]/feature.md`. Bug-fix history is in each feature's `bugfixes/` folder and the cross-project index at `_LOUIE-output/bugfixes/overview.md`.
- Sophie creates this file at project setup. Nina appends after every implementation or bugfix. Max checks during review that new ports / commands / gotchas from the change made it in.
