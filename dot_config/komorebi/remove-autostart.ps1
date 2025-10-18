# Script to remove komorebi autostart from Windows
# Run this if you want to disable automatic startup

$taskName = "KomorebAutostart"

Write-Host "Removing komorebi autostart..." -ForegroundColor Cyan

# Check if task exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Successfully removed '$taskName' from startup!" -ForegroundColor Green
    } catch {
        Write-Host "Error removing task: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Task '$taskName' not found. Nothing to remove." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Komorebi will no longer start automatically on login." -ForegroundColor Cyan
Write-Host "You can still start it manually with the 'ks' command." -ForegroundColor Cyan