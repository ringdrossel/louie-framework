# Import System Design

How LOUIE retrofits onto a project that already has source code (and possibly v1-style docs). Read this when changing `louie-import`, the init-script detection, or anything that decides how existing artifacts are mapped into the LOUIE schema.

## Why It Exists

`louie-setup` assumes a green-field project — Tom interviews, Sophie architects, code follows. That assumption breaks for two common cases:

1. **Cold import** — a real project with code but no LOUIE-shaped docs. Most adopters land here. They don't want to retrofit requirements by hand.
2. **v1-docs import** — a project set up with the LOUIE precursor (the flat "feature-based development" workflow). They have `docs/implementations/overview.md` plus per-feature docs, but no architecture/tech-stack/runbook/requirements.

Before this command, `_LOUIE_/setup/project-setup.md` punted on both cases ("just run Sophie manually, don't retroactively create docs"). That's slow and inconsistent. `louie-import` automates it.

## Scope

`louie-import` produces the same artifacts as a successful `louie-setup`:

- `_LOUIE-output/architecture.md`
- `_LOUIE-output/tech-stack.md`
- `_LOUIE-output/runbook.md`
- `_LOUIE-output/requirements/<feature>-requirements.md` (one per discovered feature)
- `_LOUIE-output/implementations/<feature>.md` (one per discovered feature, status: Implemented)
- `_LOUIE-output/implementations/overview.md`

After `louie-import` exits successfully, the project is indistinguishable from one that went through `louie-setup` + N rounds of `louie-feature`. The two architecture confirmation gates apply identically.

## Two Modes

### Cold Import (Type 1)

No prior LOUIE-shaped docs. Sophie scans the codebase to infer:

- Tech stack (manifest files: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `composer.json`, `Gemfile`, `mix.exs`, etc.)
- Architecture (entry points, top-level modules, framework signatures, folder shape)
- Runbook (start/build/test commands from manifests, ports from config files, env vars from `.env.example`/`README.md`)
- Features (routes, top-level modules, CLI commands, observable surface area)

Tom interviews **only on the gaps** Sophie can't resolve from code:

- Project goal (the "why")
- Target users
- Hard constraints not visible in code (compliance, deadlines, performance targets)
- Acceptance criteria for the discovered features

Cold import never invents requirements wholesale — code is treated as ground truth. Tom asks; he doesn't speculate.

### v1-Docs Import (Type 2)

A v1 project's docs live at:

```
docs/
├── ai-workflow.md                    ← discard (replaced by LOUIE workflow)
├── implementations/
│   ├── overview.md                   ← maps to _LOUIE-output/implementations/overview.md
│   └── <feature>.md                  ← maps to _LOUIE-output/implementations/<feature>.md
└── templates/
    └── feature-template.md           ← discard (LOUIE has its own)
```

The unambiguous v1 signature is `docs/implementations/overview.md` plus sibling per-feature `.md` files. v1 had no requirements/architecture/tech-stack/runbook concepts — those still need reverse engineering from code, the same way Cold Import does it. v1 docs only short-circuit the **feature discovery** step.

v1 feature docs translate directly to LOUIE's feature template (the v2 template is a strict superset). New sections (Type, Affected Entities, Testing Strategy, Handoff) get filled from architecture context.

### Mode Detection

`louie-import` detects the mode automatically:

- Presence of `docs/implementations/overview.md` AND at least one sibling `<feature>.md` → **v1-docs**
- Otherwise → **cold**

The user can always override the detection. The command shows what was detected and asks for confirmation before proceeding.

## Trust-As-Truth Policy

Discovered features are written with status `Implemented`, not `Implemented (unverified)` or similar. Rationale:

- The code is running. Whatever shape it has is reality.
- A "verified" middle state would force a per-feature audit before users could `louie-feature` again — that's friction without payoff.
- Max and Ava can flag drift on the next change touching that feature. They don't need a new pre-existing-code state to do their jobs.

Caveat: if Sophie or Tom find code they genuinely can't make sense of, they record it under Open Questions on the feature doc rather than guessing. Open Questions are the supported way to flag "we don't fully understand this part."

## Agent Reuse vs. New Agent

`louie-import` reuses **Tom (Analyst)** and **Sophie (Architect)**. No new persona. Reasons:

- Their existing competencies (requirements interviews; architectural inference) are exactly what import needs.
- Adding an "Importer" agent bloats the chain and forces every downstream surface (`agent-handoffs.md`, init-script command tables, README) to grow another row.
- The import-specific behavior is a *prompt variant* triggered by the command, not a *role*. Commands customize agent behavior all the time (Sophie's "first run" vs "subsequent run" branches in `architect.md` are precedent).

The command is responsible for telling Tom and Sophie they're in import mode and pointing them at the codebase / v1 docs.

## Init Script Integration

The init scripts (`_LOUIE_/setup/<tool>-init.{sh,bat}`) detect existing projects and **recommend** running `louie-import`. They never invoke it directly — the import has to happen inside the AI tool, where Tom and Sophie can do their work.

### Detection Signal

A project is considered "existing" if any of these are present at the root:

- v1 docs: `docs/implementations/overview.md`
- Source directory: `src/`, `app/`, `lib/`
- Manifest file: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `composer.json`, `Gemfile`, `mix.exs`, `setup.py`, `requirements.txt`

The detection is intentionally conservative — false negatives (skipping the recommendation) are fine; false positives would annoy fresh-project users. The framework's own repo has none of these signals at root, so framework dev sessions don't trigger the recommendation.

### Behavior

After the install steps complete, if the existing-project signal is true:

- v1-docs detected → "Detected v1 LOUIE docs. Run `/louie-import` (or `louie-import`) next to translate them into LOUIE format."
- Cold project → "Detected existing project source. Run `/louie-import` (or `louie-import`) next to have LOUIE generate architecture, tech-stack, runbook, and feature docs from the existing code."

The recommendation is non-blocking. Users can ignore it and run `louie-setup` if they truly want to start fresh.

## Confirmation Gates

`louie-import` respects the standard architecture gate. After Sophie produces architecture/tech-stack/runbook from inferred or v1-derived sources, the user confirms before any feature docs are finalized or any future `louie-feature` is allowed.

There is no separate "import gate." The architecture gate is sufficient because everything Sophie produced flows into it.

The feature-doc gate from `louie-feature` does not apply during import — discovered features are documenting existing code, not authorizing new code, so there's nothing for the user to approve before implementation. The implementations are already there.

## What Import Does NOT Do

- Does not run Leo, Nina, Max, or Ava. Import is a documentation pass, not a build pass.
- Does not modify source code under any circumstance.
- Does not overwrite existing `_LOUIE-output/` artifacts without explicit user confirmation. If the project already has a partial LOUIE setup, the user is asked per file.
- Does not delete v1 docs after import. Users can clean up `docs/` themselves once they're satisfied.

## Future Considerations

- A `--dry-run` mode that lists what would be discovered without writing files. Defer until users ask.
- Support for other documentation precursors (Spec Kit, BMAD) by adding more detectors. Each would map to its own translator in this design doc.
- Per-feature confidence scoring on inferred architecture decisions — would require a new "confidence" field in templates. Not justified yet.
