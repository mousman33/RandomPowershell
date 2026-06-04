<#
.SYNOPSIS
    A script to compliment the foulplay script. Uses the desktop goose app to spawn a goose using the startup folder. 


#>

# Determine execution context (Admin vs User) and set paths
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if ($isAdmin) {
    Write-Host "Context: Administrator" -ForegroundColor Cyan
    $installPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
    $unzippedpath = "$env:ProgramFiles\MicrosoftUU"
    # create backup location to hide files
    $backupPath = "$env:ProgramFiles\Microsoft Procs"
} else {
    Write-Host "Context: Standard User ($env:USERNAME)" -ForegroundColor Cyan
    $installPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $unzippedpath = "$env:USERPROFILE\AppData\Local\MicrosoftUU"
    # create backup location to hide files
    $backupPath = "$env:USERPROFILE\AppData\Local\Microsoft Procs"
}


#-----------------------------------------------------------------------------------------------
#region Variables and Functions


function unpackgoose {
    # Extract to the install path
    $backupzip = Get-ChildItem -Path $backupPath -Filter "Desktop Goose*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($backupzip) {
        Write-Host "Found backup zip at $($backupzip.FullName). Extracting..." -ForegroundColor Green
        Expand-Archive -Path $backupzip.FullName -DestinationPath $unzippedpath -Force
        Write-Host "Desktop Goose extracted to $unzippedpath" -ForegroundColor Green
    } else {
        Write-Host "Backup zip not found in $backupPath. Removing gosling..." -ForegroundColor Red
        undo-gosling
        exit
    }
}


function undo-gosling {
    # Remove the startup shortcut
    $shortcutPath = Join-Path -Path $installPath -ChildPath "Goose.lnk"
    if (Test-Path -Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
        Write-Host "Removed startup shortcut: $shortcutPath" -ForegroundColor Green
    } else {
        Write-Host "No startup shortcut found to remove." -ForegroundColor Yellow
    }
}





#endregion
#-----------------------------------------------------------------------------------------------
#region LOGIC

#if the package is not unzipped, unzip it
if (-not (Test-Path -Path $unzippedpath)) {
    Write-Host "Desktop Goose not found in unzipped location. Attempting to unpack..." -ForegroundColor Yellow
    unpackgoose
} else {
    Write-Host "Desktop Goose already exists in unzipped location." -ForegroundColor Green
}


# If shortcut to desktop goose doesn't exist, recreate it
$shortcutPath = Join-Path -Path $installPath -ChildPath "WinPix.lnk"
if (-not (Test-Path -Path $shortcutPath)) {
    Write-Host "Desktop Goose shortcut not found in startup folder. Attempting to recreate..." -ForegroundColor Yellow
    $honk = Get-ChildItem -Path $unzippedpath -Filter "GooseDesktop.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    $WshShell = New-Object -COMObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$shortcutPath")
    $Shortcut.TargetPath = $honk.FullName
    $Shortcut.Save()
} else {
    Write-Host "Desktop Goose shortcut already exists in startup folder." -ForegroundColor Green
}






#endregion