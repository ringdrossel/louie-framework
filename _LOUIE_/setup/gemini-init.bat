@echo off
setlocal enabledelayedexpansion

echo LOUIE — Gemini CLI Setup
echo =========================
echo.

set "SCRIPT_DIR=%~dp0"
set "LOUIE_DIR=%SCRIPT_DIR%..\.."
set "GEMINI_MD=%LOUIE_DIR%\GEMINI.md"

:: Check if LOUIE section already exists
if exist "%GEMINI_MD%" (
    findstr /c:"LOUIE-FRAMEWORK" "%GEMINI_MD%" > nul 2>&1
    if !errorlevel! equ 0 (
        echo   GEMINI.md already contains LOUIE section — skipped.
        goto :done
    )
)

:: Append LOUIE section to GEMINI.md
(
echo.
echo ^<!-- LOUIE-FRAMEWORK --^>
echo ## LOUIE Framework
echo.
echo This project uses **LOUIE** ^(Lean Orchestration for Unified Intelligent Engineering^) for AI-assisted development.
echo.
echo ### Command Routing
echo.
echo When the user types a `louie-*` command, read the matching file from `_LOUIE_/commands/` and follow the instructions in it.
echo.
echo Available commands:
echo - `louie-setup` → `_LOUIE_/commands/louie-setup.md`
echo - `louie-import` → `_LOUIE_/commands/louie-import.md`
echo - `louie-migrate` → `_LOUIE_/commands/louie-migrate.md`
echo - `louie-feature` → `_LOUIE_/commands/louie-feature.md`
echo - `louie-extend` → `_LOUIE_/commands/louie-extend.md`
echo - `louie-update` → `_LOUIE_/commands/louie-update.md`
echo - `louie-bugfix` → `_LOUIE_/commands/louie-bugfix.md`
echo - `louie-continue` → `_LOUIE_/commands/louie-continue.md`
echo - `louie-review` → `_LOUIE_/commands/louie-review.md`
echo - `louie-review-doc` → `_LOUIE_/commands/louie-review-doc.md`
echo - `louie-evaluate` → `_LOUIE_/commands/louie-evaluate.md`
echo - `louie-review-mode` → `_LOUIE_/commands/louie-review-mode.md`
echo - `louie-branch-mode` → `_LOUIE_/commands/louie-branch-mode.md`
echo - `louie-autopilot-mode` → `_LOUIE_/commands/louie-autopilot-mode.md`
echo - `louie-language` → `_LOUIE_/commands/louie-language.md`
echo - `louie-test` → `_LOUIE_/commands/louie-test.md`
echo - `louie-doc` → `_LOUIE_/commands/louie-doc.md`
echo - `louie-ideate` → `_LOUIE_/commands/louie-ideate.md`
echo - `louie-roadmap` → `_LOUIE_/commands/louie-roadmap.md`
echo - `louie-roadmap-change` → `_LOUIE_/commands/louie-roadmap-change.md`
echo - `louie-recipe` → `_LOUIE_/commands/louie-recipe.md`
echo - `louie-from-source` → `_LOUIE_/commands/louie-from-source.md`
echo.
echo ### Critical Rules
echo.
echo 1. **Never implement directly** — create a feature document and get user confirmation first.
echo 2. **Never start feature work** without a confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md`.
echo 3. **Never merge to `main`** without explicit user approval after Max's review and Ava's tests pass.
echo 4. **Never write implementation learnings to `_LOUIE-output/runbook.md`.** Operational reference only ^(ports, env vars, services, commands, first-check debugging^). Framework quirks / cache rules / "I learned X" go in code-local `// WHY` comments + per-feature `bugfixes/^<slug^>.md` ^Detect / Avoid^. There is no `## Common Gotchas` section. Applies on every edit path, including ad-hoc "update the specs" requests.
echo.
echo ### Key Files
echo.
echo - `README.md` — framework overview ^(project root^)
echo - `_LOUIE_/workflow/ai-workflow.md` — full workflow
echo - `_LOUIE_/guidelines/coding-guidelines.md` — coding rules

echo - `_LOUIE_/guidelines/interaction-guidelines.md` — how to ask the user to chooseecho - `_LOUIE_/agents/` — agent definitions
echo - `_LOUIE-output/architecture.md` — system design
echo - `_LOUIE-output/tech-stack.md` — build-time stack
echo - `_LOUIE-output/runbook.md` — runtime ops ^(deployment, ports, commands, env, first-check debugging^)
echo - `_LOUIE-output/roadmap.md` — bigger changes / epics list ^(created at setup^)
echo - `_LOUIE-output/implementations/^<feature^>/` — per-feature folder ^(feature.md, requirements.md, decisions.md, bugfixes/^)
echo - `_LOUIE-output/bugfixes/overview.md` — cross-project bug-fix index
echo ^<!-- /LOUIE-FRAMEWORK --^>
) >> "%GEMINI_MD%"

echo   Created/updated GEMINI.md with LOUIE section.

:done
echo.
echo Done!
echo.

:: Source adapters (louie-from-source) - keep private adapters out of version control
findstr /b /c:"louie-adapters/" "%LOUIE_DIR%\.gitignore" >nul 2>&1
if errorlevel 1 (
    echo.>> "%LOUIE_DIR%\.gitignore"
    echo # Private LOUIE source adapters - credentials, never commit>> "%LOUIE_DIR%\.gitignore"
    echo louie-adapters/>> "%LOUIE_DIR%\.gitignore"
    echo   Added louie-adapters/ to .gitignore
)

:: Report source-adapter availability - project-local louie-adapters\ overrides %USERPROFILE%\.louie\adapters
set "ADAPTER_SCOPE="
set "ADAPTER_LIST="
if exist "%LOUIE_DIR%\louie-adapters\" (
    for /d %%a in ("%LOUIE_DIR%\louie-adapters\*") do (
        if exist "%%a\adapter.md" (
            set "ADAPTER_SCOPE=project"
            set "ADAPTER_LIST=!ADAPTER_LIST!%%~nxa "
        )
    )
)
if not defined ADAPTER_SCOPE if exist "%USERPROFILE%\.louie\adapters\" (
    for /d %%a in ("%USERPROFILE%\.louie\adapters\*") do (
        if exist "%%a\adapter.md" (
            set "ADAPTER_SCOPE=global"
            set "ADAPTER_LIST=!ADAPTER_LIST!%%~nxa "
        )
    )
)
if defined ADAPTER_SCOPE (
    echo   Source adapters ^(!ADAPTER_SCOPE!^): !ADAPTER_LIST!
) else (
    echo   No source adapters found - louie-from-source will be unavailable.
    echo   Install one to %%USERPROFILE%%\.louie\adapters\^<name^>\adapter.md to enable it for all projects.
)
echo.

:: Detect existing project — recommend louie-import if so
set "EXISTING_PROJECT=0"
set "HAS_V1_DOCS=0"
if exist "%LOUIE_DIR%\docs\implementations\overview.md" (
    for %%f in ("%LOUIE_DIR%\docs\implementations\*.md") do (
        if /I not "%%~nxf"=="overview.md" (
            set "EXISTING_PROJECT=1"
            set "HAS_V1_DOCS=1"
        )
    )
)
if !EXISTING_PROJECT! equ 0 (
    for %%m in (package.json pyproject.toml Cargo.toml go.mod pom.xml build.gradle composer.json Gemfile mix.exs setup.py requirements.txt) do (
        if exist "%LOUIE_DIR%\%%m" set "EXISTING_PROJECT=1"
    )
)
if !EXISTING_PROJECT! equ 0 (
    for %%d in (src app lib) do (
        if exist "%LOUIE_DIR%\%%d\" set "EXISTING_PROJECT=1"
    )
)

if !EXISTING_PROJECT! equ 1 (
    if !HAS_V1_DOCS! equ 1 (
        echo Detected v1 LOUIE docs at docs\implementations\.
        echo Run 'louie-import' in Gemini CLI next to translate them into LOUIE format.
    ) else (
        echo Detected existing project source.
        echo Run 'louie-import' in Gemini CLI next to have LOUIE generate architecture,
        echo tech-stack, runbook, and feature docs from the existing code.
    )
) else (
    echo You can now type 'louie-setup' in Gemini CLI to start a new project,
    echo or 'louie-feature' to add a feature.
)

endlocal
