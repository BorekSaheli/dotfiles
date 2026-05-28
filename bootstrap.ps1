#!/usr/bin/env pwsh
<#
.SYNOPSIS
    One-command bootstrap for a fresh Windows machine.

.DESCRIPTION
    Run on a brand-new Windows install with:

        irm https://raw.githubusercontent.com/BorekSaheli/dotfiles/main/bootstrap.ps1 | iex

    It performs the ~30-second prelude (ensure winget is present and recent,
    enable DSC configuration support), then hands off to `winget configure`
    which installs every package, and finally runs chezmoi to lay down the
    dotfiles.

    Flow:
      1. Ensure winget (App Installer) is present and >= the version that
         supports `winget configure`.
      2. Enable the DSC `configuration` experimental feature.
      3. winget configure  -> installs Git, PowerShell, Neovim, WezTerm,
         Starship, lazygit, komorebi, whkd, fastfetch, chezmoi (fully silent).
      4. Refresh PATH, then `chezmoi init --apply` to drop the dotfiles.
#>

[CmdletBinding()]
param(
    # GitHub repo to pull dotfiles from (chezmoi shorthand: user/repo).
    [string]$DotfilesRepo = 'BorekSaheli/dotfiles',

    # Branch the bootstrap + DSC files live on.
    [string]$Branch = 'main',

    # Minimum App Installer (winget) version that supports `winget configure`.
    [version]$MinWingetVersion = '1.6.0'
)

$ErrorActionPreference = 'Stop'

function Write-Step  { param([string]$Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Info  { param([string]$Message) Write-Host "    $Message" -ForegroundColor DarkGray }
function Write-Ok    { param([string]$Message) Write-Host "    $Message" -ForegroundColor Green }
function Write-Warn  { param([string]$Message) Write-Host "    $Message" -ForegroundColor Yellow }

$rawBase = "https://raw.githubusercontent.com/$DotfilesRepo/$Branch"
$dscUrl  = "$rawBase/winget-configure.dsc.yaml"

# ---------------------------------------------------------------------------
# Refresh the current session's PATH from the machine + user environment so
# tools installed during this run (chezmoi, git, ...) become callable without
# opening a new shell.
# ---------------------------------------------------------------------------
function Update-SessionPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = ($machinePath, $userPath | Where-Object { $_ }) -join ';'
}

# ---------------------------------------------------------------------------
# 1. Ensure winget is present and recent enough for `winget configure`.
# ---------------------------------------------------------------------------
function Get-WingetVersion {
    $cmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $cmd) { return $null }
    try {
        # `winget --version` prints e.g. "v1.7.10661"
        $raw = (& winget --version) 2>$null
        if ($raw -match '(\d+\.\d+(\.\d+)?)') { return [version]$Matches[1] }
    } catch { }
    return $null
}

function Install-Winget {
    Write-Step 'Installing App Installer (winget)...'

    # On Windows 11 / recent Windows 10, the fastest path is the built-in
    # App Installer from the Store. Fall back to a direct package install.
    try {
        Write-Info 'Attempting install via Microsoft.WinGet.Client module...'
        if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
            Install-Module -Name Microsoft.WinGet.Client -Force -Scope CurrentUser -Repository PSGallery
        }
        Import-Module Microsoft.WinGet.Client
        Repair-WinGetPackageManager -ErrorAction Stop
        Write-Ok 'winget repaired/installed via Microsoft.WinGet.Client.'
        return
    } catch {
        Write-Warn "Module path failed: $($_.Exception.Message)"
    }

    # Direct download fallback (App Installer msixbundle).
    Write-Info 'Falling back to direct App Installer download...'
    $tmp = Join-Path $env:TEMP 'AppInstaller.msixbundle'
    $url = 'https://aka.ms/getwinget'
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
    Add-AppxPackage -Path $tmp
    Remove-Item $tmp -ErrorAction SilentlyContinue
    Write-Ok 'App Installer installed.'
}

Write-Step 'Checking for winget...'
$version = Get-WingetVersion
if (-not $version) {
    Write-Warn 'winget not found.'
    Install-Winget
    Update-SessionPath
    $version = Get-WingetVersion
    if (-not $version) {
        throw 'winget is still unavailable after install. Open a new terminal and re-run, or install "App Installer" from the Microsoft Store manually.'
    }
}

if ($version -lt $MinWingetVersion) {
    Write-Warn "winget $version is older than required $MinWingetVersion; upgrading..."
    Install-Winget
    Update-SessionPath
    $version = Get-WingetVersion
}
Write-Ok "winget $version ready."

# ---------------------------------------------------------------------------
# 2. Enable the DSC `configuration` experimental feature so `winget configure`
#    is available. Newer winget builds have it on by default; enabling it is
#    idempotent and harmless.
# ---------------------------------------------------------------------------
Write-Step 'Enabling winget DSC configuration support...'
try {
    & winget configure --enable --disable-interactivity 2>$null | Out-Null
    Write-Ok 'DSC configuration feature enabled.'
} catch {
    Write-Warn "Could not toggle the feature automatically: $($_.Exception.Message)"
    Write-Warn 'Continuing; modern winget builds enable configuration by default.'
}

# ---------------------------------------------------------------------------
# 3. Download the DSC file and run `winget configure` (fully silent).
# ---------------------------------------------------------------------------
Write-Step 'Downloading DSC configuration...'
$dscPath = Join-Path $env:TEMP 'winget-configure.dsc.yaml'
Invoke-WebRequest -Uri $dscUrl -OutFile $dscPath -UseBasicParsing
Write-Ok "Saved to $dscPath"

Write-Step 'Running winget configure (installing all packages)...'
& winget configure --file $dscPath `
    --accept-configuration-agreements `
    --disable-interactivity
if ($LASTEXITCODE -ne 0) {
    throw "winget configure exited with code $LASTEXITCODE."
}
Write-Ok 'All packages installed via winget configure.'

# ---------------------------------------------------------------------------
# 4. Refresh PATH so the freshly-installed chezmoi is callable, then apply.
# ---------------------------------------------------------------------------
Update-SessionPath

Write-Step 'Applying dotfiles with chezmoi...'
$chezmoi = Get-Command chezmoi -ErrorAction SilentlyContinue
if (-not $chezmoi) {
    throw 'chezmoi was not found on PATH after install. Open a new terminal and run: chezmoi init --apply ' + $DotfilesRepo
}

& chezmoi init --apply $DotfilesRepo
if ($LASTEXITCODE -ne 0) {
    throw "chezmoi init --apply exited with code $LASTEXITCODE."
}

Write-Step 'Bootstrap complete.'
Write-Ok 'Dotfiles applied. Open a fresh terminal to pick up the new PATH and PowerShell profile.'
Write-Info 'Note: the Neovim config (.chezmoiexternal.toml) is pulled over SSH;'
Write-Info 'run `chezmoi apply` again once you have an SSH key loaded to fetch it.'
