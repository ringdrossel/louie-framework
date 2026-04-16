#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOUIE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/../commands"

echo "LOUIE — Claude Code Setup"
echo "========================="
echo ""

# Create .claude/commands/ directory
mkdir -p "$LOUIE_DIR/.claude/commands"

# Copy all louie-* command files
count=0
for cmd in "$COMMANDS_SRC"/louie-*.md; do
  if [ -f "$cmd" ]; then
    cp "$cmd" "$LOUIE_DIR/.claude/commands/"
    count=$((count + 1))
    echo "  Installed /$(basename "$cmd" .md)"
  fi
done

# Create CLAUDE.md if it doesn't exist, or append LOUIE section
CLAUDE_MD="$LOUIE_DIR/CLAUDE.md"
LOUIE_MARKER="<!-- LOUIE-FRAMEWORK -->"

if [ -f "$CLAUDE_MD" ] && grep -q "$LOUIE_MARKER" "$CLAUDE_MD"; then
  echo ""
  echo "  CLAUDE.md already contains LOUIE section — skipped."
else
  cat >> "$CLAUDE_MD" << 'CONTENT'

<!-- LOUIE-FRAMEWORK -->
## LOUIE Framework

This project uses **LOUIE** (Lean Orchestration for Unified Intelligent Engineering) for AI-assisted development.

### Commands

LOUIE commands are available as slash commands (`/louie-*`). Type `/louie-` to see all available commands.

| Command | Description |
|---------|-------------|
| `/louie-setup` | Initialize a new project |
| `/louie-feature` | Add a new feature (full agent chain) |
| `/louie-extend` | Extend an existing feature |
| `/louie-update` | Quick change (< 50 lines) |
| `/louie-bugfix` | Diagnose and fix a bug |
| `/louie-review` | Code review by Max |
| `/louie-review-doc` | Review + fix + update docs |
| `/louie-test` | Write or improve tests with Ava |
| `/louie-doc` | Update documentation + commit message |
| `/louie-ideate` | Brainstorm ideas with Ivy |

### Key Files

- `_LOUIE_/README.md` — framework overview
- `_LOUIE_/workflow/ai-workflow.md` — full workflow
- `_LOUIE_/guidelines/coding-guidelines.md` — coding rules
- `_LOUIE_/agents/` — agent definitions
- `_LOUIE-output/` — agent-produced artifacts (requirements, architecture, feature docs)
<!-- /LOUIE-FRAMEWORK -->
CONTENT
  echo ""
  echo "  Created/updated CLAUDE.md with LOUIE section."
fi

echo ""
echo "Done! $count commands installed."
echo ""
echo "You can now use /louie-setup to start a new project,"
echo "or /louie-feature to add a feature."
