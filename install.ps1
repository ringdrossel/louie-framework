<#
.SYNOPSIS
  LOUIE one-liner installer for Windows.

.DESCRIPTION
  irm https://raw.githubusercontent.com/ringdrossel/louie-framework/main/install.ps1 | iex

  Note: `iex` on a piped string cannot take arguments, so that form is
  autodetect-only. To pass parameters, download first:

    irm https://raw.githubusercontent.com/ringdrossel/louie-framework/main/install.ps1 -OutFile install.ps1
    .\install.ps1 -Tool claude -Dir C:\projects\app

  Design notes: _LOUIE-internals/install.md
  Must stay behaviorally aligned with install.sh (manual review item — the
  consistency lint does not cover the installers).
#>

[CmdletBinding()]
param(
  [string[]]$Tool,
  [string]$Dir = $PWD.Path,
  [string]$Version = $(if ($env:LOUIE_VERSION) { $env:LOUIE_VERSION } else { 'main' }),
  [switch]$Force,
  [switch]$NoInit
)

$ErrorActionPreference = 'Stop'

$RepoUrl    = 'https://github.com/ringdrossel/louie-framework'
$KnownTools = @('claude', 'cursor', 'codex', 'gemini', 'opencode', 'pi')

if ($Tool -contains 'all') { $Tool = $KnownTools }
foreach ($t in $Tool) {
  if ($KnownTools -notcontains $t) {
    Write-Error "Unknown tool: $t (known: $($KnownTools -join ', '), all)"
    exit 2
  }
}

# The installer never creates the project directory — a typo should not
# silently produce a stray tree somewhere.
if (-not (Test-Path -LiteralPath $Dir -PathType Container)) {
  Write-Error "Target directory does not exist: $Dir"
  exit 1
}
$Target = (Resolve-Path -LiteralPath $Dir).Path

Write-Host "LOUIE - Install"
Write-Host "==============="
Write-Host ""
Write-Host "  Source: $RepoUrl @ $Version"
Write-Host "  Target: $Target"
Write-Host ""

# ------------------------------------------------------------------- guards

$louieDir   = Join-Path $Target '_LOUIE_'
$versionFile = Join-Path $louieDir 'VERSION'

if ((Test-Path -LiteralPath $louieDir) -and (-not $Force)) {
  if (Test-Path -LiteralPath $versionFile) {
    $installed = (Get-Content -LiteralPath $versionFile -First 1).Trim()
    Write-Host "Error: LOUIE $installed is already installed at $Target." -ForegroundColor Red
  } else {
    Write-Host "Error: A _LOUIE_\ directory already exists at $Target (pre-versioning install)." -ForegroundColor Red
  }
  Write-Host ""
  Write-Host "To upgrade, run 'louie-update-framework' in your AI assistant - it does"
  Write-Host "version-gated migrations and shows a changelog delta, which a plain file"
  Write-Host "overwrite skips. Use -Force here only to reinstall from scratch."
  exit 1
}

# -------------------------------------------------------------------- fetch

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("louie-" + [System.Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

try {
  Write-Host "Downloading..."
  $tarball = Join-Path $tmp 'louie.tar.gz'
  try {
    Invoke-WebRequest -Uri "$RepoUrl/archive/$Version.tar.gz" -OutFile $tarball -UseBasicParsing
  } catch {
    Write-Host "Error: Download failed for ref '$Version'." -ForegroundColor Red
    Write-Host "Check the ref name and your network connection: $RepoUrl"
    exit 1
  }

  # tar ships in-box on Windows 10 1803+ / Server 2019+.
  if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
    Write-Error "tar is required but not available (Windows 10 1803+ ships it in-box)."
    exit 1
  }
  tar -xzf $tarball -C $tmp
  if ($LASTEXITCODE -ne 0) { Write-Error "Failed to extract the archive."; exit 1 }

  $src = Get-ChildItem -Path $tmp -Directory | Select-Object -First 1
  if (-not $src -or -not (Test-Path -LiteralPath (Join-Path $src.FullName '_LOUIE_'))) {
    Write-Error "Unexpected archive layout - no _LOUIE_\ found."
    exit 1
  }

  $srcLouie   = Join-Path $src.FullName '_LOUIE_'
  $srcOutput  = Join-Path $src.FullName '_LOUIE-output'
  $srcVersion = Join-Path $srcLouie 'VERSION'
  $frameworkVersion = if (Test-Path -LiteralPath $srcVersion) {
    (Get-Content -LiteralPath $srcVersion -First 1).Trim()
  } else { 'unknown' }

  # --------------------------------------------------------------------- copy
  # Allowlist, never denylist: anything new at the repo root stays out of user
  # projects unless it is opted in here deliberately (see install.md).

  Write-Host "Installing framework files..."
  if (Test-Path -LiteralPath $louieDir) { Remove-Item -LiteralPath $louieDir -Recurse -Force }
  Copy-Item -LiteralPath $srcLouie -Destination $louieDir -Recurse
  Write-Host "  _LOUIE_\            framework $frameworkVersion"

  # _LOUIE-output\ holds the user's work - seed missing skeleton files only,
  # never overwrite. Same rule louie-update-framework follows.
  $seeded = 0
  $skipped = 0
  if (Test-Path -LiteralPath $srcOutput) {
    $prefix = (Resolve-Path -LiteralPath $srcOutput).Path
    foreach ($file in Get-ChildItem -LiteralPath $srcOutput -Recurse -File) {
      $rel  = $file.FullName.Substring($prefix.Length).TrimStart('\', '/')
      $dest = Join-Path (Join-Path $Target '_LOUIE-output') $rel
      if (Test-Path -LiteralPath $dest) {
        $skipped++
      } else {
        New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $dest
        $seeded++
      }
    }
  }

  if ($skipped -gt 0) {
    Write-Host "  _LOUIE-output\      $seeded file(s) seeded, $skipped existing file(s) kept"
  } else {
    Write-Host "  _LOUIE-output\      $seeded file(s) seeded"
  }

  # --------------------------------------------------------------------- init

  if ($NoInit) {
    Write-Host ""
    Write-Host "Skipped tool init (-NoInit). Run _LOUIE_\setup\<tool>-init.bat when ready."
    exit 0
  }

  if (-not $Tool -or $Tool.Count -eq 0) {
    # Autodetect. All matches are used - a project may carry several
    # integrations. Marker set mirrors louie-update-framework step 1.
    $detected = @()
    if (Test-Path -LiteralPath (Join-Path $Target '.claude'))      { $detected += 'claude' }
    if ((Test-Path -LiteralPath (Join-Path $Target '.cursorrules')) -or
        (Test-Path -LiteralPath (Join-Path $Target '.cursor')))    { $detected += 'cursor' }
    if (Test-Path -LiteralPath (Join-Path $Target '.codex'))       { $detected += 'codex' }
    if ((Test-Path -LiteralPath (Join-Path $Target '.gemini')) -or
        (Test-Path -LiteralPath (Join-Path $Target 'GEMINI.md')))  { $detected += 'gemini' }
    if (Test-Path -LiteralPath (Join-Path $Target '.opencode'))    { $detected += 'opencode' }
    if (Test-Path -LiteralPath (Join-Path $Target '.pi'))          { $detected += 'pi' }

    if ($detected.Count -eq 0) {
      $Tool = @('claude')
      Write-Host ""
      Write-Host "No AI tool detected - setting up for Claude Code."
      Write-Host "For another tool, run: _LOUIE_\setup\<tool>-init.bat"
    } else {
      $Tool = $detected
      Write-Host ""
      Write-Host "Detected: $($Tool -join ', ')"
    }
  }

  foreach ($t in $Tool) {
    $script = Join-Path (Join-Path $louieDir 'setup') "$t-init.bat"
    if (-not (Test-Path -LiteralPath $script)) {
      Write-Error "Init script missing: _LOUIE_\setup\$t-init.bat"
      exit 1
    }
    Write-Host ""
    # The init scripts resolve their target from their own location and print
    # their own next-step guidance (including detecting an existing project and
    # suggesting louie-import) - don't duplicate that here.
    & cmd.exe /c "`"$script`""
  }

  Write-Host ""
  Write-Host "LOUIE $frameworkVersion installed."
}
finally {
  Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
