# Komorebi Autostart Script
# This script runs on Windows startup to launch komorebi

# Set XDG_CONFIG_HOME and KOMOREBI_CONFIG_HOME
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"
$env:KOMOREBI_CONFIG_HOME = "$env:USERPROFILE\.config\komorebi"

# Start komorebi with custom config path
$komorebicConfig = "$env:KOMOREBI_CONFIG_HOME\komorebi.json"
$whkdConfig = "$env:KOMOREBI_CONFIG_HOME\whkdrc"

# Start komorebi first (it needs to be running for bar and whkd)
komorebic start -c $komorebicConfig | Out-Null

# Wait a moment for komorebi to initialize
Start-Sleep -Seconds 2

# Start whkd with custom config (if installed)
if (Get-Command whkd -ErrorAction SilentlyContinue) {
    Start-Process -WindowStyle Hidden whkd -ArgumentList "-c", $whkdConfig
}

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