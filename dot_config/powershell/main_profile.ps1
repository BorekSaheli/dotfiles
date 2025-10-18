# Unified PowerShell Profile
# Works for both PowerShell 7 and Windows PowerShell 5.1
# Works for both admin and non-admin sessions

# Set XDG_CONFIG_HOME so Neovim uses ~/.config/nvim
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"

# Set Komorebi config path
$env:KOMOREBI_CONFIG_HOME = "$env:USERPROFILE\.config\komorebi"

# Initialize Starship prompt
Invoke-Expression (&starship init powershell)

# Aliases
Set-Alias vim nvim
Set-Alias v viktor-cli
Set-Alias ff fastfetch

# Path additions
$env:Path += ";C:\Users\borek.saheli\tools\komorebi"

# Komorebi functions
function ks {
    Write-Host "Starting komorebi..."

    # Start komorebi with custom config path
    $komorebicConfig = "$env:KOMOREBI_CONFIG_HOME\komorebi.json"
    $whkdConfig = "$env:KOMOREBI_CONFIG_HOME\whkdrc"

    # Start komorebi first (it needs to be running for bar and whkd)
    komorebic start -c $komorebicConfig | Out-Null

    # Wait a moment for komorebi to initialize
    Start-Sleep -Seconds 2

    # Start whkd with custom config
    Start-Process -WindowStyle Hidden whkd -ArgumentList "-c", $whkdConfig

    # Start komorebi-bar instances for each monitor
    $barConfigs = @(
        "$env:KOMOREBI_CONFIG_HOME\komorebi_bar\komorebi.bar.json",
        "$env:KOMOREBI_CONFIG_HOME\komorebi_bar\komorebi.bar.monitor0.json",
        "$env:KOMOREBI_CONFIG_HOME\komorebi_bar\komorebi.bar.monitor1.json",
        "$env:KOMOREBI_CONFIG_HOME\komorebi_bar\komorebi.bar.monitor2.json"
    )

    foreach ($config in $barConfigs) {
        if (Test-Path $config) {
            Start-Process -WindowStyle Hidden komorebi-bar -ArgumentList "-c", $config
        }
    }
}
function kq {
    Write-Host "Closing komorebi..."
    komorebic stop | Out-Null
    Stop-Process -Name whkd -ErrorAction SilentlyContinue
    Stop-Process -Name komorebi-bar -ErrorAction SilentlyContinue
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