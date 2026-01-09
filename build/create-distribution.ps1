# =========================
# FolderTextMerger - Distribution Package Creator
# =========================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$ProjectRoot = Split-Path $ScriptDir -Parent
$DistribFolder = Join-Path $ProjectRoot "distribution"
$Version = "1.0.5"

Write-Host ""
Write-Host "=== Creating Distribution Package v$Version ===" -ForegroundColor Cyan
Write-Host ""

# Clean and create distribution folder
if (Test-Path $DistribFolder) {
    Remove-Item $DistribFolder -Recurse -Force
}
New-Item -ItemType Directory -Path $DistribFolder | Out-Null

# Copy executable
Write-Host ">>> Copying executable..."
$ExePath = Join-Path $ProjectRoot "FolderTextMerger.exe"
if (-not (Test-Path $ExePath)) {
    throw "Executable not found: $ExePath"
}
Copy-Item $ExePath $DistribFolder

# Copy config
Write-Host ">>> Copying configuration..."
$ConfigFolder = Join-Path $ProjectRoot "config"
Copy-Item $ConfigFolder $DistribFolder -Recurse

# Create standalone installer
Write-Host ">>> Creating standalone installer..."

$InstallerContent = @"
# =========================
# FolderTextMerger v$Version - Standalone Installer
# =========================
# This script installs FolderTextMerger on your system
# No admin rights required - installs to user profile
# =========================

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"

`$ApplicationName = "FolderTextMerger"
`$Version = "$Version"
`$q = [char]34  # Double quote character

Write-Host ""
Write-Host "=== FolderTextMerger v`$Version - Installer ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installing FolderTextMerger..."
Write-Host "Installation location: `$env:LOCALAPPDATA\`$ApplicationName"
Write-Host ""

# Paths
`$ScriptDir = `$PSScriptRoot
`$InstallDir = Join-Path `$env:LOCALAPPDATA `$ApplicationName
`$LogDir = Join-Path `$InstallDir "logs"
`$SourceExe = Join-Path `$ScriptDir "FolderTextMerger.exe"
`$TargetExe = Join-Path `$InstallDir "FolderTextMerger.exe"
`$ConfigSource = Join-Path `$ScriptDir "config"

# Verify source files
if (-not (Test-Path `$SourceExe)) {
    throw "Installation files not found. Please extract all files from the ZIP archive."
}

# Create directories
New-Item -ItemType Directory -Path `$InstallDir -Force | Out-Null
New-Item -ItemType Directory -Path `$LogDir -Force | Out-Null

# Copy files
Write-Host "  - Copying executable..."
Copy-Item `$SourceExe `$TargetExe -Force

# Copy config if exists
if (Test-Path `$ConfigSource) {
    Write-Host "  - Copying configuration..."
    Copy-Item `$ConfigSource `$InstallDir -Recurse -Force
}

# Load supported extensions
`$ConfigFile = Join-Path `$InstallDir "config\supported_extensions.txt"
`$SupportedExtensions = @()
if (Test-Path `$ConfigFile) {
    `$SupportedExtensions = @(
        Get-Content `$ConfigFile |
        Where-Object { `$_ -match '^\.[a-z0-9]+$' } |
        ForEach-Object { `$_.Trim() }
    )
}

Write-Host "  - Configuring context menu..."

`$RegistryBase = "HKCU:\Software\Classes"

# 1. Folder context menu
`$FolderMenuKey = Join-Path `$RegistryBase "Directory\shell\`$ApplicationName"
`$FolderCommandKey = Join-Path `$FolderMenuKey "command"

New-Item -Path `$FolderMenuKey -Force | Out-Null
New-Item -Path `$FolderCommandKey -Force | Out-Null

Set-ItemProperty -Path `$FolderMenuKey -Name "(Default)" -Value "Merge text files here"
Set-ItemProperty -Path `$FolderMenuKey -Name "Icon" -Value "`$TargetExe,0"
Set-ItemProperty -Path `$FolderCommandKey -Name "(Default)" -Value "`$q`$TargetExe`$q `$q%1`$q"

# 2. Folder background context menu
`$BackgroundMenuKey = Join-Path `$RegistryBase "Directory\Background\shell\`$ApplicationName"
`$BackgroundCommandKey = Join-Path `$BackgroundMenuKey "command"

New-Item -Path `$BackgroundMenuKey -Force | Out-Null
New-Item -Path `$BackgroundCommandKey -Force | Out-Null

Set-ItemProperty -Path `$BackgroundMenuKey -Name "(Default)" -Value "Merge text files here"
Set-ItemProperty -Path `$BackgroundMenuKey -Name "Icon" -Value "`$TargetExe,0"
Set-ItemProperty -Path `$BackgroundCommandKey -Name "(Default)" -Value "`$q`$TargetExe`$q `$q%V`$q"

# 3. File type menus
if (`$SupportedExtensions.Count -gt 0) {
    foreach (`$ext in `$SupportedExtensions) {
        `$FileTypeMenuKey = Join-Path `$RegistryBase "SystemFileAssociations\`$ext\shell\`$ApplicationName"
        `$FileTypeCommandKey = Join-Path `$FileTypeMenuKey "command"

        New-Item -Path `$FileTypeMenuKey -Force | Out-Null
        New-Item -Path `$FileTypeCommandKey -Force | Out-Null

        Set-ItemProperty -Path `$FileTypeMenuKey -Name "(Default)" -Value "Merge with other text files"
        Set-ItemProperty -Path `$FileTypeMenuKey -Name "Icon" -Value "`$TargetExe,0"
        Set-ItemProperty -Path `$FileTypeCommandKey -Name "(Default)" -Value "`$q`$TargetExe`$q `$q%1`$q"
    }
    Write-Host "    Registered `$(`$SupportedExtensions.Count) file types" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== INSTALLATION COMPLETED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host ""
Write-Host "Installed to: `$InstallDir"
Write-Host "Context menu: Enabled"
Write-Host ""
Write-Host "You can now right-click on any folder to use 'Merge text files here'"
Write-Host ""
"@

$InstallerPath = Join-Path $DistribFolder "INSTALL.ps1"
Set-Content -Path $InstallerPath -Value $InstallerContent -Encoding UTF8

# Create uninstaller
Write-Host ">>> Creating uninstaller..."

$UninstallerContent = @"
# =========================
# FolderTextMerger v$Version - Uninstaller
# =========================

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"

`$ApplicationName = "FolderTextMerger"

Write-Host ""
Write-Host "=== FolderTextMerger - Uninstaller ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Removing FolderTextMerger from your system..."
Write-Host ""

`$InstallDir = Join-Path `$env:LOCALAPPDATA `$ApplicationName
`$RegistryBase = "HKCU:\Software\Classes"

# Remove context menu entries
Write-Host "  - Removing context menu..."

`$Keys = @(
    "Directory\shell\`$ApplicationName",
    "Directory\Background\shell\`$ApplicationName"
)

foreach (`$key in `$Keys) {
    `$fullPath = Join-Path `$RegistryBase `$key
    if (Test-Path `$fullPath) {
        Remove-Item `$fullPath -Recurse -Force
    }
}

# Remove file type associations (search and remove)
`$SystemFileAssoc = Join-Path `$RegistryBase "SystemFileAssociations"
if (Test-Path `$SystemFileAssoc) {
    Get-ChildItem `$SystemFileAssoc | ForEach-Object {
        `$appPath = Join-Path `$_.PSPath "shell\`$ApplicationName"
        if (Test-Path `$appPath) {
            Remove-Item `$appPath -Recurse -Force
        }
    }
}

# Remove installation directory
Write-Host "  - Removing files..."
if (Test-Path `$InstallDir) {
    Remove-Item `$InstallDir -Recurse -Force
}

Write-Host ""
Write-Host "=== UNINSTALLATION COMPLETED ===" -ForegroundColor Green
Write-Host ""
Write-Host "FolderTextMerger has been removed from your system."
Write-Host ""
"@

$UninstallerPath = Join-Path $DistribFolder "UNINSTALL.ps1"
Set-Content -Path $UninstallerPath -Value $UninstallerContent -Encoding UTF8

# Create README
Write-Host ">>> Creating README..."

$ReadmeContent = @"
# FolderTextMerger v$Version

## Quick Start

1. Right-click on **INSTALL.ps1** and select **"Run with PowerShell"**
2. Wait for installation to complete (few seconds)
3. Done! Right-click on any folder to see "Merge text files here"

## What does it do?

FolderTextMerger combines multiple text files from a folder into a single output file.
Perfect for:
- Sharing code with AI assistants (Claude, ChatGPT, etc.)
- Creating project snapshots
- Reviewing multiple log files
- Documentation gathering

## Features

- Works with 60+ file types (.txt, .py, .java, .js, .md, etc.)
- Automatic binary file detection and exclusion
- Comprehensive summary with file statistics
- Silent execution (no console windows)
- Context menu integration (right-click on folders)

## Usage

**Option 1**: Right-click on a folder → "Merge text files here"
**Option 2**: Right-click inside a folder (on background) → "Merge text files here"
**Option 3**: Right-click on text files → "Merge with other text files"

Output file will be created in the parent directory with format:
\`output-[foldername]-[timestamp].txt\`

## Uninstallation

Right-click on **UNINSTALL.ps1** and select **"Run with PowerShell"**

## System Requirements

- Windows 10/11
- PowerShell (included in Windows)
- No admin rights required

## Privacy

- All processing is local (no internet connection required)
- No data collection
- Open source: https://github.com/UmbertoDiP/folder-text-merger

## Version

$Version (Released: $(Get-Date -Format 'yyyy-MM-dd'))

## License

Copyright (c) 2026 FolderTextMerger. All rights reserved.

---

**Troubleshooting**

If installation fails with "execution policy" error:
1. Open PowerShell as Administrator
2. Run: \`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser\`
3. Retry installation

For support: https://github.com/UmbertoDiP/folder-text-merger/issues
"@

$ReadmePath = Join-Path $DistribFolder "README.txt"
Set-Content -Path $ReadmePath -Value $ReadmeContent -Encoding UTF8

# Create ZIP archive
Write-Host ">>> Creating ZIP archive..."

$ZipName = "FolderTextMerger-v$Version-Setup.zip"
$ZipPath = Join-Path $ProjectRoot $ZipName

if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Add-Type -Assembly System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $DistribFolder,
    $ZipPath,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
)

Write-Host ""
Write-Host "=== DISTRIBUTION PACKAGE CREATED ===" -ForegroundColor Green
Write-Host ""
Write-Host "Package: $ZipName"
Write-Host "Location: $ProjectRoot"
Write-Host "Size: $([math]::Round((Get-Item $ZipPath).Length / 1MB, 2)) MB"
Write-Host ""
Write-Host "Contents:"
Write-Host "  - FolderTextMerger.exe (application)"
Write-Host "  - INSTALL.ps1 (auto-installer)"
Write-Host "  - UNINSTALL.ps1 (uninstaller)"
Write-Host "  - README.txt (documentation)"
Write-Host "  - config/ (supported file types)"
Write-Host ""
Write-Host "Send this ZIP file to your friends. They just need to:"
Write-Host "  1. Extract the ZIP"
Write-Host "  2. Right-click INSTALL.ps1 -> Run with PowerShell"
Write-Host "  3. Done!"
Write-Host ""
