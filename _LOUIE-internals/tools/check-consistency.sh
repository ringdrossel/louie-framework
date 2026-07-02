#!/usr/bin/env bash
# check-consistency.sh — framework-dev lint (finding E-02).
#
# The framework registers its commands on ~17 hand-edited surfaces (12 init
# scripts + 4 doc tables + root CLAUDE.md). This lint catches the drift that
# hand-editing reliably produces. Run from anywhere inside the repo:
#
#   bash _LOUIE-internals/tools/check-consistency.sh
#
# Checks:
#   1. Command-set consistency — every surface's command listing matches
#      _LOUIE_/commands/louie-*.md (the canonical set), minus explicit
#      per-surface exclusions.
#   2. Merged-bullet corruption — the "two bullets on one line" pattern that
#      has now produced two live bugs (see CHANGELOG + E-02).
#   3. Path existence — every backticked `_LOUIE_/...` path referenced in
#      distributed files exists in the repo.
#   4. sh/bat pairing — every init script exists in both variants and both
#      list the same commands.
#
# This tool is framework-repo-only. It is never distributed downstream.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

ERRORS=0
fail() { echo "FAIL: $*"; ERRORS=$((ERRORS + 1)); }

# Deliberate omissions: "surface-path:command" lines, one per entry.
# Empty by default — every surface must list every command.
EXCLUSIONS=""

excluded() { # $1=surface $2=command
  printf '%s\n' "$EXCLUSIONS" | grep -qxF "$1:$2"
}

# The registration surfaces (command tables / command bullet lists).
DOC_SURFACES="CLAUDE.md README.md _LOUIE_/workflow/ai-workflow.md _LOUIE_/setup/project-setup.md"
INIT_SURFACES="$(ls _LOUIE_/setup/*-init.sh _LOUIE_/setup/*-init.bat 2>/dev/null)"
ALL_SURFACES="$DOC_SURFACES $INIT_SURFACES"

# Normalize a surface for parsing: drop CR, strip .bat echo prefixes and ^ escapes.
normalize() {
  sed -e 's/\r$//' -e 's/^echo \./echo /' -e 's/^echo //' -e 's/\^//g' "$1"
}

# Extract the set of commands a surface registers. A command counts as listed
# only on a *listing line* — a markdown table row or a `cmd` → file bullet —
# so prose mentions can't mask a missing table entry (that is exactly how the
# louie-update-framework gap stayed invisible).
listed_commands() {
  normalize "$1" \
    | grep -E '^\| .*`/?louie-[a-z][a-z-]*`|^- `louie-[a-z][a-z-]*` →' \
    | grep -oE '`/?louie-[a-z][a-z-]*`' \
    | tr -d '`/' | sort -u
}

canonical_commands() {
  ls _LOUIE_/commands/louie-*.md | xargs -n1 basename | sed 's/\.md$//' | sort -u
}

# --- Check 1: command-set consistency --------------------------------------
CANONICAL="$(canonical_commands)"

for surface in $ALL_SURFACES; do
  [ -f "$surface" ] || { fail "surface missing: $surface"; continue; }
  LISTED="$(listed_commands "$surface")"
  for cmd in $CANONICAL; do
    if ! printf '%s\n' "$LISTED" | grep -qxF "$cmd"; then
      excluded "$surface" "$cmd" || fail "$surface: command not listed: $cmd"
    fi
  done
  for cmd in $LISTED; do
    if ! printf '%s\n' "$CANONICAL" | grep -qxF "$cmd"; then
      fail "$surface: lists unknown command (no _LOUIE_/commands/$cmd.md): $cmd"
    fi
  done
done

# --- Check 2: merged-bullet corruption --------------------------------------
for surface in $ALL_SURFACES; do
  [ -f "$surface" ] || continue
  MERGED="$(normalize "$surface" | grep -nE '^- `[^`]+` — .*- `' || true)"
  if [ -n "$MERGED" ]; then
    fail "$surface: merged bullet detected (two list items on one line):"
    printf '%s\n' "$MERGED" | sed 's/^/      /'
  fi
done

# --- Check 3: referenced _LOUIE_/ paths exist --------------------------------
# Scope: distributed files only (root CLAUDE.md, README.md, everything under
# _LOUIE_/). Internals docs may reference planned/future paths and are exempt.
# Skipped tokens: placeholders (<...>), globs (*), and ellipses.
PATH_SCAN_FILES="$(printf '%s\n' CLAUDE.md README.md; find _LOUIE_ -name '*.md'; printf '%s\n' $INIT_SURFACES)"

for f in $PATH_SCAN_FILES; do
  [ -f "$f" ] || continue
  normalize "$f" | grep -oE '`_LOUIE_/[^`]+`' | tr -d '`' | sort -u | while read -r ref; do
    case "$ref" in
      *'<'*|*'*'*|*...*) continue ;;
    esac
    # "foo.sh/.bat" means both variants exist
    if printf '%s' "$ref" | grep -qE '\.sh/\.bat$'; then
      base="${ref%.sh/.bat}"
      [ -f "$base.sh" ] || echo "MISSING $f -> $base.sh"
      [ -f "$base.bat" ] || echo "MISSING $f -> $base.bat"
      continue
    fi
    [ -e "$ref" ] || echo "MISSING $f -> $ref"
  done
done > /tmp/louie-lint-paths.$$ 2>&1
if [ -s /tmp/louie-lint-paths.$$ ]; then
  while read -r line; do fail "referenced path does not exist: ${line#MISSING }"; done < /tmp/louie-lint-paths.$$
fi
rm -f /tmp/louie-lint-paths.$$

# --- Check 4: sh/bat pairing --------------------------------------------------
for sh in _LOUIE_/setup/*-init.sh; do
  bat="${sh%.sh}.bat"
  [ -f "$bat" ] || { fail "init script has no .bat twin: $sh"; continue; }
  if [ "$(listed_commands "$sh")" != "$(listed_commands "$bat")" ]; then
    fail "command lists differ between $sh and $bat:"
    diff <(listed_commands "$sh") <(listed_commands "$bat") | sed 's/^/      /'
  fi
done
for bat in _LOUIE_/setup/*-init.bat; do
  sh="${bat%.bat}.sh"
  [ -f "$sh" ] || fail "init script has no .sh twin: $bat"
done

# --- Result -------------------------------------------------------------------
echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "check-consistency: $ERRORS error(s)."
  exit 1
fi
echo "check-consistency: OK ($(printf '%s\n' "$CANONICAL" | wc -l | tr -d ' ') commands, $(printf '%s\n' $ALL_SURFACES | wc -l | tr -d ' ') surfaces)."
