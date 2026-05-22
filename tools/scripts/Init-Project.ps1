#Requires -Version 5.1
<#
.SYNOPSIS
    Personalize this template for your new project.

.DESCRIPTION
    Replaces template tokens (__PLOFF_*) with your project's actual values.
    Run once after cloning/creating from the template.

.EXAMPLE
    .\tools\scripts\Init-Project.ps1
#>

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

# ─── Prompt for values ───────────────────────────────────────────────────────

Write-Host ""
Write-Host "🚀 Project LiftOff — Project Initializer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$DisplayName = Read-Host "Project display name (e.g., My Awesome Project)"
if ([string]::IsNullOrWhiteSpace($DisplayName)) {
    Write-Host "Error: Display name cannot be empty." -ForegroundColor Red
    exit 1
}

# Generate default slug from display name
$DefaultSlug = ($DisplayName.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-').Trim('-')
$SlugInput = Read-Host "Project slug for repo/URLs/code [$DefaultSlug]"
$Slug = if ([string]::IsNullOrWhiteSpace($SlugInput)) { $DefaultSlug } else { $SlugInput }

$CurrentYear = (Get-Date).Year
$CopyrightInput = Read-Host "Copyright holder (e.g., Your Name or Company) []"
$CopyrightHolder = if ([string]::IsNullOrWhiteSpace($CopyrightInput)) { $DisplayName } else { $CopyrightInput }

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Display name:      $DisplayName" -ForegroundColor Green
Write-Host "  Slug:              $Slug" -ForegroundColor Green
Write-Host "  Copyright:         (c) $CurrentYear $CopyrightHolder" -ForegroundColor Green
Write-Host ""

$Confirm = Read-Host "Proceed? (y/N)"
if ($Confirm -notmatch '^[yY]$') {
    Write-Host "Aborted."
    exit 0
}

# ─── Replace tokens in git-tracked files ─────────────────────────────────────

Write-Host ""
Write-Host "Replacing template tokens..." -ForegroundColor Cyan

Push-Location $RepoRoot

$files = git ls-files
foreach ($file in $files) {
    if (-not (Test-Path $file)) { continue }

    $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }

    if ($content -match '__PLOFF_') {
        $newContent = $content `
            -replace '__PLOFF_DISPLAY_NAME__', $DisplayName `
            -replace '__PLOFF_SLUG__', $Slug `
            -replace '__PLOFF_YEAR__', $CurrentYear `
            -replace '__PLOFF_COPYRIGHT_HOLDER__', $CopyrightHolder

        Set-Content $file -Value $newContent -NoNewline
        Write-Host "  ✅ $file" -ForegroundColor Green
    }
}

# ─── Optional: Reset git history ─────────────────────────────────────────────

Write-Host ""
$ResetGit = Read-Host "Reset git history for a fresh start? (y/N)"
if ($ResetGit -match '^[yY]$') {
    Remove-Item -Recurse -Force .git
    git init
    git add -A
    git commit -m "feat: initial project setup from Project LiftOff template"
    Write-Host "Git history reset with initial commit." -ForegroundColor Green
}

Pop-Location

# ─── Done ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "🎉 Project '$DisplayName' initialized successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Review the changes: git diff"
Write-Host "  2. Set the remote: git remote add origin <your-repo-url>"
Write-Host "  3. Push: git push -u origin main"
Write-Host "  4. Run: make setup && make up"
