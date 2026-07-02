# Framework Backlog

Open ideas, gaps, and feature suggestions for the LOUIE framework itself. This is **not** a per-project todo list — it lives in `_LOUIE-internals/` and is not distributed.

Items move from here into `CHANGELOG.md` (Unreleased section) once implemented.

Format: short title + the gap + why it matters + tradeoff or open design questions. Leave entries terse; the goal is to capture, not to design.

## Open

### Init-script generator (E-02 level 2)

The E-02 consistency lint (`_LOUIE-internals/tools/check-consistency.sh`) catches command-table drift across the ~16 registration surfaces, but adding a command still means hand-editing all of them. The full fix sketched in `framework-evaluation/efficiency.md` § E-02 is a generator that renders the 12 init scripts from per-tool templates plus one manifest (or parses `_LOUIE_/commands/*.md` headers directly), making the scripts build artifacts. Deferred because the scripts carry real per-tool differences (codex skill frontmatter, opencode command dir, adapter reporting) — the templates would inherit that complexity, and a generator bug corrupts 12 files at once. Revisit if the per-command editing tax keeps hurting despite the lint.

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

### "Where am I?" status command — DONE (S-07)

Implemented as `louie-status` (2026-07-02). Read-only, no agent, pure aggregation: features by status, aggregated Open Questions, stale `In Development` docs, recent bugfix rows, roadmap deltas — grouped by domain, index-first per Context Discipline. See `_LOUIE_/commands/louie-status.md` and CHANGELOG.

### Scaling the artifact layout for large projects

**Status: designed, awaiting implementation approval.** See `_LOUIE-internals/scaling.md` for the full design.

Direction locked in: **universal per-feature folders** (`implementations/<feature>/feature.md` + `requirements.md` + `decisions.md` + `bugfixes/<date>-<slug>.md`), top-level `_LOUIE-output/bugfixes/overview.md` for cross-cutting search, and a one-way migration path triggered from `louie-update-framework` (or a new `louie-migrate` command).

Largest structural change since the framework was built. Touches templates, every command that writes to `_LOUIE-output/`, all agents, the overview format, `louie-update-framework`, and adds `louie-migrate`. Best done on its own feature branch.

### Smart merge for `louie-evaluate` rescan — DONE (S-04)

Implemented 2026-07-02 alongside chunked scanning. Rescan now matches new→old findings by `file` + normalized signature anchored to the nearest enclosing function/class; matched carry status forward, unmatched-old → `resolved`, new → `pending`. `archive` remains the clean-slate option. See `_LOUIE-internals/evaluate.md` § Scanning at Scale and CHANGELOG.

## Smaller / nice-to-have

- ~~**No deprecation path for retired features.**~~ DONE (S-03, 2026-07-02): terminal `Retired` status; `louie-doc` moves the row to a collapsed `### Retired` section, folder stays on disk, agents skip it when scanning.
- **No domain glossary artifact.** Tom captures personas but not vocabulary. For projects with heavy jargon, terms should have a single home (e.g., `_LOUIE-output/glossary.md`).
- **Multi-repo / monorepo story.** Current model assumes one project per LOUIE install. Big projects with backend/frontend/mobile splits have no story.
- **Test coverage thresholds.** Ava's coverage is descriptive, never measured against a minimum. Could be a tech-stack-level setting.
- **Tom standalone.** Tom can't be invoked just to "capture this idea" without committing to setup/feature. A `louie-capture` or `--requirements-only` flag would help when the user is still uncertain. *Partially absorbed by `louie-roadmap` (capture without commitment); the remaining gap is "I want Tom-level requirements but no architecture/chain" which is a distinct use case.*
- **ADR growth.** Architecture template mentions ADRs but nothing adds new ones over time. Either a `louie-adr` command or a slot in `louie-extend`/`louie-feature` to capture decisions made during the chain.
- **Template versioning.** When `feature-template.md` evolves, existing feature docs don't carry a version. `louie-update-framework` could detect outdated docs and offer migration. Related to the framework-update artifact-migration pattern called out in `_LOUIE-internals/import.md`.
- **Security review mode.** Max runs a generic review; security has its own rhythm. A `louie-security-review` (Max with a security-focused prompt + checklist) is high-leverage for regulated teams. Lower priority because Max already covers the baseline.
