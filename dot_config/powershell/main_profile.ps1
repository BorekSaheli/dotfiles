# Unified PowerShell Profile
# Works for both PowerShell 7 and Windows PowerShell 5.1
# Works for both admin and non-admin sessions

# Set XDG_CONFIG_HOME so Neovim uses ~/.config/nvim
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"

# Initialize Starship prompt
Invoke-Expression (&starship init powershell)

# Aliases
Set-Alias vim nvim
Set-Alias v viktor-cli
Set-Alias ff fastfetch

# Path additions
$env:Path += ";C:\Users\borek.saheli\tools\komorebi"

# Komorebi functions
function ks { komorebic start --whkd --bar }
function kq { komorebic stop --whkd --bar }

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