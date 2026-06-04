# Komorebi Autostart Script
# This script runs on Windows startup to launch komorebi

# Set config locations for komorebi and whkd
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"
$env:KOMOREBI_CONFIG_HOME = "$env:USERPROFILE\.config\komorebi"
$env:WHKD_CONFIG_HOME = "$env:USERPROFILE\.config\komorebi"

# Start komorebi; it launches whkd and the bars listed in
# bar_configurations (komorebi.json) once it is ready,
# so no sleep-based startup racing is needed
komorebic start --whkd --bar -c "$env:KOMOREBI_CONFIG_HOME\komorebi.json"

# komorebi-bar 0.1.40+ windows get a taskbar button despite requesting
# taskbar(false); strip WS_EX_APPWINDOW so the bars stay out of the taskbar
& "$env:KOMOREBI_CONFIG_HOME\hide-bar-from-taskbar.ps1"
