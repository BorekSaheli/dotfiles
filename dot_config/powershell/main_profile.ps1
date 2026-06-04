# Unified PowerShell Profile
# Works for both PowerShell 7 and Windows PowerShell 5.1
# Works for both admin and non-admin sessions

# Set XDG_CONFIG_HOME so Neovim uses ~/.config/nvim
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"

# Set Komorebi config path
$env:KOMOREBI_CONFIG_HOME = "$env:USERPROFILE\.config\komorebi"

# Set Starship config path
$env:STARSHIP_CONFIG = "$env:USERPROFILE\.config\starship\starship.toml"

# Initialize Starship prompt
Invoke-Expression (&starship init powershell)

# Aliases
Set-Alias lg lazygit
Set-Alias vim nvim
Set-Alias vi nvim
Set-Alias v nvim
Set-Alias viktor viktor-cli
Set-Alias ff fastfetch
Set-Alias activate venv\Scripts\Activate

# Path additions - removed old komorebi tools path (now using winget version)

# Komorebi functions
function ks {
    # Check if running as administrator (komorebi inherits elevation from this shell)
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Host "Starting komorebi with ADMIN privileges..." -ForegroundColor Yellow
    } else {
        Write-Host "Starting komorebi..."
    }

    # Single source of truth: same script the logon task runs.
    # komorebi starts whkd and the bars (bar_configurations in
    # komorebi.json) itself once it is ready - no sleeps needed.
    & "$env:USERPROFILE\.config\komorebi\autostart.ps1"
}
function kq {
    Write-Host "Closing komorebi..."
    komorebic stop | Out-Null
    Stop-Process -Name whkd -ErrorAction SilentlyContinue
    Stop-Process -Name komorebi-bar -ErrorAction SilentlyContinue
}

function ks-onboot-true {
    Write-Host "Enabling komorebi autostart..." -ForegroundColor Cyan
    & "$env:USERPROFILE\.config\komorebi\register-startup.ps1"
}

function ks-onboot-false {
    Write-Host "Disabling komorebi autostart..." -ForegroundColor Cyan
    & "$env:USERPROFILE\.config\komorebi\remove-autostart.ps1"
}

# Git diff helper
function showdiff { git diff --cached --stat }

# Reload Windows environment variables
function winsource {
  $machinePath = [System.Environment]::GetEnvironmentVariable("Path","Machine")
  $userpath = [System.Environment]::GetEnvironmentVariable("Path","User")
  $env:Path = $userpath + ";" + $machinePath
}

# Neovide launcher (if needed)
# function neovide {
#     $env:NEOVIDE_OPENGL = "1"
#     $env:WGPU_BACKEND = "dx12"
#     $env:WGPU_POWER_PREF = "high-performance"
#     $currentDir = Get-Location
#     Start-Process "C:\Users\borek.saheli\scoop\apps\neovide\current\neovide.exe" -ArgumentList "--opengl --frame none $args" -WorkingDirectory $currentDir
# }

# Import PSReadLine for better command line editing (PowerShell 5.1)
if ($PSVersionTable.PSVersion.Major -eq 5) {
    Import-Module PSReadLine
}