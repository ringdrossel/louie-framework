#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOUIE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "LOUIE — Gemini CLI Setup"
echo "========================="
echo ""

GEMINI_MD="$LOUIE_DIR/GEMINI.md"
LOUIE_MARKER="<!-- LOUIE-FRAMEWORK -->"

if [ -f "$GEMINI_MD" ] && grep -q "$LOUIE_MARKER" "$GEMINI_MD"; then
  echo "  GEMINI.md already contains LOUIE section — skipped."
else
  cat >> "$GEMINI_MD" << 'CONTENT'

<!-- LOUIE-FRAMEWORK -->
## LOUIE Framework

This project uses **LOUIE** (Lean Orchestration for Unified Intelligent Engineering) for AI-assisted development.

### Command Routing

When the user types a `louie-*` command (e.g., `louie-setup`, `louie-feature`), read the matching file from `_LOUIE_/commands/` and follow the instructions in it.

Available commands:
- `louie-setup` → `_LOUIE_/commands/louie-setup.md`
- `louie-import` → `_LOUIE_/commands/louie-import.md`
- `louie-migrate` → `_LOUIE_/commands/louie-migrate.md`
- `louie-feature` → `_LOUIE_/commands/louie-feature.md`
- `louie-extend` → `_LOUIE_/commands/louie-extend.md`
- `louie-update` → `_LOUIE_/commands/louie-update.md`
- `louie-bugfix` → `_LOUIE_/commands/louie-bugfix.md`
- `louie-continue` → `_LOUIE_/commands/louie-continue.md`
- `louie-review` → `_LOUIE_/commands/louie-review.md`
- `louie-review-doc` → `_LOUIE_/commands/louie-review-doc.md`
- `louie-evaluate` → `_LOUIE_/commands/louie-evaluate.md`
- `louie-review-mode` → `_LOUIE_/commands/louie-review-mode.md`
- `louie-branch-mode` → `_LOUIE_/commands/louie-branch-mode.md`
- `louie-autopilot-mode` → `_LOUIE_/commands/louie-autopilot-mode.md`
- `louie-language` → `_LOUIE_/commands/louie-language.md`
- `louie-test` → `_LOUIE_/commands/louie-test.md`
- `louie-doc` → `_LOUIE_/commands/louie-doc.md`
- `louie-ideate` → `_LOUIE_/commands/louie-ideate.md`
- `louie-roadmap` → `_LOUIE_/commands/louie-roadmap.md`
- `louie-roadmap-change` → `_LOUIE_/commands/louie-roadmap-change.md`
- `louie-recipe` → `_LOUIE_/commands/louie-recipe.md`
- `louie-update-framework` → `_LOUIE_/commands/louie-update-framework.md`
- `louie-from-source` → `_LOUIE_/commands/louie-from-source.md`

### Critical Rules

1. **Never implement directly** — create a feature document and get user confirmation first.
2. **Never start feature work** without a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
3. **Never merge to `main`** without explicit user approval after Max's review and Ava's tests pass.
4. **Never write implementation learnings to `_LOUIE-output/runbook.md`.** The runbook is operational reference only (ports, env vars, external services, commands, first-check debugging). Framework quirks, cache rules, "I learned X" → code-local `// WHY` comments + per-feature `bugfixes/<slug>.md` § Detect / Avoid. There is no `## Common Gotchas` section; do not create one. Applies to every edit path, including ad-hoc "update the specs" requests that don't route through a `louie-*` command.

### Key Files

- `README.md` — framework overview (project root)
- `_LOUIE_/workflow/ai-workflow.md` — full workflow
- `_LOUIE_/guidelines/coding-guidelines.md` — coding rules
- `_LOUIE_/guidelines/interaction-guidelines.md` — how to ask the user to choose
- `_LOUIE_/guidelines/execution-guidelines.md` — how work runs (sequential baseline, work packages, subagent dispatch)
- `_LOUIE_/agents/` — agent definitions
- `_LOUIE-output/architecture.md` — system design
- `_LOUIE-output/tech-stack.md` — build-time stack
- `_LOUIE-output/runbook.md` — runtime ops (deployment, ports, commands, env, first-check debugging)
- `_LOUIE-output/roadmap.md` — bigger changes / epics list (created at setup)
- `_LOUIE-output/implementations/<feature>/` — per-feature folder (`feature.md`, `requirements.md`, `decisions.md`, `bugfixes/`)
- `_LOUIE-output/bugfixes/overview.md` — cross-project bug-fix index
<!-- /LOUIE-FRAMEWORK -->
CONTENT
  echo "  Created/updated GEMINI.md with LOUIE section."
fi

echo ""
echo "Done!"
echo ""

# Source adapters (louie-from-source) — keep private adapters out of version control
if ! grep -qs '^louie-adapters/' "$LOUIE_DIR/.gitignore"; then
  {
    echo ""
    echo "# Private LOUIE source adapters (credentials) — never commit"
    echo "louie-adapters/"
  } >> "$LOUIE_DIR/.gitignore"
  echo "  Added louie-adapters/ to .gitignore"
fi

# Report source-adapter availability (project-local louie-adapters/ overrides ~/.louie/adapters)
GLOBAL_ADAPTERS="$HOME/.louie/adapters"
if ls "$LOUIE_DIR/louie-adapters"/*/adapter.md > /dev/null 2>&1; then
  echo "  Source adapters (project): $(cd "$LOUIE_DIR/louie-adapters" && ls -d */ | tr -d '/' | tr '\n' ' ')"
elif ls "$GLOBAL_ADAPTERS"/*/adapter.md > /dev/null 2>&1; then
  echo "  Source adapters (global): $(cd "$GLOBAL_ADAPTERS" && ls -d */ | tr -d '/' | tr '\n' ' ')"
else
  echo "  No source adapters found — louie-from-source will be unavailable."
  echo "  Install one to ~/.louie/adapters/<name>/adapter.md to enable it for all projects."
fi
echo ""

# Detect existing project — recommend louie-import if so
EXISTING_PROJECT=0
HAS_V1_DOCS=0
if [ -f "$LOUIE_DIR/docs/implementations/overview.md" ]; then
  if ls "$LOUIE_DIR/docs/implementations/"*.md 2>/dev/null | grep -v '/overview\.md$' > /dev/null; then
    EXISTING_PROJECT=1
    HAS_V1_DOCS=1
  fi
fi
if [ $EXISTING_PROJECT -eq 0 ]; then
  for marker in package.json pyproject.toml Cargo.toml go.mod pom.xml build.gradle composer.json Gemfile mix.exs setup.py requirements.txt; do
    if [ -f "$LOUIE_DIR/$marker" ]; then EXISTING_PROJECT=1; break; fi
  done
fi
if [ $EXISTING_PROJECT -eq 0 ]; then
  for srcdir in src app lib; do
    if [ -d "$LOUIE_DIR/$srcdir" ]; then EXISTING_PROJECT=1; break; fi
  done
fi

if [ $EXISTING_PROJECT -eq 1 ]; then
  if [ $HAS_V1_DOCS -eq 1 ]; then
    echo "Detected v1 LOUIE docs at docs/implementations/."
    echo "Run 'louie-import' in Gemini CLI next to translate them into LOUIE format."
  else
    echo "Detected existing project source."
    echo "Run 'louie-import' in Gemini CLI next to have LOUIE generate architecture,"
    echo "tech-stack, runbook, and feature docs from the existing code."
  fi
else
  echo "You can now type 'louie-setup' in Gemini CLI to start a new project,"
  echo "or 'louie-feature' to add a feature."
fi
