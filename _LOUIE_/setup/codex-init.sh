#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOUIE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/../commands"

echo "LOUIE — Codex CLI Setup"
echo "========================"
echo ""

# Codex CLI discovers project-shared skills at .codex/skills/<name>/SKILL.md.
# Each skill is a directory with a SKILL.md that opens with YAML frontmatter
# (name + description). We install one skill per louie-* command; the
# description is worded to bias Codex toward explicit slash invocation
# rather than implicit auto-activation on inferred user intent.
mkdir -p "$LOUIE_DIR/.codex/skills"

count=0
for cmd in "$COMMANDS_SRC"/louie-*.md; do
  if [ -f "$cmd" ]; then
    name=$(basename "$cmd" .md)
    skill_dir="$LOUIE_DIR/.codex/skills/$name"
    mkdir -p "$skill_dir"
    {
      echo "---"
      echo "name: $name"
      echo "description: Procedure for the LOUIE command \"$name\". Activate ONLY when the user explicitly types \"/$name\" or \"$name\" as a command — never invoke implicitly based on inferred intent."
      echo "---"
      echo ""
      cat "$cmd"
    } > "$skill_dir/SKILL.md"
    count=$((count + 1))
    echo "  Installed /$name"
  fi
done

AGENTS_MD="$LOUIE_DIR/AGENTS.md"
LOUIE_MARKER="<!-- LOUIE-FRAMEWORK -->"

if [ -f "$AGENTS_MD" ] && grep -q "$LOUIE_MARKER" "$AGENTS_MD"; then
  echo ""
  echo "  AGENTS.md already contains LOUIE section — skipped."
else
  cat >> "$AGENTS_MD" << 'CONTENT'

<!-- LOUIE-FRAMEWORK -->
## LOUIE Framework

This project uses **LOUIE** (Lean Orchestration for Unified Intelligent Engineering) for AI-assisted development.

### Commands

LOUIE commands are installed as Codex CLI skills under `.codex/skills/<name>/SKILL.md`. Invoke them explicitly as `/louie-setup`, `/louie-feature`, etc. Typing the bare name (e.g. `louie-setup`) also works — the routing table below lets the agent resolve names that miss the autocomplete.

| Command | Description |
|---------|-------------|
| `/louie-setup` | Initialize a new project |
| `/louie-import` | Import an existing project (cold or v1 docs) into LOUIE |
| `/louie-migrate` | Migrate an old-layout LOUIE project to per-feature folders |
| `/louie-feature` | Add a new feature (full agent chain) |
| `/louie-extend` | Extend an existing feature |
| `/louie-update` | Quick change (< 50 lines) |
| `/louie-bugfix` | Diagnose and fix a bug |
| `/louie-review` | Code review by Max |
| `/louie-review-doc` | Review + fix + update docs |
| `/louie-review-mode` | View or change the project review mode (manual / auto-fix-critical / auto-fix-all) |
| `/louie-test` | Write or improve tests with Ava |
| `/louie-doc` | Update documentation + commit message |
| `/louie-ideate` | Brainstorm ideas with Ivy |
| `/louie-roadmap` | Capture pre-feature ideas in `_LOUIE-output/roadmap.md`; promote one to a full feature |
| `/louie-recipe` | Browse or load a reusable recipe |

Skill files are kept in sync with `_LOUIE_/commands/` by `bash _LOUIE_/setup/codex-init.sh` (also re-run by `louie-update-framework`). Their frontmatter is worded so Codex does **not** auto-activate them — every LOUIE command requires explicit user invocation.

### Critical Rules

1. **Never implement directly** — create a feature document and get user confirmation first.
2. **Never start feature work** without a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
3. **Never merge to `main`** without explicit user approval after Max's review and Ava's tests pass.
4. **Never write implementation learnings to `_LOUIE-output/runbook.md`.** The runbook is operational reference only (ports, env vars, external services, commands, first-check debugging). Framework quirks, cache rules, "I learned X" → code-local `// WHY` comments + per-feature `bugfixes/<slug>.md` § Detect / Avoid. There is no `## Common Gotchas` section; do not create one. Applies to every edit path, including ad-hoc "update the specs" requests that don't route through a `louie-*` command.

### Key Files

- `README.md` — framework overview (project root)
- `_LOUIE_/workflow/ai-workflow.md` — full workflow
- `_LOUIE_/guidelines/coding-guidelines.md` — coding rules
- `_LOUIE_/agents/` — agent definitions
- `_LOUIE-output/architecture.md` — system design
- `_LOUIE-output/tech-stack.md` — build-time stack
- `_LOUIE-output/runbook.md` — runtime ops (deployment, ports, commands, env, first-check debugging)
- `_LOUIE-output/roadmap.md` — pre-feature idea list (lazy-created on first `/louie-roadmap add`)
- `_LOUIE-output/implementations/<feature>/` — per-feature folder (`feature.md`, `requirements.md`, `decisions.md`, `bugfixes/`)
- `_LOUIE-output/bugfixes/overview.md` — cross-project bug-fix index
<!-- /LOUIE-FRAMEWORK -->
CONTENT
  echo ""
  echo "  Created/updated AGENTS.md with LOUIE section."
fi

echo ""
echo "Done! $count commands installed."
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
    echo "Run /louie-import in Codex next to translate them into LOUIE format."
  else
    echo "Detected existing project source."
    echo "Run /louie-import in Codex next to have LOUIE generate architecture,"
    echo "tech-stack, runbook, and feature docs from the existing code."
  fi
else
  echo "You can now use /louie-setup in Codex to start a new project,"
  echo "or /louie-feature to add a feature."
fi
