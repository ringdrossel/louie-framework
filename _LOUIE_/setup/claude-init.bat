@echo off
setlocal enabledelayedexpansion

echo LOUIE — Claude Code Setup
echo =========================
echo.

:: Resolve paths
set "SCRIPT_DIR=%~dp0"
set "LOUIE_DIR=%SCRIPT_DIR%..\.."
set "COMMANDS_SRC=%SCRIPT_DIR%..\commands"

:: Create .claude\commands\ directory
if not exist "%LOUIE_DIR%\.claude\commands" mkdir "%LOUIE_DIR%\.claude\commands"

:: Copy all louie-* command files
set count=0
for %%f in ("%COMMANDS_SRC%\louie-*.md") do (
    copy /Y "%%f" "%LOUIE_DIR%\.claude\commands\" > nul
    set /a count+=1
    echo   Installed /%%~nf
)

:: Create or update CLAUDE.md
set "CLAUDE_MD=%LOUIE_DIR%\CLAUDE.md"

if exist "%CLAUDE_MD%" (
    findstr /c:"LOUIE-FRAMEWORK" "%CLAUDE_MD%" > nul 2>&1
    if !errorlevel! equ 0 (
        echo.
        echo   CLAUDE.md already contains LOUIE section — skipped.
        goto :done
    )
)

:: Append LOUIE section to CLAUDE.md
(
echo.
echo ^<!-- LOUIE-FRAMEWORK --^>
echo ## LOUIE Framework
echo.
echo This project uses **LOUIE** ^(Lean Orchestration for Unified Intelligent Engineering^) for AI-assisted development.
echo.
echo ### Commands
echo.
echo LOUIE commands are available as slash commands ^(`/louie-*`^). Type `/louie-` to see all available commands.
echo.
echo ^| Command ^| Description ^|
echo ^|---------|-------------|
echo ^| `/louie-setup` ^| Initialize a new project ^|
echo ^| `/louie-feature` ^| Add a new feature ^(full agent chain^) ^|
echo ^| `/louie-extend` ^| Extend an existing feature ^|
echo ^| `/louie-update` ^| Quick change ^(^< 50 lines^) ^|
echo ^| `/louie-bugfix` ^| Diagnose and fix a bug ^|
echo ^| `/louie-review` ^| Code review by Max ^|
echo ^| `/louie-review-doc` ^| Review + fix + update docs ^|
echo ^| `/louie-test` ^| Write or improve tests with Ava ^|
echo ^| `/louie-doc` ^| Update documentation + commit message ^|
echo ^| `/louie-ideate` ^| Brainstorm ideas with Ivy ^|
echo ^| `/louie-recipe` ^| Browse or load a reusable recipe ^|
echo.
echo ### Critical Rules
echo.
echo 1. **Never implement directly** — create a feature document and get user confirmation first.
echo 2. **Never start feature work** without a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
echo 3. **Never merge to `main`** without explicit user approval after Max's review and Ava's tests pass.
echo.
echo ### Key Files
echo.
echo - `README.md` — framework overview ^(project root^)
echo - `_LOUIE_/workflow/ai-workflow.md` — full workflow
echo - `_LOUIE_/guidelines/coding-guidelines.md` — coding rules
echo - `_LOUIE_/agents/` — agent definitions
echo - `_LOUIE-output/architecture.md` — system design
echo - `_LOUIE-output/tech-stack.md` — build-time stack
echo - `_LOUIE-output/runbook.md` — runtime ops ^(deployment, ports, commands, gotchas^)
echo - `_LOUIE-output/` — full artifact tree
echo ^<!-- /LOUIE-FRAMEWORK --^>
) >> "%CLAUDE_MD%"

echo.
echo   Created/updated CLAUDE.md with LOUIE section.

:done
echo.
echo Done! %count% commands installed.
echo.
echo You can now use /louie-setup to start a new project,
echo or /louie-feature to add a feature.

endlocal
