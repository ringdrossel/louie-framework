# Framework Backlog

Open ideas, gaps, and feature suggestions for the LOUIE framework itself. This is **not** a per-project todo list — it lives in `_LOUIE-internals/` and is not distributed.

Items move from here into `CHANGELOG.md` (Unreleased section) once implemented.

Format: short title + the gap + why it matters + tradeoff or open design questions. Leave entries terse; the goal is to capture, not to design.

## Open

### Recipe library expansion

The `louie-recipe` dispatcher is in place but only `admin:settings` ships. The system's value scales with catalogue size. Candidate next recipes (rough priority order):

- `auth:email-password` — registration, login, password reset, session management
- `auth:oauth` — OAuth 2 / OIDC with provider templates (Google, GitHub)
- `logging:structured` — JSON logging with levels, request correlation IDs
- `config:env-validation` — typed env var loading with startup validation
- `errors:middleware` — central error handler with safe/unsafe error mapping
- `ci:github-actions` — lint + test + build pipeline
- `dev:docker-compose` — local dev stack (app + db + cache)
- `uploads:files` — file upload with size/type validation, optional S3 backend
- `data:pagination` — cursor + offset pagination patterns
- `audit:event-log` — append-only audit trail
- `email:transactional` — provider-agnostic transactional email

Each recipe needs to stay stack-agnostic (per the recipe authoring guide). Open question: whether to ship "starter packs" (e.g., `auth-pack` that pulls auth + OAuth + email) or keep recipes atomic and let users compose them.

### Release / deployment workflow

Runbook covers *how to run* the system; nothing covers *how to ship* it. Users will hit this as soon as they go to production.

Proposed: a `louie-release` command that:

- Bumps version across manifest files (per tech-stack)
- Generates a user-facing changelog from feature docs landed since last release (using their `## Status` and `## Change History` sections)
- Drafts release notes
- Optionally drafts a PR description from the feature docs in flight

Open questions: which agent owns this (Sophie? new persona? command-only with no agent)? Does it interact with the merge-to-main gate or sit downstream of it? How does it handle multiple in-flight features being released together?

### "Where am I?" status command

Long-running projects accumulate in-flight features, open questions across docs, and stale feature docs. There's no quick way to ask "what's the state?" without grepping.

Proposed: a `louie-status` (or `louie-overview`) command that summarizes:

- Features by status (Planned / In Development / Implemented / Tested) from `implementations/overview.md` and per-feature docs
- All `## Open Questions` sections aggregated across requirements and feature docs
- Stale feature docs (e.g., In Development with no Change History entry in N days)
- Recent runbook gotchas
- Any architecture/tech-stack items added since last status check

Read-only command. No agent. Pure aggregation.

### Scaling the artifact layout for large projects

**Status: designed, awaiting implementation approval.** See `_LOUIE-internals/scaling.md` for the full design.

Direction locked in: **universal per-feature folders** (`implementations/<feature>/feature.md` + `requirements.md` + `decisions.md` + `bugfixes/<date>-<slug>.md`), top-level `_LOUIE-output/bugfixes/overview.md` for cross-cutting search, and a one-way migration path triggered from `louie-update-framework` (or a new `louie-migrate` command).

Largest structural change since the framework was built. Touches templates, every command that writes to `_LOUIE-output/`, all agents, the overview format, `louie-update-framework`, and adds `louie-migrate`. Best done on its own feature branch.

## Smaller / nice-to-have

- **No deprecation path for retired features.** Their docs just sit in `implementations/`. Could be a `louie-retire` command or a status flag.
- **No domain glossary artifact.** Tom captures personas but not vocabulary. For projects with heavy jargon, terms should have a single home (e.g., `_LOUIE-output/glossary.md`).
- **Multi-repo / monorepo story.** Current model assumes one project per LOUIE install. Big projects with backend/frontend/mobile splits have no story.
- **Test coverage thresholds.** Ava's coverage is descriptive, never measured against a minimum. Could be a tech-stack-level setting.
- **Tom standalone.** Tom can't be invoked just to "capture this idea" without committing to setup/feature. A `louie-capture` or `--requirements-only` flag would help when the user is still uncertain.
- **ADR growth.** Architecture template mentions ADRs but nothing adds new ones over time. Either a `louie-adr` command or a slot in `louie-extend`/`louie-feature` to capture decisions made during the chain.
- **Template versioning.** When `feature-template.md` evolves, existing feature docs don't carry a version. `louie-update-framework` could detect outdated docs and offer migration. Related to the framework-update artifact-migration pattern called out in `_LOUIE-internals/import.md`.
- **Security review mode.** Max runs a generic review; security has its own rhythm. A `louie-security-review` (Max with a security-focused prompt + checklist) is high-leverage for regulated teams. Lower priority because Max already covers the baseline.
