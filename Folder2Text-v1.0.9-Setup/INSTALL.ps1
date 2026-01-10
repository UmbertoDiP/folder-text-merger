# =========================
# Folder2Text v1.0.9 - Standalone Installer
# =========================
# This script installs Folder2Text on your system
# No admin rights required - installs to user profile
# =========================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ApplicationName = "Folder2Text"
$Version = "1.0.9"
$q = [char]34  # Double quote character

Write-Host ""
Write-Host "=== Folder2Text v$Version - Installer ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installing Folder2Text..."
Write-Host "Installation location: $env:LOCALAPPDATA\$ApplicationName"
Write-Host ""

# Paths
$ScriptDir = $PSScriptRoot
$InstallDir = Join-Path $env:LOCALAPPDATA $ApplicationName
$LogDir = Join-Path $InstallDir "logs"
$SourceExe = Join-Path $ScriptDir "Folder2Text.exe"
$TargetExe = Join-Path $InstallDir "Folder2Text.exe"
$ConfigSource = Join-Path $ScriptDir "config"

# Verify source files
if (-not (Test-Path $SourceExe)) {
    throw "Installation files not found. Please extract all files from the ZIP archive."
}

# Create directories
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

# Copy files
Write-Host "  - Copying executable..."
Copy-Item $SourceExe $TargetExe -Force

# Copy config if exists
if (Test-Path $ConfigSource) {
    Write-Host "  - Copying configuration..."
    Copy-Item $ConfigSource $InstallDir -Recurse -Force
}

# Load supported extensions
$ConfigFile = Join-Path $InstallDir "config\supported_extensions.txt"
$SupportedExtensions = @()
if (Test-Path $ConfigFile) {
    $SupportedExtensions = @(
        Get-Content $ConfigFile |
        Where-Object { $_ -match '^\.[a-z0-9]+$' } |
        ForEach-Object { $_.Trim() }
    )
}

Write-Host "  - Configuring context menu..."

$RegistryBase = "HKCU:\Software\Classes"

# 1. Folder context menu
$FolderMenuKey = Join-Path $RegistryBase "Directory\shell\$ApplicationName"
$FolderCommandKey = Join-Path $FolderMenuKey "command"

New-Item -Path $FolderMenuKey -Force | Out-Null
New-Item -Path $FolderCommandKey -Force | Out-Null

Set-ItemProperty -Path $FolderMenuKey -Name "(Default)" -Value "Folder2Text - Extract text from folder"
Set-ItemProperty -Path $FolderMenuKey -Name "Icon" -Value "$TargetExe,0"
Set-ItemProperty -Path $FolderCommandKey -Name "(Default)" -Value "$q$TargetExe$q $q%1$q"

# 2. Folder background context menu
$BackgroundMenuKey = Join-Path $RegistryBase "Directory\Background\shell\$ApplicationName"
$BackgroundCommandKey = Join-Path $BackgroundMenuKey "command"

New-Item -Path $BackgroundMenuKey -Force | Out-Null
New-Item -Path $BackgroundCommandKey -Force | Out-Null

Set-ItemProperty -Path $BackgroundMenuKey -Name "(Default)" -Value "Folder2Text - Extract text from folder"
Set-ItemProperty -Path $BackgroundMenuKey -Name "Icon" -Value "$TargetExe,0"
Set-ItemProperty -Path $BackgroundCommandKey -Name "(Default)" -Value "$q$TargetExe$q $q%V$q"

# 3. File type menus
if ($SupportedExtensions.Count -gt 0) {
    foreach ($ext in $SupportedExtensions) {
        $FileTypeMenuKey = Join-Path $RegistryBase "SystemFileAssociations\$ext\shell\$ApplicationName"
        $FileTypeCommandKey = Join-Path $FileTypeMenuKey "command"

        New-Item -Path $FileTypeMenuKey -Force | Out-Null
        New-Item -Path $FileTypeCommandKey -Force | Out-Null

        Set-ItemProperty -Path $FileTypeMenuKey -Name "(Default)" -Value "Merge with other text files"
        Set-ItemProperty -Path $FileTypeMenuKey -Name "Icon" -Value "$TargetExe,0"
        Set-ItemProperty -Path $FileTypeCommandKey -Name "(Default)" -Value "$q$TargetExe$q $q%1$q"
    }
    Write-Host "    Registered $($SupportedExtensions.Count) file types" -ForegroundColor Green
}

# 4. Register in Windows Programs and Features (Control Panel)
Write-Host "  - Registering in Windows Programs and Features..."

$UninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ApplicationName"
$UninstallScript = Join-Path $InstallDir "UNINSTALL.ps1"

New-Item -Path $UninstallKey -Force | Out-Null

# Calculate installation size (in KB)
$InstallSize = [math]::Round((Get-ChildItem $InstallDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1KB)

Set-ItemProperty -Path $UninstallKey -Name "DisplayName" -Value "Folder2Text"
Set-ItemProperty -Path $UninstallKey -Name "DisplayVersion" -Value $Version
Set-ItemProperty -Path $UninstallKey -Name "Publisher" -Value "Folder2Text"
Set-ItemProperty -Path $UninstallKey -Name "InstallLocation" -Value $InstallDir
# NOTE: Added -WindowStyle Hidden here to ensure silent launch from Control Panel
Set-ItemProperty -Path $UninstallKey -Name "UninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File $q$UninstallScript$q"
Set-ItemProperty -Path $UninstallKey -Name "DisplayIcon" -Value "$TargetExe,0"
Set-ItemProperty -Path $UninstallKey -Name "NoModify" -Value 1 -Type DWord
Set-ItemProperty -Path $UninstallKey -Name "NoRepair" -Value 1 -Type DWord
Set-ItemProperty -Path $UninstallKey -Name "EstimatedSize" -Value $InstallSize -Type DWord
Set-ItemProperty -Path $UninstallKey -Name "InstallDate" -Value (Get-Date -Format "yyyyMMdd")
Set-ItemProperty -Path $UninstallKey -Name "URLInfoAbout" -Value "https://github.com/UmbertoDiP/folder-text-merger"

Write-Host ""
Write-Host "=== INSTALLATION COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host ""
Write-Host "Installed to: $InstallDir"
Write-Host "Context menu: Enabled"
Write-Host "Control Panel: Registered"
Write-Host ""
Write-Host "You can now right-click on any folder to use 'Merge text files here'"
Write-Host ""
Write-Host "To uninstall: Settings > Apps > Apps & features > Folder2Text > Uninstall"
Write-Host "Or run UNINSTALL.ps1 from: $InstallDir"
Write-Host ""
