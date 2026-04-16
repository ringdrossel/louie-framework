#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOUIE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "LOUIE — Cursor Setup"
echo "====================="
echo ""

CURSORRULES="$LOUIE_DIR/.cursorrules"
LOUIE_MARKER="<!-- LOUIE-FRAMEWORK -->"

if [ -f "$CURSORRULES" ] && grep -q "$LOUIE_MARKER" "$CURSORRULES"; then
  echo "  .cursorrules already contains LOUIE section — skipped."
else
  cat >> "$CURSORRULES" << 'CONTENT'

<!-- LOUIE-FRAMEWORK -->
## LOUIE Framework

This project uses **LOUIE** (Lean Orchestration for Unified Intelligent Engineering) for AI-assisted development.

### Command Routing

When the user types a `louie-*` command (e.g., `louie-setup`, `louie-feature`), read the matching file from `_LOUIE_/commands/` and follow the instructions in it.

Available commands:
- `louie-setup` → `_LOUIE_/commands/louie-setup.md`
- `louie-feature` → `_LOUIE_/commands/louie-feature.md`
- `louie-extend` → `_LOUIE_/commands/louie-extend.md`
- `louie-update` → `_LOUIE_/commands/louie-update.md`
- `louie-bugfix` → `_LOUIE_/commands/louie-bugfix.md`
- `louie-review` → `_LOUIE_/commands/louie-review.md`
- `louie-review-doc` → `_LOUIE_/commands/louie-review-doc.md`
- `louie-test` → `_LOUIE_/commands/louie-test.md`
- `louie-doc` → `_LOUIE_/commands/louie-doc.md`
- `louie-ideate` → `_LOUIE_/commands/louie-ideate.md`

### Key Files

- `README.md` — framework overview (project root)
- `_LOUIE_/workflow/ai-workflow.md` — full workflow
- `_LOUIE_/guidelines/coding-guidelines.md` — coding rules
- `_LOUIE_/agents/` — agent definitions
- `_LOUIE-output/` — agent-produced artifacts (requirements, architecture, feature docs)
<!-- /LOUIE-FRAMEWORK -->
CONTENT
  echo "  Created/updated .cursorrules with LOUIE section."
fi

echo ""
echo "Done!"
echo ""
echo "You can now type 'louie-setup' in Cursor to start a new project,"
echo "or 'louie-feature' to add a feature."
