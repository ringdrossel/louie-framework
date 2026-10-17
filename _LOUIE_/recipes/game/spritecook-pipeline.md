SpriteCook asset pipeline: MCP and agent-skill setup, asset folder conventions, style consistency, Godot import of generated sprites.

**Requires profile:** game

# SpriteCook Pipeline

## Overview

Sets up a repeatable pipeline for AI-generated pixel art with **SpriteCook**, used by the developer through MCP: where generated files land, how they get a consistent style, how they are imported into Godot so they stay crisp, and how every asset's origin is recorded.

**What this recipe does not do:** LOUIE's agents don't generate assets. The developer asks the assistant to use the SpriteCook MCP tools when they want art; this recipe only sets up the folders, conventions, import settings, and documentation around that.

**Use it** in a Godot pixel-art project that will use SpriteCook for sprites, sprite sheets, tilesets, or icons.

**Prerequisites:** project profile `game`; `game:godot-project` (or equivalent) with the pixel-art display and import defaults; a SpriteCook account.

## Verified Setup

Verified on 2026-10-17 against https://github.com/SpriteCook/spritecook-mcp (README). Re-check before applying.

- **Quick setup:** `npx spritecook-mcp setup` — detects installed AI clients, authenticates with an API key where required, configures the MCP connections, and installs an optional agent skill.
- **The optional agent skill** (per the README) covers asynchronous job polling, model discovery, guided character workflows, saved presets, multi-image style guide references, local-file uploads, background cleanup, asset organization and recovery, and Godot-ready character exports.
- **Manual configuration:** the hosted MCP endpoint is `https://api.spritecook.ai/mcp/` with an `Authorization: Bearer <API key>` header (the README shows Cursor and VS Code examples). For Claude Code, prefer `npx spritecook-mcp setup`; for a manual entry, follow Claude Code's MCP documentation for a remote HTTP server with that endpoint and header.
- **API keys:** created at https://app.spritecook.ai (README § Links). API reference: https://spritecook.ai/docs
- **Never commit the API key.** Keep it in the user-level MCP configuration or an environment variable; if a project-level MCP file is committed, it must not contain the key. `runbook.md` names *where* the key lives, never the key.

## Requirements Seed

**Functional**

- Generated assets enter the project through one documented path and naming convention.
- Every generated asset has a provenance entry (tool, date, prompt or preset, reference assets used).
- Sprites keep one consistent style: shared palette, sprite size, frame size, and reference assets, recorded once.
- Imported sprites render crisp (nearest filtering, lossless compression) and animated sprite sheets play in Godot.
- The developer can regenerate or edit an asset without breaking scenes that use it.

**Out of scope**

- Automatic generation by LOUIE agents.
- Audio, 3D models.

## Architecture Notes

For Sophie to validate and record in `architecture.md` § Asset pipeline and `tech-stack.md` § Asset Tools / § MCP Servers.

**Folder conventions (proposal):**

```
assets/
  sprites/<category>/<name>.png      imported, used by scenes (characters, enemies, tiles, ui, icons)
  sprites/<category>/<name>.tres     SpriteFrames / other resources built from them
  _incoming/                         raw downloads waiting for review; contains an empty .gdignore
  PROVENANCE.md                      one row per accepted asset
```

- `snake_case` names, per Godot's project-organization guide. An empty `.gdignore` in `_incoming/` keeps unreviewed files out of Godot's import (resources in an ignored folder can't be loaded). Source: https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html
- An asset moves from `_incoming/` to `sprites/` only after review; replacing a file in place keeps scene references working.

**Style consistency — record once in `tech-stack.md` § Asset Tools:**

- the SpriteCook preset name(s) and the reference assets used as the style guide (the README lists saved presets and multi-image style guide references as skill features),
- palette, base sprite size (e.g. 16×16 or 32×32 tiles), character frame size, outline and shading rules,
- one "hero" reference per category that new assets are compared against.

**Godot import (pixel art):**

- Project default canvas texture filter **Nearest** and integer scaling come from `game:godot-project`.
- Image import: keep **Lossless** compression — Godot's default for 2D and recommended for pixel art; avoid VRAM compression for pixel-art textures. Source: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html
- Animation: sprite sheets and individual frames are animated with `AnimatedSprite2D` and its `SpriteFrames` resource (or with `AnimationPlayer`). Source: https://docs.godotengine.org/en/4.7/tutorials/2d/2d_sprite_animation.html
- Godot-ready character exports from the SpriteCook skill: check what the export contains (scene, `SpriteFrames`, frame layout) on the first use and record the import steps in `runbook.md` § Common Commands.

## Implementation Guidance

1. Run `npx spritecook-mcp setup` on the developer machine; choose Claude Code; install the optional agent skill. Restart the AI client.
2. Create the folder structure above, including `assets/_incoming/.gdignore` and `assets/PROVENANCE.md`:

   | Asset | File | Date | Tool | Preset / prompt | References | Notes |
   |-------|------|------|------|-----------------|------------|-------|

3. Generate the first reference asset per category and record the style rules in `tech-stack.md`.
4. For each new asset: generate into `_incoming/`, review against the reference, move to `sprites/<category>/`, add a `PROVENANCE.md` row, let Godot import it, and build the `SpriteFrames` resource if it's animated.
5. Add to `runbook.md` § Environment & Dependencies: SpriteCook MCP configured via `npx spritecook-mcp setup`; key stored in the user-level MCP configuration.

## Test Guidance

- A content test lists every PNG under `assets/sprites/` and checks it has a `PROVENANCE.md` row (and vice versa).
- An import-settings check: no file under `assets/sprites/` uses VRAM compression.
- Playtest checklist: new sprites match the reference style side by side; animations play at the intended frame rate; no blurry or uneven pixels at 1×–3× scale.

## Variations

- **Tilesets:** build a `TileSet` resource from the tileset sheet and record the tile size with the style rules.
- **Hand-drawn art alongside generated art:** use the same folders and `PROVENANCE.md` with tool `manual`.
- **Other engines:** the folder, provenance, and style rules carry over; replace the Godot import section.
