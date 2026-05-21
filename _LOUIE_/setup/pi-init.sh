#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOUIE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "LOUIE — Pi Coding Agent Setup"
echo "=============================="
echo ""

AGENTS_MD="$LOUIE_DIR/AGENTS.md"
LOUIE_MARKER="<!-- LOUIE-FRAMEWORK -->"

if [ -f "$AGENTS_MD" ] && grep -q "$LOUIE_MARKER" "$AGENTS_MD"; then
  echo "  AGENTS.md already contains LOUIE section — skipped."
else
  cat >> "$AGENTS_MD" << 'CONTENT'

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
- `louie-review` → `_LOUIE_/commands/louie-review.md`
- `louie-review-doc` → `_LOUIE_/commands/louie-review-doc.md`
- `louie-review-mode` → `_LOUIE_/commands/louie-review-mode.md`
- `louie-test` → `_LOUIE_/commands/louie-test.md`
- `louie-doc` → `_LOUIE_/commands/louie-doc.md`
- `louie-ideate` → `_LOUIE_/commands/louie-ideate.md`
- `louie-roadmap` → `_LOUIE_/commands/louie-roadmap.md`
- `louie-recipe` → `_LOUIE_/commands/louie-recipe.md`

### Critical Rules

1. **Never implement directly** — create a feature document and get user confirmation first.
2. **Never start feature work** without a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
3. **Never merge to `main`** without explicit user approval after Max's review and Ava's tests pass.

### Key Files

- `README.md` — framework overview (project root)
- `_LOUIE_/workflow/ai-workflow.md` — full workflow
- `_LOUIE_/guidelines/coding-guidelines.md` — coding rules
- `_LOUIE_/agents/` — agent definitions
- `_LOUIE-output/architecture.md` — system design
- `_LOUIE-output/tech-stack.md` — build-time stack
- `_LOUIE-output/runbook.md` — runtime ops (deployment, ports, commands, env, first-check debugging)
- `_LOUIE-output/roadmap.md` — pre-feature idea list (lazy-created on first `louie-roadmap add`)
- `_LOUIE-output/implementations/<feature>/` — per-feature folder (`feature.md`, `requirements.md`, `decisions.md`, `bugfixes/`)
- `_LOUIE-output/bugfixes/overview.md` — cross-project bug-fix index
<!-- /LOUIE-FRAMEWORK -->
CONTENT
  echo "  Created/updated AGENTS.md with LOUIE section."
fi

echo ""
echo "Done!"
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
    echo "Run 'louie-import' in pi next to translate them into LOUIE format."
  else
    echo "Detected existing project source."
    echo "Run 'louie-import' in pi next to have LOUIE generate architecture,"
    echo "tech-stack, runbook, and feature docs from the existing code."
  fi
else
  echo "You can now type 'louie-setup' in pi to start a new project,"
  echo "or 'louie-feature' to add a feature."
fi
