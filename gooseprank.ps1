<# 
.SYNOPSIS
    Spawns a goose on the desktop. Install Desktop Goose and make it hard to remove
.DESCRIPTION
    - With files from the Desktop Goose website, https://samperson.itch.io/desktop-goose
    - This script will install the Desktop Goose application and make it difficult to remove by creating a scheduled task that reinstalls it if deleted.
.NOTES
    Author: Mousman33
    Last Updated: 2026-04-01
- add 'install' mode to install the script and scheduled task, and 'remove' mode to remove the scheduled task and delete the files.
- make this the file that is run via its own scheduled task? Save goose zip somewhere. If goose zip are missing, run the remove option?
- add different install methods for admin vs non-admin

#>

#manually download desktop goose zip
write-host "First, we have to download the desktop goose zip file from the official website. Must be done manually. Please consider donating to the developer if you enjoy."
Start-Process "https://samperson.itch.io/desktop-goose"

#check that it was downloaded to the default location
$download = get-item "$env:USERPROFILE\Downloads\Desktop Goose*.zip"
if (Test-Path $download.FullName) {
    Write-Host "Desktop Goose zip file found at $($download.FullName)" -ForegroundColor Green
} else {
    Write-Host "Desktop Goose zip file not found. Please download it from the official website and place it in your Downloads folder." -ForegroundColor Red
    exit
}

#if running as admin, we can install to program files
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $installPath = "$env:ProgramFiles\Desktop Goose"
    write-host "Running as administrator, installing to $installPath"
} else {
    $installPath = "$env:USERPROFILE\AppData\Local\Desktop Goose"
    write-host "Not running as administrator, installing to $installPath"
}









