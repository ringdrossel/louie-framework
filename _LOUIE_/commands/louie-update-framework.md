# louie-update-framework

When the user says **`louie-update-framework`**, follow this procedure to update the LOUIE framework to the latest version.

## Procedure

1. **Detect the current setup:**
   - Check which AI tool integration exists (any combination is possible — multiple may co-exist on one project):
     - `.claude/commands/` → Claude Code
     - `.opencode/command/` → opencode
     - `.codex/skills/` → Codex CLI
     - `.pi/prompts/` → Pi Coding Agent
     - `.gemini/` or `GEMINI.md` → Gemini CLI
     - `.cursorrules` → Cursor
     - `AGENTS.md` with LOUIE section → Codex / opencode / Pi (shared context file)
   - Read the current `_LOUIE_/` directory to understand what's installed

2. **Pull the latest framework:**
   - **Default source:** `https://github.com/ringdrossel/louie-framework` (branch `main`). Use this unless the user explicitly specified a different source alongside the command.
   - Clone shallow into a temp directory: `git clone --depth 1 https://github.com/ringdrossel/louie-framework /tmp/louie-framework-update`
   - If the clone fails (network, auth, rate limit), report the error and ask the user for an alternative source — do **not** silently fall back to a stale local copy.
   - If the project itself has a git remote pointing at the framework, you can pull there instead (faster, no temp dir). Otherwise the temp clone is canonical.
   - **Never overwrite `_LOUIE-output/`** — that's the user's work. Only update files that ship with the framework (overview.md skeleton is safe to skip if it already has content).
   - After step 4, delete the temp clone (`rm -rf /tmp/louie-framework-update`).

3. **Update the framework files:**
   - Replace `_LOUIE_/agents/` with the latest versions
   - Replace `_LOUIE_/commands/` with the latest versions
   - Replace `_LOUIE_/templates/` with the latest versions
   - Replace `_LOUIE_/guidelines/` with the latest versions
   - Replace `_LOUIE_/workflow/` with the latest versions
   - Replace `_LOUIE_/setup/` with the latest versions
   - Replace `_LOUIE_/recipes/` with the latest versions (recipe library)
   - Update `CLAUDE.md` at project root (replace the LOUIE-FRAMEWORK section, preserve any user-added sections)

4. **Re-run the appropriate init script(s)** — each is idempotent (skips the context-file section if the LOUIE marker is present; always overwrites the installed slash-command / skill / prompt-template files so they pick up framework updates). Run every script whose integration the project uses (multiple may apply):
   - Claude Code → `bash _LOUIE_/setup/claude-init.sh` — refreshes `.claude/commands/louie-*.md`
   - opencode → `bash _LOUIE_/setup/opencode-init.sh` — refreshes `.opencode/command/louie-*.md`
   - Codex CLI → `bash _LOUIE_/setup/codex-init.sh` — refreshes `.codex/skills/louie-*/SKILL.md`
   - Pi Coding Agent → `bash _LOUIE_/setup/pi-init.sh` — refreshes `.pi/prompts/louie-*.md`
   - Gemini CLI → `bash _LOUIE_/setup/gemini-init.sh` (text-routing via `GEMINI.md` only — Gemini's slash-command convention is `.gemini/commands/*.toml`; LOUIE doesn't auto-generate those yet)
   - Cursor → `bash _LOUIE_/setup/cursor-init.sh` (text-routing via `.cursorrules` only — Cursor doesn't expose a markdown drop-in slash-command path)

5. **Show what changed:**
   - List new/updated/removed commands
   - List new/updated agents
   - List any template changes
   - List new/updated recipes (sections and individual recipes)
   - **Check `_LOUIE-output/` for any new canonical outputs introduced by this framework update.** If a new output is now expected (e.g. `runbook.md`) and the project doesn't have it, tell the user and offer to bootstrap it from existing artifacts (architecture, ad-hoc context files). Never silently create files in `_LOUIE-output/`.
   - Highlight breaking changes if any (e.g., renamed files, changed handoff format)

6. **Detect old artifact layout and offer migration:**
   - Inspect `_LOUIE-output/` for the old flat layout signal:
     - At least one `*.md` file directly in `_LOUIE-output/implementations/` other than `overview.md`, OR
     - The directory `_LOUIE-output/requirements/` exists
   - If the old layout is detected, tell the user:
     > "Your `_LOUIE-output/` is on the old flat layout. The framework now uses per-feature folders (`implementations/<feature>/feature.md` + `requirements.md` + `decisions.md` + `bugfixes/`) and a top-level `bugfixes/overview.md` index. I can run `louie-migrate` for you now to restructure your artifacts (one-way; uses `git mv` so history is preserved)."
   - On user confirmation, follow `_LOUIE_/commands/louie-migrate.md` directly. Do not re-prompt for the same confirmations `louie-migrate` would ask.
   - On decline, leave the project on the old layout and warn that newly-shipped commands assume the new layout — features run via `louie-feature` etc. will produce per-feature folders alongside the old flat files until migration runs.

7. **Confirm success:**
   - "Framework updated to the latest version. Your `_LOUIE-output/` artifacts are [untouched / migrated to the new layout]."

## Usage

```
louie-update-framework
```

or from a specific source:

```
louie-update-framework
Pull from https://github.com/ringdrossel/louie-framework
```
