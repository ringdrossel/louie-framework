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

The consequence shapes the design: the run always produces a **triage report** alongside the refresh, naming what still needs the assistant. `--dry-run` previews without changing anything; applying is the default, since the operation is near-fully reversible (`_LOUIE_/` is regenerable at any version via `install.sh --force --version <ref>`, and `_LOUIE-output/` is never touched).

**Only two conditions stop an update:** the directory isn't a LOUIE project, or it is the framework's own source repo. Everything else is refreshed.

That is a deliberate loosening of the original design, which blocked on pre-versioning installs, major version gaps, the flat layout, dirty trees, and non-git directories. Measured against a real 24-project fleet, those rules refused 15 of 24 — and the refusals were mostly wrong. The pre-versioning block in particular was circular: it deferred to `louie-update-framework`'s "filesystem-based migration detection," but the only thing that detection looks for is the flat layout, which this script already tests directly. Exactly one of the 15 actually had it.

The underlying reason the loose rule is safe: `_LOUIE_/` is wholly framework-owned and regenerable, and `_LOUIE-output/` is never touched. A refresh has almost nothing irreversible to destroy.

**Reported, not blocked** (each needs the assistant, none needs to stop the file refresh):

| Condition | Follow-up |
|---|---|
| Old flat `_LOUIE-output/` layout | `louie-migrate`. `louie-update-framework` itself supports declining the migration and carrying on, so blocking here would be stricter than the command it stands in for |
| Major version gap | Check for version-gated migrations |
| Missing `runbook.md` / `roadmap.md` | Newer canonical outputs; only the assistant can bootstrap them from existing artifacts |
| Uncommitted edits **inside `_LOUIE_/`** | The one genuinely irreversible loss — see below |
| Not a git repository | Same exposure, no undo available |

**Still hard blockers:**

| Condition | Why |
|---|---|
| The framework's own source repo | It is not an installation — see below |
| Version ahead of latest | A refresh would be a downgrade |

**Dirty-tree handling is scoped, not global.** The original rule skipped any project with uncommitted changes anywhere — which on a real fleet meant skipping projects whose *application code* was mid-edit, something a framework refresh cannot touch. The check now narrows to `git status -- _LOUIE_`, the only path the update overwrites. On the same fleet that took 7 blocked projects down to 3 warnings, and all 3 turned out to be uncommitted framework upgrades rather than customizations. It warns and proceeds; a hand-customized agent prompt is the case worth naming, and the user gets told.

**The context-block problem.** Init scripts skip the context-file section when the LOUIE marker is already present (that's what makes them idempotent), so framework changes to the `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` block would never reach an existing project. `louie-update-framework` step 3 handles this by reasoning; the script does it by splicing between `<!-- LOUIE-FRAMEWORK -->` and `<!-- /LOUIE-FRAMEWORK -->`, generating the canonical block by running init against a scratch directory. Everything outside the markers is preserved verbatim.

Projects whose context file predates the **closing** marker are regenerated rather than punted on. Early init scripts emitted only the opener, and they *append* their block — so it always ran to the end of the file as written. Everything from the opening marker to EOF is therefore framework content, and is replaced. A `.louie-bak` copy is written first and reported, since anything the user added after the block would fall inside that span.

The earlier design skipped these files as unsafe. Measured against a real fleet, the one project that hit the case had a context file that was *entirely* the LOUIE block — nothing to protect, and the guard just left it stale.

**The changelog is not in the tarball.** `.gitattributes` marks `_LOUIE-internals/ export-ignore`, which applies to `git archive` and therefore to GitHub's tarball endpoint. The script fetches `CHANGELOG.md` separately from `raw.githubusercontent.com` for its version-gap report. `louie-update-framework` is unaffected — it uses `git clone`, and `export-ignore` does not apply to clones. Anything that needs a `_LOUIE-internals/` file from an archive must fetch it separately.

Fetch happens **once** per run and is reused across all projects — never N downloads for N projects.

## Not covered by the lint

`check-consistency.sh` checks command-set registration; the installers list no commands, so they are outside its checks. What can drift instead:

- The tool list in the installers vs `_LOUIE_/setup/*-init.sh` — adding a seventh tool integration means editing both installers.
- The autodetect marker table vs `louie-update-framework.md` step 1.
- The raw URL in README/QUICKSTART vs the actual default branch.

Extending the lint to cover these is a candidate if it drifts once.
