@echo off
setlocal enabledelayedexpansion

echo LOUIE — Codex CLI Setup
echo ========================
echo.

set "SCRIPT_DIR=%~dp0"
set "LOUIE_DIR=%SCRIPT_DIR%..\.."
set "COMMANDS_SRC=%SCRIPT_DIR%..\commands"
set "AGENTS_MD=%LOUIE_DIR%\AGENTS.md"

:: Install Codex skills at .codex/skills/<name>/SKILL.md, one per louie-* command.
:: Frontmatter is worded to bias toward explicit invocation only.
if not exist "%LOUIE_DIR%\.codex\skills" mkdir "%LOUIE_DIR%\.codex\skills"

set "count=0"
for %%f in ("%COMMANDS_SRC%\louie-*.md") do (
    set "name=%%~nf"
    set "skill_dir=%LOUIE_DIR%\.codex\skills\!name!"
    if not exist "!skill_dir!" mkdir "!skill_dir!"
    (
        echo ---
        echo name: !name!
        echo description: Procedure for the LOUIE command "!name!". Activate ONLY when the user explicitly types "/!name!" or "!name!" as a command — never invoke implicitly based on inferred intent.
        echo ---
        echo.
        type "%%f"
    ) > "!skill_dir!\SKILL.md"
    set /a count+=1
    echo   Installed /!name!
)

if exist "%AGENTS_MD%" (
    findstr /c:"LOUIE-FRAMEWORK" "%AGENTS_MD%" > nul 2>&1
    if !errorlevel! equ 0 (
        echo.
        echo   AGENTS.md already contains LOUIE section — skipped.
        goto :done
    )
)

(
echo.
echo ^<!-- LOUIE-FRAMEWORK --^>
echo ## LOUIE Framework
echo.
echo This project uses **LOUIE** ^(Lean Orchestration for Unified Intelligent Engineering^) for AI-assisted development.
echo.
echo ### Commands
echo.
echo LOUIE commands are installed as Codex CLI skills under `.codex/skills/^<name^>/SKILL.md`. Invoke them explicitly as `/louie-setup`, `/louie-feature`, etc. Typing the bare name also works.
echo.
echo ^| Command ^| Description ^|
echo ^|---------^|-------------^|
echo ^| `/louie-setup` ^| Initialize a new project ^|
echo ^| `/louie-import` ^| Import an existing project ^(cold or v1 docs^) into LOUIE ^|
echo ^| `/louie-migrate` ^| Migrate an old-layout LOUIE project to per-feature folders ^|
echo ^| `/louie-feature` ^| Add a new feature ^(full agent chain^) ^|
echo ^| `/louie-extend` ^| Extend an existing feature ^|
echo ^| `/louie-update` ^| Quick change ^(^< 50 lines^) ^|
echo ^| `/louie-bugfix` ^| Diagnose and fix a bug ^|
echo ^| `/louie-review` ^| Code review by Max ^|
echo ^| `/louie-review-doc` ^| Review + fix + update docs ^|
echo ^| `/louie-review-mode` ^| View or change the project review mode ^|
echo ^| `/louie-test` ^| Write or improve tests with Ava ^|
echo ^| `/louie-doc` ^| Update documentation + commit message ^|
echo ^| `/louie-ideate` ^| Brainstorm ideas with Ivy ^|
echo ^| `/louie-roadmap` ^| Capture pre-feature ideas in `_LOUIE-output/roadmap.md` ^|
echo ^| `/louie-recipe` ^| Browse or load a reusable recipe ^|
echo.
echo Skill files are kept in sync with `_LOUIE_/commands/` by running the codex-init script ^(also re-run by `louie-update-framework`^). Frontmatter is worded so Codex does **not** auto-activate them.
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
echo - `_LOUIE_/agents/` — agent definitions
echo - `_LOUIE-output/architecture.md` — system design
echo - `_LOUIE-output/tech-stack.md` — build-time stack
echo - `_LOUIE-output/runbook.md` — runtime ops ^(deployment, ports, commands, env, first-check debugging^)
echo - `_LOUIE-output/roadmap.md` — pre-feature idea list ^(lazy-created on first `/louie-roadmap add`^)
echo - `_LOUIE-output/implementations/^<feature^>/` — per-feature folder ^(feature.md, requirements.md, decisions.md, bugfixes/^)
echo - `_LOUIE-output/bugfixes/overview.md` — cross-project bug-fix index
echo ^<!-- /LOUIE-FRAMEWORK --^>
) >> "%AGENTS_MD%"

echo.
echo   Created/updated AGENTS.md with LOUIE section.

:done
echo.
echo Done! !count! commands installed.
echo.

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
        echo Run /louie-import in Codex next to translate them into LOUIE format.
    ) else (
        echo Detected existing project source.
        echo Run /louie-import in Codex next to have LOUIE generate architecture,
        echo tech-stack, runbook, and feature docs from the existing code.
    )
) else (
    echo You can now use /louie-setup in Codex to start a new project,
    echo or /louie-feature to add a feature.
)

endlocal
