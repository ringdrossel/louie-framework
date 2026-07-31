# One-Liner Install

**Audience:** framework maintainers. Design notes for `install.sh` / `install.ps1` at the repo root.

## Problem

Before this, installing LOUIE was two manual steps with an implicit third:

1. Copy `_LOUIE_/` and `_LOUIE-output/` into the project root (README says "copy both" — no mechanism given).
2. Run `bash _LOUIE_/setup/<tool>-init.sh`.
3. Know which of the six tool init scripts applies to you.

Step 1 has no happy path. A user without the repo has to clone it, then hand-copy two directories out of it and delete the rest — `_LOUIE-internals/`, `ressources/`, the framework's own `README.md`/`CLAUDE.md`, and a `.git/` pointing at someone else's remote. Nothing enforces that; the likely outcome is a project with framework-internal files in it.

## Decision: `curl | bash` bootstrapper

```bash
curl -fsSL https://raw.githubusercontent.com/ringdrossel/louie-framework/main/install.sh | bash -s -- claude
```

Alternatives considered:

- **npm package (`npx louie-framework init`).** Gives versioning and a registry for free. Rejected: LOUIE is markdown plus bash with no runtime, and this would impose a Node dependency on projects that may have none (a Rust or Python project has no reason to own a `node_modules`). It also adds a publish step to every release — one more thing to drift out of sync with `_LOUIE_/VERSION`, which is exactly the failure this repo already had.
- **`git clone` one-liner.** Leaves `.git/` and the whole `_LOUIE-internals/` tree in the user's project. The user then has to know what to delete — the same problem, relocated.
- **Copy-paste as today.** The status quo. Keep it documented as the offline/air-gapped fallback, demoted below the one-liner.

Curl-to-bash matches what the framework already is: a shell-script install of a text tree, with no build step. `louie-update-framework` already assumes `curl`/`git` reachability against this same repo, so the dependency is not new.

## Contract

```
install.sh [tool ...] [--force] [--dir <path>] [--version <ref>] [--no-init]
```

- **`tool`** — one or more of `claude`, `cursor`, `codex`, `gemini`, `opencode`, `pi`, or `all`. Omitted → autodetect (below). Multiple tools are legal and normal: a project may carry Claude Code and Cursor at once, and the init scripts are independently idempotent.
- **`--dir`** — install target, default `$PWD`. Must exist; the installer never creates the project directory (that would turn a typo into a stray tree).
- **`--version`** — git ref to fetch. Default `main`. Also settable as `LOUIE_VERSION` for pipe-friendliness.
- **`--force`** — permit overwriting an existing `_LOUIE_/`. See Guards.
- **`--no-init`** — copy files, skip init scripts. For scripted/CI installs that run init separately.

### Why `main` and not the newest tag

The default ref is `main`, with `--version` / `LOUIE_VERSION` as opt-in pinning.

A hardcoded default tag has to be edited at every release, and a release cut without that edit leaves the installer silently serving stale content forever. That is not hypothetical here: `_LOUIE_/VERSION` sat at `1.0.0` through the `v1.0.1`–`v1.0.3` tags, and the `stable` tag pointed three months behind `main`. An installer pinned to either would have been wrong. `main` is also what `louie-update-framework` clones, so the two paths agree on what "latest" means.

Resolving the newest tag dynamically (GitHub API) was rejected: it adds an unauthenticated API call subject to rate limiting on a path whose whole value is that it always works.

Revisit if release discipline holds for several cycles and `main` starts carrying genuinely unstable work.

## Mechanics

**Fetch.** `curl -fsSL https://github.com/ringdrossel/louie-framework/archive/<ref>.tar.gz | tar -xz` into `mktemp -d`, trapped for cleanup on exit. No `git` dependency — `curl` and `tar` are the only requirements, both present on any macOS/Linux box and on Windows 10+ (`tar` ships in-box; PowerShell handles the rest).

**Copy — allowlist, never denylist.** Only `_LOUIE_/` and `_LOUIE-output/` are copied. An allowlist is load-bearing: a denylist silently starts shipping every new top-level file added to this repo (`_LOUIE-internals/` was added after the original install docs were written, and the docs never caught up). Anything new at the repo root is excluded by default and must be opted in here deliberately.

**`_LOUIE-output/` is seeded per-file, never wholesale.** Each skeleton file is copied only if absent at the target. The directory holds user work; an existing `implementations/overview.md` with real features in it must survive a re-run. This is the same rule `louie-update-framework` follows ("Never overwrite `_LOUIE-output/`").

**Init.** Delegates to `_LOUIE_/setup/<tool>-init.sh` in the target. The init scripts already handle their own idempotency (LOUIE-marker check on the context file, unconditional refresh of installed command files) and already print the right next step — they detect existing project source and suggest `/louie-import` over `/louie-setup`. The installer must not duplicate that logic; it prints its own summary and lets init have the last word.

## Guards

- **Existing install.** If `_LOUIE_/VERSION` exists at the target, stop with `LOUIE <version> is already installed — use louie-update-framework` and exit non-zero. `--force` overrides. Rationale: `louie-update-framework` does version-gated migrations and changelog deltas that a blind file overwrite skips; silently clobbering a project mid-version is how a downstream artifact layout gets stranded.
- **`_LOUIE_/` present without `VERSION`.** A pre-versioning install. Same stop, different message, pointing at `louie-update-framework` for the same reason.
- **Non-empty `_LOUIE-output/`.** Not an error — per-file seeding handles it. Report what was skipped so the result isn't silently partial.

## The `/dev/tty` constraint

Under `curl ... | bash`, **stdin is the script**. A `read` in the script consumes its own source text, so an interactive prompt both fails to prompt and corrupts execution — a classic and thoroughly non-obvious curl-pipe bug.

**Rule: the installer is fully non-interactive.** Every choice is a flag or an autodetect. There is no prompt to route.

If a prompt is ever genuinely needed, it must read from `/dev/tty` explicitly and degrade to a documented default when no tty exists (CI). Prefer adding a flag.

## Tool autodetection

Runs only when no tool argument is given. Markers, in order; all matches are used, not just the first:

| Marker at target | Tool |
|---|---|
| `.claude/` | `claude` |
| `.cursorrules` or `.cursor/` | `cursor` |
| `.codex/` | `codex` |
| `.gemini/` or `GEMINI.md` | `gemini` |
| `.opencode/` | `opencode` |
| `.pi/` | `pi` |

Same marker set `louie-update-framework` step 1 uses — keep them in sync.

No markers → default to `claude` and say so. It is the primary target, it is the only integration installing native subagents, and a wrong guess costs one extra init run rather than a broken install. `AGENTS.md` is deliberately **not** a marker: three tools share it (codex, opencode, pi), so it cannot disambiguate.

## Windows

`install.ps1` mirrors `install.sh`, invoked as:

```powershell
irm https://raw.githubusercontent.com/ringdrossel/louie-framework/main/install.ps1 | iex
```

`iex` on a piped string takes no arguments, so the PowerShell path is autodetect-only; parameters require downloading the script first (documented in the README). Same guards, same allowlist, same per-file `_LOUIE-output/` seeding; dispatches to `*-init.bat`.

The sh/bat parity rule from `tools/README.md` applies here by extension: `install.sh` and `install.ps1` must stay behaviorally aligned. The consistency lint does not cover them (they register no commands), so this is a manual review item at each release.

## Bulk update (`update-all.sh`)

Scans directory trees for LOUIE projects and refreshes them. For maintainers of many LOUIE projects, where opening each one in an assistant to run `louie-update-framework` is the bottleneck.

**Scope is deliberately partial.** The script does the mechanical part: replace `_LOUIE_/`, refresh the context-file block, re-run init scripts. It does *not* do the judgment parts — version-gated migrations, the flat→per-feature layout migration, bootstrapping newly-canonical `_LOUIE-output/` files. Those need per-project reasoning over the user's actual artifacts.

The consequence shapes the design: **the triage report is the primary output, the update is secondary.** A project the script refuses to touch is a successful result, not a failure — it has been correctly identified as needing `louie-update-framework`. Dry-run is the default.

**Blockers** (reported, never auto-updated):

| Condition | Why |
|---|---|
| Major version gap | Migrations live exactly here (`core.md` § Versioning) |
| Pre-versioning install (no `VERSION`) | No gating basis; needs the command's filesystem-based detection |
| Old flat `_LOUIE-output/` layout | Needs `louie-migrate` and its `git mv` history preservation |
| Uncommitted changes | Git is the undo; without a clean tree there isn't one (`--allow-dirty` overrides) |
| Not a git repository | Same — no way back from a bad update |
| The framework's own source repo | It is not an installation — see below |
| Version ahead of latest | A refresh would be a downgrade |

**The framework must never update itself.** A maintainer's checkout of this repo has a `_LOUIE_/` directory and therefore looks exactly like an installed project to a filesystem scan. It isn't one: refreshing it would `rm -rf` the source tree and replace it with the last *published* copy, silently reverting unreleased work. Detection uses `_LOUIE-internals/` plus a root `install.sh` — `_LOUIE-internals/` is repo-only and never distributed, so it cannot appear in a real installation.

This failure mode stays latent while the repo's `VERSION` matches the published one (it reads as "already current"). It arms itself precisely during a release cut, when `VERSION` is bumped locally before the tag is pushed — the moment the source tree is most valuable and least recoverable.

**Version comparison must be ordered, not equality.** Bare `$local = $latest` treats "ahead" and "behind" identically, so any project ahead of the published release gets silently downgraded. `version_gt` compares semver components; anything ahead is reported and left alone.

**The context-block problem.** Init scripts skip the context-file section when the LOUIE marker is already present (that's what makes them idempotent), so framework changes to the `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` block would never reach an existing project. `louie-update-framework` step 3 handles this by reasoning; the script does it by splicing between `<!-- LOUIE-FRAMEWORK -->` and `<!-- /LOUIE-FRAMEWORK -->`, generating the canonical block by running init against a scratch directory. Everything outside the markers is preserved verbatim.

Projects whose context file predates the **closing** marker are reported and left alone: with only an opening marker there is no way to tell where the framework section ends and the user's content begins, and guessing would eat their notes.

**The changelog is not in the tarball.** `.gitattributes` marks `_LOUIE-internals/ export-ignore`, which applies to `git archive` and therefore to GitHub's tarball endpoint. The script fetches `CHANGELOG.md` separately from `raw.githubusercontent.com` for its version-gap report. `louie-update-framework` is unaffected — it uses `git clone`, and `export-ignore` does not apply to clones. Anything that needs a `_LOUIE-internals/` file from an archive must fetch it separately.

Fetch happens **once** per run and is reused across all projects — never N downloads for N projects.

## Not covered by the lint

`check-consistency.sh` checks command-set registration; the installers list no commands, so they are outside its checks. What can drift instead:

- The tool list in the installers vs `_LOUIE_/setup/*-init.sh` — adding a seventh tool integration means editing both installers.
- The autodetect marker table vs `louie-update-framework.md` step 1.
- The raw URL in README/QUICKSTART vs the actual default branch.

Extending the lint to cover these is a candidate if it drifts once.
