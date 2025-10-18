# PowerShell Profile Loaders

These loader files are reference templates that get deployed to the Windows Documents folder by the `run_once_before_setup-powershell-profiles.ps1.tmpl` script.

## Files

- `Microsoft.PowerShell_profile.ps1` - Loader template for PowerShell 7
- `WindowsPowerShell_profile.ps1` - Loader template for Windows PowerShell 5.1

## Deployment

When you run `chezmoi apply` on Windows, the run_once script will:
1. Detect your Documents folder (even if redirected to OneDrive)
2. Create `~/Documents/PowerShell/profile.ps1`
3. Create `~/Documents/WindowsPowerShell/profile.ps1`

Both loaders source the main profile at `~/.config/powershell/main_profile.ps1`

## Platform

These files are **Windows-only** and will not be deployed on macOS or Linux.