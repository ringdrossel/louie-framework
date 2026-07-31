#!/usr/bin/env bash
#
# LOUIE one-liner installer.
#
#   curl -fsSL https://raw.githubusercontent.com/ringdrossel/louie-framework/main/install.sh | bash -s -- claude
#
# Design notes: _LOUIE-internals/install.md
#
# NOTE: this script must stay fully non-interactive. Under `curl | bash` stdin IS
# the script text, so any `read` would consume its own source. Every choice is a
# flag or an autodetect.

set -euo pipefail

REPO_URL="https://github.com/ringdrossel/louie-framework"
REF="${LOUIE_VERSION:-main}"
TARGET="$PWD"
FORCE=0
RUN_INIT=1
TOOLS=()

KNOWN_TOOLS="claude cursor codex gemini opencode pi"

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '%s\n' "$*"; }

usage() {
  cat <<'USAGE'
LOUIE installer

  install.sh [tool ...] [options]

Tools:
  claude, cursor, codex, gemini, opencode, pi, all
  (omitted: autodetected from the target directory; defaults to claude)

Options:
  --dir <path>       Install target (default: current directory)
  --version <ref>    Git ref to install (default: main; env: LOUIE_VERSION)
  --force            Overwrite an existing _LOUIE_/ install
  --no-init          Copy files only, skip the tool init scripts
  -h, --help         Show this help

Examples:
  curl -fsSL .../install.sh | bash -s -- claude
  curl -fsSL .../install.sh | bash -s -- claude cursor --dir ~/projects/app
  LOUIE_VERSION=v1.1.0 curl -fsSL .../install.sh | bash
USAGE
}

# ---------------------------------------------------------------- arguments

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      [ $# -ge 2 ] || { err "--dir requires a path"; exit 2; }
      TARGET="$2"; shift 2 ;;
    --dir=*)     TARGET="${1#*=}"; shift ;;
    --version)
      [ $# -ge 2 ] || { err "--version requires a ref"; exit 2; }
      REF="$2"; shift 2 ;;
    --version=*) REF="${1#*=}"; shift ;;
    --force)     FORCE=1; shift ;;
    --no-init)   RUN_INIT=0; shift ;;
    -h|--help)   usage; exit 0 ;;
    -*)          err "Unknown option: $1"; usage >&2; exit 2 ;;
    all)
      # shellcheck disable=SC2206
      TOOLS=($KNOWN_TOOLS); shift ;;
    *)
      case " $KNOWN_TOOLS " in
        *" $1 "*) TOOLS+=("$1"); shift ;;
        *) err "Unknown tool: $1 (known: $KNOWN_TOOLS, all)"; exit 2 ;;
      esac ;;
  esac
done

for cmd in curl tar; do
  command -v "$cmd" >/dev/null 2>&1 || { err "$cmd is required but not installed."; exit 1; }
done

# The installer never creates the project directory — a typo should not
# silently produce a stray tree somewhere.
[ -d "$TARGET" ] || { err "Target directory does not exist: $TARGET"; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

info "LOUIE — Install"
info "==============="
info ""
info "  Source: $REPO_URL @ $REF"
info "  Target: $TARGET"
info ""

# ------------------------------------------------------------------- guards

if [ -e "$TARGET/_LOUIE_" ] && [ "$FORCE" -eq 0 ]; then
  if [ -f "$TARGET/_LOUIE_/VERSION" ]; then
    installed="$(head -n1 "$TARGET/_LOUIE_/VERSION" | tr -d '[:space:]')"
    err "LOUIE $installed is already installed at $TARGET."
  else
    err "A _LOUIE_/ directory already exists at $TARGET (pre-versioning install)."
  fi
  info ""
  info "To upgrade, run 'louie-update-framework' in your AI assistant — it does"
  info "version-gated migrations and shows a changelog delta, which a plain file"
  info "overwrite skips. Use --force here only to reinstall from scratch."
  exit 1
fi

# -------------------------------------------------------------------- fetch

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

info "Downloading..."
if ! curl -fsSL "$REPO_URL/archive/$REF.tar.gz" | tar -xz -C "$TMP"; then
  err "Download failed for ref '$REF'."
  err "Check the ref name and your network connection: $REPO_URL"
  exit 1
fi

SRC="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[ -n "$SRC" ] && [ -d "$SRC/_LOUIE_" ] || { err "Unexpected archive layout — no _LOUIE_/ found."; exit 1; }

VERSION="unknown"
[ -f "$SRC/_LOUIE_/VERSION" ] && VERSION="$(head -n1 "$SRC/_LOUIE_/VERSION" | tr -d '[:space:]')"

# --------------------------------------------------------------------- copy
# Allowlist, never denylist: anything new at the repo root stays out of user
# projects unless it is opted in here deliberately (see install.md).

info "Installing framework files..."
rm -rf "$TARGET/_LOUIE_"
cp -R "$SRC/_LOUIE_" "$TARGET/_LOUIE_"
chmod +x "$TARGET/_LOUIE_/setup/"*.sh 2>/dev/null || true
info "  _LOUIE_/            framework $VERSION"

# _LOUIE-output/ holds the user's work — seed missing skeleton files only,
# never overwrite. Same rule louie-update-framework follows.
seeded=0
skipped=0
if [ -d "$SRC/_LOUIE-output" ]; then
  while IFS= read -r rel; do
    dest="$TARGET/_LOUIE-output/$rel"
    if [ -e "$dest" ]; then
      skipped=$((skipped + 1))
    else
      mkdir -p "$(dirname "$dest")"
      cp "$SRC/_LOUIE-output/$rel" "$dest"
      seeded=$((seeded + 1))
    fi
  done < <(cd "$SRC/_LOUIE-output" && find . -type f | sed 's|^\./||')
fi

if [ "$skipped" -gt 0 ]; then
  info "  _LOUIE-output/      $seeded file(s) seeded, $skipped existing file(s) kept"
else
  info "  _LOUIE-output/      $seeded file(s) seeded"
fi

# --------------------------------------------------------------------- init

if [ "$RUN_INIT" -eq 0 ]; then
  info ""
  info "Skipped tool init (--no-init). Run _LOUIE_/setup/<tool>-init.sh when ready."
  exit 0
fi

if [ ${#TOOLS[@]} -eq 0 ]; then
  # Autodetect. All matches are used — a project may carry several integrations.
  # Marker set mirrors louie-update-framework step 1; keep them in sync.
  # Trailing `|| true` on each: under `set -e` a non-matching marker would
  # otherwise abort the script.
  [ -d "$TARGET/.claude" ]                                      && TOOLS+=("claude")   || true
  { [ -f "$TARGET/.cursorrules" ] || [ -d "$TARGET/.cursor" ]; } && TOOLS+=("cursor")   || true
  [ -d "$TARGET/.codex" ]                                       && TOOLS+=("codex")    || true
  { [ -d "$TARGET/.gemini" ] || [ -f "$TARGET/GEMINI.md" ]; }    && TOOLS+=("gemini")   || true
  [ -d "$TARGET/.opencode" ]                                    && TOOLS+=("opencode") || true
  [ -d "$TARGET/.pi" ]                                          && TOOLS+=("pi")       || true

  if [ ${#TOOLS[@]} -eq 0 ]; then
    TOOLS=("claude")
    info ""
    info "No AI tool detected — setting up for Claude Code."
    info "For another tool, run: bash _LOUIE_/setup/<tool>-init.sh"
  else
    info ""
    info "Detected: ${TOOLS[*]}"
  fi
fi

for tool in "${TOOLS[@]}"; do
  script="$TARGET/_LOUIE_/setup/$tool-init.sh"
  if [ ! -f "$script" ]; then
    err "Init script missing: _LOUIE_/setup/$tool-init.sh"
    exit 1
  fi
  info ""
  # The init scripts resolve their target from their own location and print
  # their own next-step guidance (including detecting an existing project and
  # suggesting louie-import) — don't duplicate that here.
  bash "$script"
done

info ""
info "LOUIE $VERSION installed."
