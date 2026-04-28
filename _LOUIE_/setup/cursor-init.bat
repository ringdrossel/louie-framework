@echo off
setlocal enabledelayedexpansion

echo LOUIE — Cursor Setup
echo =====================
echo.

set "SCRIPT_DIR=%~dp0"
set "LOUIE_DIR=%SCRIPT_DIR%..\.."
set "CURSORRULES=%LOUIE_DIR%\.cursorrules"

:: Check if LOUIE section already exists
if exist "%CURSORRULES%" (
    findstr /c:"LOUIE-FRAMEWORK" "%CURSORRULES%" > nul 2>&1
    if !errorlevel! equ 0 (
        echo   .cursorrules already contains LOUIE section — skipped.
        goto :done
    )
)

:: Append LOUIE section to .cursorrules
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
echo - `louie-feature` → `_LOUIE_/commands/louie-feature.md`
echo - `louie-extend` → `_LOUIE_/commands/louie-extend.md`
echo - `louie-update` → `_LOUIE_/commands/louie-update.md`
echo - `louie-bugfix` → `_LOUIE_/commands/louie-bugfix.md`
echo - `louie-review` → `_LOUIE_/commands/louie-review.md`
echo - `louie-review-doc` → `_LOUIE_/commands/louie-review-doc.md`
echo - `louie-test` → `_LOUIE_/commands/louie-test.md`
echo - `louie-doc` → `_LOUIE_/commands/louie-doc.md`
echo - `louie-ideate` → `_LOUIE_/commands/louie-ideate.md`
echo - `louie-recipe` → `_LOUIE_/commands/louie-recipe.md`
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
) >> "%CURSORRULES%"

echo   Created/updated .cursorrules with LOUIE section.

:done
echo.
echo Done!
echo.
echo You can now type 'louie-setup' in Cursor to start a new project,
echo or 'louie-feature' to add a feature.

endlocal
