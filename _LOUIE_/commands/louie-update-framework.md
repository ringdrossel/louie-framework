# louie-update-framework

When the user says **`louie-update-framework`**, follow this procedure to update the LOUIE framework to the latest version.

## Procedure

1. **Detect the current setup:**
   - Check which AI tool integration exists:
     - `.claude/commands/` → Claude Code
     - `.cursorrules` → Cursor
     - `AGENTS.md` with LOUIE section → Codex
   - Read the current `_LOUIE_/` directory to understand what's installed

2. **Pull the latest framework:**
   - If the project has a git remote for louie-framework, pull the latest `_LOUIE_/` and `_LOUIE-output/` structure
   - If not, ask the user: "Where should I pull the latest LOUIE from? (e.g., a GitHub repo URL or a local path)"
   - **Never overwrite `_LOUIE-output/`** — that's the user's work. Only update files that ship with the framework (overview.md skeleton is safe to skip if it already has content)

3. **Update the framework files:**
   - Replace `_LOUIE_/agents/` with the latest versions
   - Replace `_LOUIE_/commands/` with the latest versions
   - Replace `_LOUIE_/templates/` with the latest versions
   - Replace `_LOUIE_/guidelines/` with the latest versions
   - Replace `_LOUIE_/workflow/` with the latest versions
   - Replace `_LOUIE_/setup/` with the latest versions
   - Update `CLAUDE.md` at project root (replace the LOUIE-FRAMEWORK section, preserve any user-added sections)

4. **Re-run the appropriate init script:**
   - Claude Code → run `bash _LOUIE_/setup/claude-init.sh` (idempotent — skips CLAUDE.md if marker exists, overwrites command files)
   - Cursor → run `bash _LOUIE_/setup/cursor-init.sh`
   - Codex → run `bash _LOUIE_/setup/codex-init.sh`

5. **Show what changed:**
   - List new/updated/removed commands
   - List new/updated agents
   - List any template changes
   - Highlight breaking changes if any (e.g., renamed files, changed handoff format)

6. **Confirm success:**
   - "Framework updated to the latest version. Your `_LOUIE-output/` artifacts are untouched."

## Usage

```
louie-update-framework
```

or from a specific source:

```
louie-update-framework
Pull from https://github.com/ringdrossel/louie-framework
```
