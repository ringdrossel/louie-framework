#!/usr/bin/env bash
#
# LOUIE bulk updater — scan a directory tree for LOUIE projects, report their
# versions, and optionally refresh the framework files in each.
#
#   bash update-all.sh ~/projects              # refresh every LOUIE project found
#   bash update-all.sh ~/projects --dry-run    # report only, change nothing
#
# SCOPE: this does the *mechanical* part of louie-update-framework — replace
# _LOUIE_/, refresh the context-file block, re-run init scripts. It deliberately
# does NOT do the judgment parts: version-gated migrations, the flat->per-feature
# layout migration, or bootstrapping newly-canonical _LOUIE-output/ files. Those
# need the AI assistant per project; this script reports which projects need it.
#
# It refreshes every LOUIE project it finds. The only two things that stop an
# update are: the directory isn't a LOUIE project, or it IS the framework's own
# source repo (updating that would overwrite unreleased work).
#
# Design notes: _LOUIE-internals/install.md § Bulk update

set -euo pipefail

REPO_URL="https://github.com/ringdrossel/louie-framework"
REF="${LOUIE_VERSION:-main}"
APPLY=1
ROOTS=()
MAXDEPTH=6

err()  { printf 'Error: %s\n' "$*" >&2; }
info() { printf '%s\n' "$*"; }

usage() {
  cat <<'USAGE'
LOUIE bulk updater

  update-all.sh <dir> [<dir> ...] [options]

Scans each <dir> for LOUIE projects (directories containing _LOUIE_/) and
reports their version against the latest release, then refreshes the framework
files in each. Use --dry-run to preview without changing anything.

Only two things stop an update: the directory isn't a LOUIE project, or it's
the framework's own source repo. Anything else is refreshed, with conditions
needing follow-up reported at the end.

Options:
  --dry-run, -n    Report only, change nothing
  --version <ref>  Framework ref to install (default: main; env: LOUIE_VERSION)
  --depth <n>      Directory scan depth (default: 6)
  -h, --help       Show this help

Never touches _LOUIE-output/ — that's your work.
USAGE
}

# ---------------------------------------------------------------- arguments

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run|-n)  APPLY=0; shift ;;
    --version)
      [ $# -ge 2 ] || { err "--version requires a ref"; exit 2; }
      REF="$2"; shift 2 ;;
    --version=*)   REF="${1#*=}"; shift ;;
    --depth)
      [ $# -ge 2 ] || { err "--depth requires a number"; exit 2; }
      MAXDEPTH="$2"; shift 2 ;;
    --depth=*)     MAXDEPTH="${1#*=}"; shift ;;
    -h|--help)     usage; exit 0 ;;
    -*)            err "Unknown option: $1"; usage >&2; exit 2 ;;
    *)             ROOTS+=("$1"); shift ;;
  esac
done

if [ ${#ROOTS[@]} -eq 0 ]; then
  err "No directory given."
  usage >&2
  exit 2
fi

for cmd in curl tar; do
  command -v "$cmd" >/dev/null 2>&1 || { err "$cmd is required but not installed."; exit 1; }
done

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || { err "Not a directory: $root"; exit 1; }
done

# -------------------------------------------------------------------- fetch
# Fetched ONCE and reused for every project — never N downloads for N projects.

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

info "Fetching LOUIE @ $REF ..."
if ! curl -fsSL "$REPO_URL/archive/$REF.tar.gz" | tar -xz -C "$TMP"; then
  err "Download failed for ref '$REF'. Check the ref name and your connection."
  exit 1
fi

SRC="$(find "$TMP" -mindepth 1 -maxdepth 1 -type d | head -n1)"
[ -n "$SRC" ] && [ -d "$SRC/_LOUIE_" ] || { err "Unexpected archive layout — no _LOUIE_/ found."; exit 1; }

LATEST="unknown"
[ -f "$SRC/_LOUIE_/VERSION" ] && LATEST="$(head -n1 "$SRC/_LOUIE_/VERSION" | tr -d '[:space:]')"

# The changelog is NOT in the tarball — .gitattributes marks _LOUIE-internals/
# as export-ignore, which applies to archives (git clone, as used by
# louie-update-framework, still gets it). Fetch it separately; a failure here is
# cosmetic, so don't abort the run.
CHANGELOG="$TMP/CHANGELOG.md"
curl -fsSL "https://raw.githubusercontent.com/ringdrossel/louie-framework/$REF/_LOUIE-internals/CHANGELOG.md" \
  -o "$CHANGELOG" 2>/dev/null || : > "$CHANGELOG"

info "Latest: $LATEST"
info ""

# ------------------------------------------------------------------ helpers

major_of() { printf '%s' "${1%%.*}"; }

# Prints the release headers in the (local, pulled] gap — the same delta
# louie-update-framework reports, headers only.
changelog_gap() {
  local from="$1" to="$2" changelog="$CHANGELOG"
  [ -s "$changelog" ] || return 0
  awk -v from="$from" -v to="$to" '
    /^## [0-9]+\.[0-9]+\.[0-9]+ / {
      split($2, v, ".")
      split(from, f, ".")
      cur = v[1]*1000000 + v[2]*1000 + v[3]
      lo  = f[1]*1000000 + f[2]*1000 + f[3]
      if (cur > lo) print "      " $0
    }
  ' "$changelog"
}

# The old flat artifact layout — needs louie-migrate, which this script wont do.
has_flat_layout() {
  local p="$1"
  [ -d "$p/_LOUIE-output/requirements" ] && return 0
  if [ -d "$p/_LOUIE-output/implementations" ]; then
    find "$p/_LOUIE-output/implementations" -maxdepth 1 -name '*.md' \
      ! -name 'overview.md' -print -quit 2>/dev/null | grep -q . && return 0
  fi
  return 1
}

# The framework's own source repo is NOT an installation of the framework.
# Updating it would rm -rf the maintainer's _LOUIE_/ source tree and replace it
# with the published copy, silently reverting in-progress work. _LOUIE-internals/
# is the reliable marker: repo-only, never distributed, never present in an
# installed project.
is_framework_repo() {
  local p="$1"
  [ -d "$p/_LOUIE-internals" ] && [ -f "$p/install.sh" ]
}

# Returns 0 if $1 is strictly newer than $2.
version_gt() {
  local a="$1" b="$2"
  [ "$a" = "pre-versioning" ] && return 1
  [ "$b" = "pre-versioning" ] && return 0
  local am ai ap bm bi bp
  IFS=. read -r am ai ap <<EOF
$a
EOF
  IFS=. read -r bm bi bp <<EOF
$b
EOF
  [ $(( am*1000000 + ai*1000 + ${ap:-0} )) -gt $(( bm*1000000 + bi*1000 + ${bp:-0} )) ]
}

is_git_repo() { git -C "$1" rev-parse --git-dir >/dev/null 2>&1; }

# Replace the block between <!-- LOUIE-FRAMEWORK --> and <!-- /LOUIE-FRAMEWORK -->,
# preserving everything the user added around it.
#
# Files predating the closing marker (early init scripts emitted only the opener)
# have no end boundary. Rather than punt, treat everything from the opening
# marker to EOF as framework content and regenerate it: init scripts *append*
# their block, so it always runs to the end of the file at the time it was
# written. Anything the user added afterwards would be inside that span, so a
# backup is written first and reported — return 4 signals "regenerated with
# backup" so the caller can say so.
refresh_context_block() {
  local file="$1" newblock="$2"
  [ -f "$file" ] || return 2
  grep -q '<!-- LOUIE-FRAMEWORK -->'  "$file" || return 2

  if ! grep -q '<!-- /LOUIE-FRAMEWORK -->' "$file"; then
    cp "$file" "$file.louie-bak"
    awk -v blockfile="$newblock" '
      /<!-- LOUIE-FRAMEWORK -->/ && !done {
        while ((getline line < blockfile) > 0) print line
        close(blockfile)
        done = 1
        next
      }
      !done { print }
    ' "$file" > "$file.louie-tmp" && mv "$file.louie-tmp" "$file"
    return 4
  fi

  awk -v blockfile="$newblock" '
    /<!-- LOUIE-FRAMEWORK -->/ && !inblock {
      inblock = 1
      while ((getline line < blockfile) > 0) print line
      close(blockfile)
      next
    }
    /<!-- \/LOUIE-FRAMEWORK -->/ && inblock { inblock = 0; next }
    !inblock { print }
  ' "$file" > "$file.louie-tmp" && mv "$file.louie-tmp" "$file"
}

# Pull the canonical context block out of a freshly generated init run.
extract_block_from() {
  local file="$1"
  sed -n '/<!-- LOUIE-FRAMEWORK -->/,/<!-- \/LOUIE-FRAMEWORK -->/p' "$file"
}

# ------------------------------------------------------------------ discover

PROJECTS=()
for root in "${ROOTS[@]}"; do
  while IFS= read -r d; do
    PROJECTS+=("$(cd "$(dirname "$d")" && pwd)")
  done < <(find "$root" -maxdepth "$MAXDEPTH" -type d -name '_LOUIE_' -not -path '*/node_modules/*' 2>/dev/null | sort)
done

if [ ${#PROJECTS[@]} -eq 0 ]; then
  info "No LOUIE projects found under: ${ROOTS[*]}"
  exit 0
fi

info "Found ${#PROJECTS[@]} LOUIE project(s)."
info ""

# ------------------------------------------------------------------- process

updated=0; skipped=0; current=0; needs_attention=0
ATTENTION=()
NOTES=()
OPTIONAL=()

for proj in "${PROJECTS[@]}"; do
  name="$(basename "$proj")"
  vfile="$proj/_LOUIE_/VERSION"
  if [ -f "$vfile" ]; then
    ver="$(head -n1 "$vfile" | tr -d '[:space:]')"
  else
    ver="pre-versioning"
  fi

  info "── $name"
  info "   $proj"

  # Never touch the framework's own source checkout — see is_framework_repo.
  if is_framework_repo "$proj"; then
    info "   framework source repo — not an installation; skipped"
    info ""
    continue
  fi

  info "   version: $ver → $LATEST"

  # Ahead of the published release (a local build, or a maintainer mid-release).
  # Refreshing would be a downgrade.
  if version_gt "$ver" "$LATEST"; then
    info "   SKIP: ahead of the published release ($ver > $LATEST) — refresh would downgrade it"
    ATTENTION+=("$name — ahead of latest ($ver > $LATEST); left alone")
    skipped=$((skipped + 1))
    needs_attention=$((needs_attention + 1))
    info ""
    continue
  fi

  # A matching version does NOT mean there is nothing to do. The context-file
  # block and the installed command/agent files drift independently of
  # _LOUIE_/VERSION — a project can sit at the latest version with a stale
  # CLAUDE.md section or a half-deleted .claude/commands/. So current projects
  # run the same refresh; only the label differs.
  AT_LATEST=0
  if [ "$ver" = "$LATEST" ]; then
    AT_LATEST=1
    info "   at latest — verifying installed files"
  fi

  # --- notes, not blockers ---------------------------------------------------
  # Only two things stop an update: it isn't a LOUIE project, or it's the
  # framework's own source. Everything else is refreshable — _LOUIE_/ is
  # framework-owned with no user content, and _LOUIE-output/ is never touched.
  # These conditions are reported so they can be followed up in the assistant.

  # The old flat layout doesn't block the refresh: louie-update-framework itself
  # supports declining the migration and carrying on, warning that newly-shipped
  # commands assume the new layout. Same warning here.
  if has_flat_layout "$proj"; then
    info "   NOTE: old flat _LOUIE-output/ layout — new commands assume per-feature folders"
    ATTENTION+=("$name — old flat _LOUIE-output/ layout; run louie-migrate")
    needs_attention=$((needs_attention + 1))
  fi

  if [ "$ver" != "pre-versioning" ] && [ "$(major_of "$ver")" != "$(major_of "$LATEST")" ]; then
    info "   NOTE: major version gap $ver → $LATEST — check for migrations"
    ATTENTION+=("$name — major version gap $ver → $LATEST; run louie-update-framework for migrations")
    needs_attention=$((needs_attention + 1))
  fi

  # Newer canonical outputs. Only the assistant can bootstrap these from a
  # project's existing artifacts, so they're reported, never generated here.
  for artifact in runbook roadmap; do
    if [ ! -f "$proj/_LOUIE-output/$artifact.md" ]; then
      info "   NOTE: _LOUIE-output/$artifact.md missing"
      OPTIONAL+=("$name — no $artifact.md")
      needs_attention=$((needs_attention + 1))
    fi
  done

  # Does the refresh actually change _LOUIE_/? If the tree already matches the
  # incoming one, there is nothing to overwrite and nothing to warn about.
  #
  # This check exists because the warning below is otherwise self-triggering:
  # once a run rewrites _LOUIE_/ and the user hasn't committed, EVERY later run
  # sees uncommitted changes there and reports overwriting them — detecting its
  # own prior output and calling it a risk. Comparing against the incoming
  # content distinguishes "someone edited the framework" from "a previous run
  # wrote exactly this".
  LOUIE_DIFFERS=1
  if diff -rq "$proj/_LOUIE_" "$SRC/_LOUIE_" >/dev/null 2>&1; then
    LOUIE_DIFFERS=0
  fi

  # The one thing this update destroys irreversibly: hand-edits to _LOUIE_/
  # files that were never committed. The directory is replaced wholesale, so
  # customized agents or commands are gone with no way back. Detect and report
  # it before touching anything — the update still proceeds.
  if [ "$LOUIE_DIFFERS" -eq 1 ] && is_git_repo "$proj" && [ -n "$(git -C "$proj" status --porcelain -- _LOUIE_ 2>/dev/null)" ]; then
    if [ "$APPLY" -eq 1 ]; then
      info "   WARNING: uncommitted changes inside _LOUIE_/ — overwriting them"
      NOTES+=("$name — had uncommitted _LOUIE_/ edits; the refresh overwrote them")
    else
      info "   WARNING: uncommitted changes inside _LOUIE_/ would be overwritten"
      ATTENTION+=("$name — has uncommitted _LOUIE_/ edits that a refresh would overwrite")
    fi
    needs_attention=$((needs_attention + 1))
  elif ! is_git_repo "$proj"; then
    info "   NOTE: not a git repository — no undo if you'd customized _LOUIE_/"
  fi

  gap="$(changelog_gap "$ver" "$LATEST")"
  if [ -n "$gap" ]; then
    info "   releases in gap:"
    info "$gap"
  fi

  if [ "$APPLY" -eq 0 ]; then
    if [ "$AT_LATEST" -eq 1 ]; then info "   would verify (dry run)"; else info "   would update (dry run)"; fi
    info ""
    continue
  fi

  # --- apply ----------------------------------------------------------------

  # _LOUIE_/ is the tool, wholly framework-owned — replace it outright. Private
  # source adapters live in louie-adapters/ at the project root, outside it.
  # Skipped when the tree already matches: no churn, no touched mtimes.
  if [ "$LOUIE_DIFFERS" -eq 1 ]; then
    rm -rf "$proj/_LOUIE_"
    cp -R "$SRC/_LOUIE_" "$proj/_LOUIE_"
    chmod +x "$proj/_LOUIE_/setup/"*.sh 2>/dev/null || true
  fi

  # Which integrations does this project use? Same marker set as
  # louie-update-framework step 1.
  tools=()
  [ -d "$proj/.claude" ]                                    && tools+=("claude")   || true
  { [ -f "$proj/.cursorrules" ] || [ -d "$proj/.cursor" ]; } && tools+=("cursor")   || true
  [ -d "$proj/.codex" ]                                     && tools+=("codex")    || true
  { [ -d "$proj/.gemini" ] || [ -f "$proj/GEMINI.md" ]; }    && tools+=("gemini")   || true
  [ -d "$proj/.opencode" ]                                  && tools+=("opencode") || true
  [ -d "$proj/.pi" ]                                        && tools+=("pi")       || true

  if [ ${#tools[@]} -eq 0 ]; then
    info "   framework files refreshed (no tool integration detected — no init run)"
    if [ "$AT_LATEST" -eq 1 ]; then current=$((current + 1)); else updated=$((updated + 1)); fi
    info ""
    continue
  fi

  # The init scripts skip the context-file section when the LOUIE marker is
  # already present, so framework updates to that block would never land. Do it
  # explicitly: generate a pristine block in a scratch dir, then splice it in.
  scratch="$TMP/scratch-$$"
  rm -rf "$scratch"; mkdir -p "$scratch"
  cp -R "$SRC/_LOUIE_" "$scratch/_LOUIE_"

  for tool in "${tools[@]}"; do
    script="$proj/_LOUIE_/setup/$tool-init.sh"
    [ -f "$script" ] || continue
    bash "$script" >/dev/null 2>&1 || { err "   init failed: $tool"; continue; }

    case "$tool" in
      claude)   ctx="CLAUDE.md" ;;
      gemini)   ctx="GEMINI.md" ;;
      codex|opencode|pi) ctx="AGENTS.md" ;;
      *)        ctx="" ;;   # cursor writes .cursorrules with no marker pair
    esac
    [ -n "$ctx" ] || continue

    # Generate the canonical block by running init against an empty scratch dir.
    ( cd "$scratch" && bash "$scratch/_LOUIE_/setup/$tool-init.sh" >/dev/null 2>&1 ) || true
    if [ -f "$scratch/$ctx" ]; then
      extract_block_from "$scratch/$ctx" > "$scratch/block.md"
      if [ -s "$scratch/block.md" ]; then
        set +e
        refresh_context_block "$proj/$ctx" "$scratch/block.md"
        rc=$?
        set -e
        case "$rc" in
          4) info "   note: $ctx predated the closing marker — regenerated (backup: $ctx.louie-bak)"
             NOTES+=("$name — $ctx had no closing marker; regenerated, backup at $ctx.louie-bak") ;;
        esac
      fi
    fi
    rm -f "$scratch/$ctx"
  done

  if [ "$AT_LATEST" -eq 1 ]; then
    info "   verified at $LATEST (${tools[*]})"
    current=$((current + 1))
  else
    info "   updated → $LATEST (${tools[*]})"
    updated=$((updated + 1))
  fi
  info ""
done

# -------------------------------------------------------------------- report

info "═══════════════════════════════════════"
if [ "$APPLY" -eq 0 ]; then
  info "DRY RUN — nothing was changed. Re-run without --dry-run to apply."
fi
info "  verified:  $current"
info "  updated:   $updated"
info "  skipped:   $skipped"

if [ ${#NOTES[@]} -gt 0 ]; then
  info ""
  info "Notes (already handled — no action needed):"
  for n in "${NOTES[@]}"; do info "  • $n"; done
fi

if [ ${#OPTIONAL[@]} -gt 0 ]; then
  info ""
  info "Optional (canonical artifacts these projects don't have yet):"
  for o in "${OPTIONAL[@]}"; do info "  • $o"; done
  info ""
  info "These are only created from a project's real content, so they're left"
  info "to the assistant — run 'louie-update-framework' there if you want them."
fi

if [ ${#ATTENTION[@]} -gt 0 ]; then
  info ""
  info "Needs the assistant (this script can't do these):"
  for a in "${ATTENTION[@]}"; do info "  • $a"; done
else
  info ""
  info "Nothing left to do — every project was updated in full."
fi
