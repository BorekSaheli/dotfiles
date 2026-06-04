# Strips WS_EX_APPWINDOW from komorebi-bar windows so they don't get a
# Windows taskbar button (and stay out of Alt-Tab).
#
# komorebi-bar requests taskbar(false) via eframe, but on 0.1.40+ the
# window still ends up with WS_EX_APPWINDOW, which forces a taskbar
# button per bar. This script swaps that flag for WS_EX_TOOLWINDOW.
# Called from autostart.ps1; safe to re-run at any time (e.g. via ks).

Add-Type @'
using System;
using System.Runtime.InteropServices;
public class BarTaskbarFix {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr lp);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    [DllImport("user32.dll", EntryPoint="SetWindowLongPtr")] public static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@

$GWL_EXSTYLE = -20
$WS_EX_TOOLWINDOW = 0x80
$WS_EX_APPWINDOW = 0x40000
$SW_HIDE = 0
$SW_SHOWNA = 8

function Repair-BarWindows {
    $barPids = (Get-Process -Name 'komorebi-bar' -ErrorAction SilentlyContinue).Id
    if (-not $barPids) { return 0 }
    $script:fixedCount = 0
    $cb = [BarTaskbarFix+EnumWindowsProc]{
        param($hWnd, $lParam)
        $procId = 0
        [BarTaskbarFix]::GetWindowThreadProcessId($hWnd, [ref]$procId) | Out-Null
        if ($barPids -contains $procId -and [BarTaskbarFix]::IsWindowVisible($hWnd)) {
            $ex = [BarTaskbarFix]::GetWindowLong($hWnd, $GWL_EXSTYLE)
            if (($ex -band $WS_EX_APPWINDOW) -ne 0) {
                $new = ($ex -band (-bnot $WS_EX_APPWINDOW)) -bor $WS_EX_TOOLWINDOW
                # hide -> restyle -> show again: the taskbar only re-reads
                # the style when the window transitions visibility
                [BarTaskbarFix]::ShowWindow($hWnd, $SW_HIDE) | Out-Null
                [BarTaskbarFix]::SetWindowLongPtr($hWnd, $GWL_EXSTYLE, [IntPtr]$new) | Out-Null
                [BarTaskbarFix]::ShowWindow($hWnd, $SW_SHOWNA) | Out-Null
                $script:fixedCount++
            }
        }
        return $true
    }
    [BarTaskbarFix]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    return $script:fixedCount
}

# The bars come up shortly after `komorebic start --bar` returns; poll for
# up to 30s so every bar gets fixed regardless of launch timing.
$deadline = (Get-Date).AddSeconds(30)
$totalFixed = 0
while ((Get-Date) -lt $deadline) {
    $totalFixed += Repair-BarWindows
    # all bars present and clean for one extra pass -> done
    if ($totalFixed -gt 0 -and (Repair-BarWindows) -eq 0) { break }
    Start-Sleep -Seconds 1
}
Write-Host "hide-bar-from-taskbar: fixed $totalFixed bar window(s)"
