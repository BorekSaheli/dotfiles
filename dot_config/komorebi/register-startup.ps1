# Script to register komorebi autostart with Windows Task Scheduler
# Run this script once to set up automatic startup

$taskName = "KomorebAutostart"
$scriptPath = "$env:USERPROFILE\.config\komorebi\autostart.ps1"

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "Task '$taskName' already exists. Unregistering old task..."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the action to run PowerShell with the autostart script (completely hidden)
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$scriptPath`""

# Create the trigger to run at logon
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Create the principal to run with highest privileges (needed for window management)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

# Create settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Register the task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Automatically start komorebi window manager at login"

Write-Host ""
Write-Host "Successfully registered '$taskName' to run at startup!" -ForegroundColor Green
Write-Host ""
Write-Host "To manage this task:"
Write-Host "  - View: Get-ScheduledTask -TaskName '$taskName'"
Write-Host "  - Remove: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
Write-Host "  - Test now: Start-ScheduledTask -TaskName '$taskName'"