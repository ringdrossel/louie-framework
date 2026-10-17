Godot 4.7 project skeleton: folder conventions, pixel-art defaults, gdUnit4 headless tests, Godot MCP server for Claude Code.

**Requires profile:** game

# Godot Project

## Overview

Sets up the foundation of a 2D Godot 4.7 game so the rest of the game profile can work: a folder layout that keeps pure game logic testable and separate from scenes, declared content paths for Mira and Kai, pixel-art display and import defaults, a gdUnit4 test suite that runs from the command line, export commands, and the Godot MCP server so the assistant can launch and inspect the project.

**Use it** at the start of a Godot project (typically as the first systems feature after `louie-setup`), or to bring an existing Godot project in line with these conventions.

**Don't use it** for non-Godot engines, or for 3D-first projects without adapting the display section (see Variations).

**Prerequisites:** project profile `game`; a confirmed `architecture.md` / `tech-stack.md` that name Godot as the engine.

## Verified Versions

Verified on 2026-10-17. Re-check before applying; update this table when it changes.

| Component | Version | Source |
|-----------|---------|--------|
| Godot Engine | 4.7.2 stable (latest 4.7 maintenance release) | `version.py` at tag `4.7.2-stable`: https://github.com/godotengine/godot/blob/4.7.2-stable/version.py — release notes: https://godotengine.org/article/maintenance-release-godot-4-7-2/ |
| gdUnit4 | 6.2.x for Godot 4.7 | Compatibility table: https://github.com/godot-gdunit-labs/gdUnit4 (README) — v6.2.x lists "v4.7, v4.7.1"; master (v7.0.0) lists "v4.7, v4.7.1, v4.8.dev7". 4.7.2 is not yet listed in either row; Godot's 4.7.2 notes report no known incompatibilities with 4.7.1. Confirm the row for your exact Godot version before pinning. |
| Godot MCP (Coding-Solo) | `@coding-solo/godot-mcp` via `npx` | https://github.com/Coding-Solo/godot-mcp (README § Quick Start, § Requirements) |

## Requirements Seed

**Functional**

- The project opens in Godot 4.7.x and runs its main scene from the editor and from the command line.
- Pure game rules live in scripts that don't depend on the scene tree and can be unit-tested headless.
- The test suite runs from the command line with one documented command and exits non-zero on failure.
- Release builds can be exported from the command line for every target in `tech-stack.md`.
- Pixel art renders crisp at every supported window size (no blurry filtering, no uneven pixel scaling).
- The assistant can launch the project and read its debug output through the Godot MCP server.

**Non-functional**

- Folder and file names follow Godot's `snake_case` convention.
- Content paths for dialogue and data are declared in `architecture.md` § Content Pipeline.

**Out of scope**

- Gameplay systems themselves (each is its own feature with Kai's `mechanics.md`).
- Dialogue integration (`game:dialogue-manager`) and asset generation (`game:spritecook-pipeline`).

## Architecture Notes

For Sophie to validate and record in `architecture.md` / `tech-stack.md` / `runbook.md`.

**Folder layout (proposal — adapt, then record in `architecture.md`):**

```
project.godot
addons/               third-party plugins (Godot convention: keep them in a top-level addons/)
src/core/             pure game rules — no Node/scene-tree dependencies; unit-tested headless
src/systems/          services that wire rules to the engine (turn manager, save service, game state)
scenes/               .tscn files with their presentation scripts, grouped by feature
data/                 data-driven resources (classes, items, units, stat tables) — Kai's content path
dialogue/             dialogue files — Mira's content path (see game:dialogue-manager)
assets/               imported art, audio, fonts (see game:spritecook-pipeline)
test/                 gdUnit4 test suites, mirroring src/
docs/                 non-game files; add an empty .gdignore so Godot doesn't import them
```

- Godot's project-organization guide recommends `snake_case` for folder and file names (except C# scripts), keeping third-party resources in a top-level `addons/` folder, and an empty `.gdignore` file to stop Godot from importing a folder's contents (resources in an ignored folder can't be loaded). Source: https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html
- **Content Pipeline rows** to add to `architecture.md`: `data/**` (owner Kai, format per the stat-table decision, validator: the data tests in `test/`), `dialogue/**` (owner Mira, see `game:dialogue-manager`).
- **Global services:** keep autoloads few (game state, save service, scene loader); each one is an architecture decision.

**Pixel-art display defaults (Project Settings):**

| Setting | Value | Source |
|---------|-------|--------|
| Base window size (`display/window/size/viewport_width` × `viewport_height`) | the viewport size you design for; 640×360 is a good baseline — it scales to 1280×720, 1920×1080, 2560×1440, and 3840×2160 without black bars under integer scaling | Multiple resolutions, § Pixel art: https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html |
| Stretch mode | `viewport` | same |
| Stretch aspect | `keep` (single aspect ratio, black bars) or `expand` (multiple aspect ratios; then anchor Controls via the Layout menu) | same |
| Stretch scale mode (`display/window/stretch/scale_mode`) | `integer` — prevents uneven pixel scaling; content is clipped if the window is smaller than the base size, so set a minimum window size | same, and `ProjectSettings` class reference at `4.7.2-stable` |
| Default canvas texture filter (`rendering/textures/canvas_textures/default_texture_filter`) | Nearest | `ProjectSettings` class reference at `4.7.2-stable`: https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/ProjectSettings.xml |
| Snap 2D transforms to pixel (`rendering/2d/snap/snap_2d_transforms_to_pixel`) | optional, for low-resolution pixel art; don't combine with vertex snapping | same |

**Import defaults:** for 2D, Godot's default image import uses **Lossless** compression, which the docs also recommend for pixel art; avoid VRAM compression for pixel-art textures. Source: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html

**Tech-stack entries** (game section, see the profile's tech-stack template): engine Godot 4.7.x, GDScript, gdUnit4 6.2.x, Godot MCP (dev-time), export targets.

## Implementation Guidance

**Installing addons** (gdUnit4 here, Dialogue Manager later): download the addon, move its `addons/` folder into the project (merging with an existing `addons/`), then enable it under **Project > Project Settings > Plugins**. Source: https://docs.godotengine.org/en/4.7/tutorials/plugins/editor/installing_plugins.html — gdUnit4's own install guide: https://godot-gdunit-labs.github.io/gdUnit4/latest/first_steps/install/

**Command line** (Godot 4.7 command-line reference: https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html):

- Run the project: `godot --path .`
- Re-import resources and quit (useful in CI before tests): `godot --headless --path . --import`
- Parse a script for errors only: `godot --headless --path . --check-only --script <script>`
- Export a release build: `godot --headless --path . --export-release "<preset name>" <output path>` — the preset name must match `export_presets.cfg`; export templates must be installed; `--export-debug` uses the debug template. `--headless` is required on machines without GPU access.

**Tests (gdUnit4 6.2.x):**

- Runner script shipped with the addon: `addons/gdUnit4/runtest.sh` (Windows: `addons/gdUnit4/runtest.cmd`). Run it from the project root — it calls Godot with `--path .`. It needs the Godot binary via `GODOT_BIN` or `--godot_binary <path>`.
- Typical call: `GODOT_BIN=/path/to/godot addons/gdUnit4/runtest.sh -a res://test`
- Runner options (from `GdUnitTestCIRunner.gd` at tag `v6.2.0`): `-a <directory|suite>` add tests, `-i <suite|suite:test>` ignore, `-c` continue on failure, `-conf <file>` load a test configuration, `-rd <directory>` report directory, `-rc <count>` reports to keep, `--ignoreHeadlessMode` (by default, gdUnit4 refuses to run in headless mode; this switch disables that check).
- For CI without a display, run the same command once with `--ignoreHeadlessMode` on your machine and record the exact working command in `runbook.md` § Common Commands. The official GitHub Action `gdunit4-action` is the documented CI path (README).
- Sources: https://github.com/godot-gdunit-labs/gdUnit4/blob/v6.2.0/addons/gdUnit4/runtest.sh and https://github.com/godot-gdunit-labs/gdUnit4/blob/v6.2.0/addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd

**Godot MCP server for Claude Code** (https://github.com/Coding-Solo/godot-mcp):

- Requirements: Godot installed, Node.js >= 18 and npm.
- Add it: `claude mcp add godot -- npx @coding-solo/godot-mcp` — then restart Claude Code.
- If Godot isn't found automatically: `claude mcp add godot -e GODOT_PATH=/path/to/godot -- npx @coding-solo/godot-mcp` (`DEBUG=true` enables server-side debug logging).
- What it gives the assistant: launch the editor, run the project in debug mode, capture console output and errors, stop the project, read the Godot version, analyze project structure, create scenes and add nodes, manage UIDs (Godot 4.4+).
- Record it in `tech-stack.md` § MCP Servers and `runbook.md` § Environment & Dependencies (`GODOT_PATH`). The server is developer tooling; the game never depends on it.

**Runbook rows for Sophie:** run (`godot --path .`), open editor, import, test (the gdUnit4 command above), export per preset; Debugging: "tests hang headless" → check the headless switch and that the test run quits; "scene fails to load" → re-import, check UID references.

## Test Guidance

- A smoke test suite exists under `test/` and passes from the command line; a deliberately failing test makes the command exit non-zero.
- A pure-logic class in `src/core/` is tested without instancing any scene.
- Export succeeds for each preset in `export_presets.cfg` (manual check or CI).
- Playtest checklist: the window scales cleanly at 1×, 2×, 3× of the base size; pixels stay square and crisp; resizing below the base size behaves as designed.

## Variations

- **3D or high-resolution 2D:** use the non-pixel-art settings from the multiple-resolutions guide (`canvas_items` stretch mode, `expand` aspect) instead of the pixel-art table.
- **C# / .NET:** gdUnit4's `runtest.sh` detects a .NET build and runs `dotnet build` first; C# setup has its own gdUnit4 guide (README).
- **Editor-bridge MCP:** for live editor control (scene editing, screenshots, input simulation) instead of CLI-driven control, PiMPStudios/Claude-GoDot-MCP (https://github.com/PiMPStudios/Claude-GoDot-MCP) runs a Godot editor plugin plus a Python server. Younger and less widely used than Coding-Solo/godot-mcp at the time of writing — evaluate before adopting.
