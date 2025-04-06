@echo off
:: Elevate to admin if not already
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting admin privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo ===== Removing Microsoft Edge =====

:: Remove Edge Appx Packages
powershell -Command "Get-AppxPackage -AllUsers ^| Where-Object { $_.Name -like '*MicrosoftEdge*' } ^| ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue }"

:: Remove Edge via winget
powershell -Command "if (Get-Command winget -ErrorAction SilentlyContinue) { if ((winget list --name 'Microsoft Edge') -match 'Microsoft Edge') { winget uninstall --name 'Microsoft Edge' --silent --accept-source-agreements --accept-package-agreements } }"

:: Delete Edge directories
takeown /f "C:\Program Files (x86)\Microsoft\Edge" /r /d y >nul 2>&1
icacls "C:\Program Files (x86)\Microsoft\Edge" /grant Administrators:F /t >nul 2>&1
rmdir /s /q "C:\Program Files (x86)\Microsoft\Edge"

takeown /f "C:\Program Files\Microsoft\Edge" /r /d y >nul 2>&1
icacls "C:\Program Files\Microsoft\Edge" /grant Administrators:F /t >nul 2>&1
rmdir /s /q "C:\Program Files\Microsoft\Edge"

takeown /f "%LOCALAPPDATA%\Microsoft\Edge" /r /d y >nul 2>&1
icacls "%LOCALAPPDATA%\Microsoft\Edge" /grant Administrators:F /t >nul 2>&1
rmdir /s /q "%LOCALAPPDATA%\Microsoft\Edge"

:: Delete registry keys (both 64 and 32-bit views)
echo Deleting registry keys...
REG DELETE "HKLM\SOFTWARE\Policies\Microsoft\Edge" /f >nul 2>&1
REG DELETE "HKCU\SOFTWARE\Policies\Microsoft\Edge" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f >nul 2>&1
REG DELETE "HKCU\Software\Microsoft\Edge" /f >nul 2>&1
REG DELETE "HKCU\Software\Microsoft\EdgeUpdate" /f >nul 2>&1
REG DELETE "HKCR\Applications\msedge.exe" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1

:: Create retry script for startup
echo Creating retry script...
set RetryScript=%ProgramData%\RemoveEdgeOnBoot.ps1
> "%RetryScript%" (
    echo $ErrorActionPreference = 'SilentlyContinue'
    echo function Is-EdgeInstalled {
    echo     Test-Path 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' -or Test-Path 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
    echo }
    echo function Remove-Edge {
    echo     $dirs = @(
    echo         'C:\Program Files (x86)\Microsoft\Edge',
    echo         'C:\Program Files\Microsoft\Edge',
    echo         "$env:LOCALAPPDATA\Microsoft\Edge"
    echo     )
    echo     foreach ($d in $dirs) {
    echo         if (Test-Path $d) {
    echo             takeown /f $d /r /d y ^| Out-Null
    echo             icacls $d /grant Administrators:F /t ^| Out-Null
    echo             Remove-Item -Path $d -Recurse -Force -ErrorAction SilentlyContinue
    echo         }
    echo     }
    echo     $registryPaths = @(
    echo         'HKLM:\SOFTWARE\Policies\Microsoft\Edge',
    echo         'HKCU:\SOFTWARE\Policies\Microsoft\Edge',
    echo         'HKLM:\SOFTWARE\Microsoft\EdgeUpdate',
    echo         'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate',
    echo         'HKCU:\Software\Microsoft\Edge',
    echo         'HKCU:\Software\Microsoft\EdgeUpdate',
    echo         'HKCR:\Applications\msedge.exe',
    echo         'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge',
    echo         'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge'
    echo     )
    echo     foreach ($regPath in $registryPaths) {
    echo         if (Test-Path $regPath) {
    echo             Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
    echo         }
    echo     }
    echo }
    echo if (Is-EdgeInstalled) {
    echo     Remove-Edge
    echo     if (Is-EdgeInstalled) {
    echo         Write-Output '[!] Microsoft Edge could not be removed after reboot.'
    echo     }
    echo }
)

:: Register task to run it at startup
powershell -Command "Register-ScheduledTask -TaskName 'RemoveEdgeOnBoot' -Trigger (New-ScheduledTaskTrigger -AtStartup) -Action (New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File \"%RetryScript%\"') -RunLevel Highest -Force"

echo.
echo Microsoft Edge removal attempted. System will now restart to verify and retry on boot.
shutdown /r /t 10
