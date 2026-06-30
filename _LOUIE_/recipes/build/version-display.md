Derive the app version from the latest git tag at build time, bake it into a generated constant, and display it where the app's UI lives — web header/footer, native window title, or CLI banner + `--version` — chosen by interview.

# Version Display by Git Tag

## Overview

The developer marks a release by tagging the repo (e.g. `git tag 07.23.1`). That tag — whatever string it is — becomes the version the application shows its users. This recipe captures the tag **at build time**, bakes it into a generated constant the app imports, and surfaces it on the right display surface for the kind of app being built.

The display surface is **not** assumed — it is decided by interview, because it depends entirely on the app:

- **Web application** → in the page **header** or **footer** (or both).
- **Native windowed application** → appended to the **window title** (`MyApp — 07.23.1`).
- **CLI / terminal application** → printed in the **startup banner** line, plus a conventional **`--version` / `-v`** flag.

In every case the app also logs its version once at startup. A single project may select more than one surface (e.g. a web app that shows the footer version *and* logs it on the server at boot).

### Use this when

- The project tags releases in git and wants that exact tag shown to users/operators.
- The app should display its version without depending on git (or `.git`) being present at runtime — i.e. it ships as a built artifact (container, bundle, binary, packaged CLI).
- You want one consistent mechanism across web, native, and CLI targets in the same or sibling projects.

### Do not use this for

- Apps that must read a **live** version from a running git checkout (e.g. a dev tool run from source that should reflect `git describe` on every invocation) — that's a runtime-git variation, not the build-time bake this recipe defaults to.
- Rich build provenance / SBOM needs (full commit graph, dependency versions, reproducible-build attestation) — that's a heavier concern than a display string.
- Per-environment banners ("STAGING", "PROD") — that's environment config, orthogonal to the version. Compose the two if you want both.

## Requirements Seed

### Functional

1. At build time, a generator resolves the **version string** and writes it into a **generated artifact** the app imports (a constant/module/file — form depends on stack).
2. Version resolution order:
   1. The **nearest git tag** reachable from `HEAD` (`git describe --tags --abbrev=0`), displayed **verbatim** — no normalization, no stripping of a leading `v`, no format validation. `07.23.1`, `v2.0`, and `2026-rc1` are all valid and shown as-is.
   2. If there is no tag (or no `.git` — e.g. building from a source tarball), fall back to the **project manifest version** (`package.json` `version`, `pyproject.toml`, `Cargo.toml`, `.csproj`, etc. — whatever the stack uses).
   3. If the manifest has no version either, bake the literal string **`unknown`**.
   The build **always succeeds** — a missing tag is never a build error.
3. "Off-tag" behavior is **tag-only**: when `HEAD` is between tags or the tree is dirty, still show the nearest tag verbatim. Commits-since-tag, the short SHA, and dirty state are **not** appended.
4. The resolved version is displayed on the surface(s) chosen by interview:
   - **Web:** rendered in the header and/or footer.
   - **Native windowed:** appended to the window title as `<AppName> — <version>`.
   - **CLI:** printed in the startup banner line, and returned by a `--version` / `-v` flag that prints the version and exits 0.
5. The app **logs its version once at startup** (one line, info level), regardless of the visual surface.
6. A project may select **multiple** surfaces; the startup log line coexists with any visual surface.

### Non-Functional

- **No runtime git dependency.** The running app must never shell out to git or require `.git`. All git access happens in the build-time generator.
- **No runtime cost.** Reading the version is a constant/module access, not I/O.
- **Deterministic from the build.** The displayed version is whatever was baked at build time; it does not change while the process runs.
- **Stack-agnostic generator.** The resolution logic (tag → manifest → `unknown`) is identical across stacks; only the artifact format and the manifest path differ.

### Out of Scope

- Runtime/live `git describe` (see *Variations*).
- Long describe form (`07.23.1-3-gabc123`), dirty markers, commit SHA, build timestamp, branch (see *Variations*).
- A `/version` or health API endpoint (see *Variations*).
- Interactive build-metadata reveal (hover/click to show commit/date).
- Tag format enforcement / semver parsing / prefix normalization.
- Version *bumping* or tag *creation* — this recipe reads tags, it does not write them.

## Architecture Notes

### The generated artifact

A single generated file holding the version string, imported by the app. Examples by stack (Sophie adapts to the project's conventions):

| Stack | Generated artifact | App reads |
|-------|--------------------|-----------|
| JS/TS | `src/generated/version.ts` exporting `export const VERSION = "07.23.1"` | `import { VERSION }` |
| Python | `mypkg/_version.py` with `__version__ = "07.23.1"` | `from mypkg._version import __version__` |
| Go | linker flag `-ldflags "-X main.version=07.23.1"` (no file) | package var |
| .NET | generated `Version.cs` or an MSBuild property | constant |

**The artifact is gitignored and regenerated on every build.** It must never be committed — it carries no information not derivable from the tag, and committing it adds version-bump noise to diffs and risks going stale. Add the generated path to `.gitignore` as part of the recipe.

> ⚠️ Because the artifact is gitignored, a build **must run the generator before the app is compiled/bundled**. Wire it as a `prebuild` step / build hook, not a manual command. If the app can be built without the generator having run, the import will be missing — fail loudly with a clear message rather than shipping a blank version.

### Resolution logic (the generator)

```
version = run("git describe --tags --abbrev=0")   # nearest tag, verbatim
if version is empty or git failed:
    version = read manifest version (package.json / pyproject / Cargo / csproj / …)
if version is still empty:
    version = "unknown"
write generated artifact with `version`
```

`--abbrev=0` yields the bare nearest tag (tag-only behavior). Do **not** use plain `git describe` (it appends `-<n>-g<sha>`). Run git with the repo root as cwd; tolerate a non-zero exit (no tags / no repo) and fall through to the manifest.

### Integration points

- **Build pipeline:** the generator hooks into the project's existing build (npm `prebuild`/Vite plugin, `setup.py`/hatch hook, Makefile target, Go `-ldflags`, MSBuild target). Sophie maps it to the project's build tool.
- **Display surface:** plugs into existing UI/shell — an existing header/footer component (web), the window-title setter (native), or the CLI's arg parser + startup path. The recipe does **not** introduce a UI framework.
- **Logging:** uses the project's existing logger for the startup line.
- **`.gitignore`:** the generated artifact path is added.

### Things Sophie should validate

- The project ships as a **built artifact** without `.git` at runtime — confirm the build-time bake is the right model (vs. the runtime-git variation).
- The build tool has a **pre-compile hook** where the generator can run before the app reads the constant.
- The project's **manifest** location and version field (for the fallback) — and whether a manifest even exists (Go modules / single binaries may not have a version field; then fallback goes straight to `unknown`).
- Whether builds run **without git available** (CI from a tarball, vendored source) — the fallback chain must hold there.
- For native: how the app **sets its window title** (framework-specific).
- For CLI: whether an **arg parser** already exists to host `--version`, or one must be added.

## Implementation Guidance

### The generator (for Nina)

Write one small generator script/module — the single source of truth for the resolution order. Keep the three-step fallback (tag → manifest → `unknown`) centralized so web, native, and CLI all bake the identical value.

- Invoke git as `git describe --tags --abbrev=0`, cwd = repo root, capture stdout, trim whitespace.
- Treat any non-zero exit (no tags, no repo) as "no tag" and continue to the manifest — **do not** throw.
- Read the manifest with the stack's native parser; pluck the version field; empty/missing → continue.
- Final fallback is the literal `unknown`.
- Write the artifact atomically; create the `generated/` dir if absent.
- Make it idempotent and safe to run on every build.

### Wiring the build

- Register the generator as a **pre-build / pre-compile** step so the artifact exists before the app imports it.
- Add the generated path to `.gitignore`.
- For Go-style projects, prefer `-ldflags -X` over a committed file; the "artifact" is the injected symbol.

### Display — per surface

**Web (header and/or footer):**
- Import the `VERSION` constant; render it as text in the chosen component(s). Display verbatim.
- Don't add a label unless the project's design calls for one; if it does, the surface owns the label (e.g. footer `v{VERSION}` or `Version {VERSION}`) — the constant stays the bare tag.
- If the web app has a server, also emit the startup log line on boot.

**Native (window title):**
- Set the window title to `<AppName> — <VERSION>` when the main window is created.
- Optionally add a `--version` flag and the startup log line if the app is also launched from a terminal.

**CLI (banner + flag):**
- Print `<program> <VERSION>` in the startup banner line on normal launch.
- Add `--version` / `-v` to the arg parser: print `<VERSION>` (or `<program> <VERSION>`) to stdout and exit 0 **before** any other work — no side effects, no config loading.

**Startup log (all targets):**
- One info-level line at boot, e.g. `starting <app> <VERSION>`. Use the project's logger.

### Pitfalls

- **Don't run git at runtime.** Every read of the version after build must hit the baked constant, never a subprocess.
- **Don't commit the generated artifact.** Gitignore it; regenerate every build.
- **Don't use bare `git describe`.** Use `--abbrev=0` or you'll append `-<n>-g<sha>` and break tag-only display.
- **Don't normalize the tag.** Ship it verbatim — stripping a `v` or coercing to semver is explicitly out of scope.
- **Don't fail the build on a missing tag.** Fall back to manifest, then `unknown`.
- **Don't let `--version` do side effects.** It must print and exit before config/IO, so it works even in a broken environment.
- **Don't read the version before the generator runs.** Order the build so the artifact exists first; if it can't, fail with a clear message, not a blank string.

## Test Guidance

### Generator (unit)

- Tag present → returns the tag **verbatim**, including a `v` prefix when the tag has one.
- `git describe` exits non-zero (no tags) → falls back to the manifest version.
- No tag **and** no `.git` directory → falls back to the manifest version.
- No tag and no manifest version → returns `unknown`.
- Bare `git describe` is *not* used: with commits after the tag, the result is still the bare tag (no `-N-gSHA`).
- Whitespace/newline from git output is trimmed.
- Generator never throws on a missing repo or missing manifest.

### Display (per built surface)

- **Web:** the chosen component(s) render the baked version string; a `v`-prefixed tag renders with the `v`.
- **Native:** the window title equals `<AppName> — <VERSION>`.
- **CLI:** `--version` and `-v` both print the version and exit 0 with no other output/side effects; the startup banner includes the version on normal launch.
- **Startup log:** exactly one version line is logged at boot.

### Regression

- A build with **no tags** still produces a running app showing the manifest version (or `unknown`), not a crash or blank.
- The generated artifact is absent from git status (gitignored) after a build.
- Building from a `.git`-less source tree (simulated tarball) succeeds and shows the fallback.

## Variations

### Runtime live version (dev tools)

For a tool meant to be run from a checkout and reflect the working tree, skip the bake and call `git describe` at runtime instead. Trade-off: requires git + `.git` present where it runs. Keep the same fallback chain for when it isn't.

### Long describe / build metadata

Append commits-since-tag, short SHA, and a `-dirty` marker (`git describe --tags --dirty`), and/or bake a build timestamp, commit SHA, and branch into the artifact. Useful for staging diagnostics. Surface them in an About dialog (native), a `--version --verbose` mode (CLI), or a tooltip (web).

### Version API / health endpoint

For web services, also expose the baked version at `GET /version` or inside `/health`, so monitoring reads it without scraping the UI. Reads the same constant — no extra git access.

### `v`-prefix normalization

If a project wants `v07.23.1` and `07.23.1` to render identically, add a normalization step in the generator (strip a single leading `v`) or a display setting. Off by default — this recipe ships the tag verbatim.

### Tag format validation

For projects that want to guarantee a scheme, validate the tag against a configurable regex in the generator and warn (or fail) on a mismatch. Off by default — this recipe accepts any tag string.

### About dialog (native)

In addition to (or instead of) the window title, show the version in a Help → About dialog, alongside build metadata if the long-describe variation is enabled.
