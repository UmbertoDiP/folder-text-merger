Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =========================
# Configurazione base
# =========================

$ApplicationName = "FolderTextMerger"
$ExecutableName = "FolderTextMerger.exe"

# =========================
# Rilevamento privilegi amministrativi
# =========================

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
$IsAdministrator = $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

# =========================
# Percorsi installazione
# =========================

if ($IsAdministrator) {
    $InstallRoot = $env:ProgramFiles
    $RegistryBase = "HKLM:\Software\Classes"
} else {
    $InstallRoot = $env:LOCALAPPDATA
    $RegistryBase = "HKCU:\Software\Classes"
}

$InstallDirectory = Join-Path $InstallRoot $ApplicationName
$TargetExecutablePath = Join-Path $InstallDirectory $ExecutableName

$LogDirectory = Join-Path (
    Join-Path $env:LOCALAPPDATA $ApplicationName
) "logs"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SourceExecutablePath = Join-Path $ProjectRoot $ExecutableName

Write-Host ""
Write-Host "=== FolderTextMerger INSTALLER ===" -ForegroundColor Cyan
Write-Host ""

# =========================
# Verifiche preliminari
# =========================

if (-not (Test-Path $SourceExecutablePath)) {
    throw "Source executable not found: $SourceExecutablePath"
}

# =========================
# Creazione directory
# =========================

Write-Host ">>> Preparing installation directories..."

New-Item -ItemType Directory -Path $InstallDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null

# =========================
# Copia eseguibile
# =========================

Write-Host ">>> Installing executable..."

Copy-Item `
    -Path $SourceExecutablePath `
    -Destination $TargetExecutablePath `
    -Force

if (-not (Test-Path $TargetExecutablePath)) {
    throw "Executable copy failed: $TargetExecutablePath"
}

# =========================
# Menu contestuale Windows
# =========================

Write-Host ">>> Configuring context menu..."

# Load supported file extensions from config file
$ConfigFile = Join-Path $ProjectRoot "config\supported_extensions.txt"
if (-not (Test-Path $ConfigFile)) {
    throw "Configuration file not found: $ConfigFile"
}

$SupportedExtensions = @(
    Get-Content $ConfigFile |
    Where-Object { $_ -match '^\.[a-z0-9]+$' } |
    ForEach-Object { $_.Trim() }
)

Write-Host "    Loaded $($SupportedExtensions.Count) file extensions from config" -ForegroundColor Cyan

# 1. Context menu for folders (right-click on folder)
$FolderMenuKey = Join-Path $RegistryBase "Directory\shell\$ApplicationName"
$FolderCommandKey = Join-Path $FolderMenuKey "command"

New-Item -Path $FolderMenuKey -Force | Out-Null
New-Item -Path $FolderCommandKey -Force | Out-Null

Set-ItemProperty -Path $FolderMenuKey -Name "(Default)" -Value "Merge text files here"
Set-ItemProperty -Path $FolderMenuKey -Name "Icon" -Value "$TargetExecutablePath,0"
Set-ItemProperty -Path $FolderCommandKey -Name "(Default)" -Value "`"$TargetExecutablePath`" `"%1`""

Write-Host "    Folder context menu: OK" -ForegroundColor Green

# 2. Context menu for folder background (right-click inside folder)
$BackgroundMenuKey = Join-Path $RegistryBase "Directory\Background\shell\$ApplicationName"
$BackgroundCommandKey = Join-Path $BackgroundMenuKey "command"

New-Item -Path $BackgroundMenuKey -Force | Out-Null
New-Item -Path $BackgroundCommandKey -Force | Out-Null

Set-ItemProperty -Path $BackgroundMenuKey -Name "(Default)" -Value "Merge text files here"
Set-ItemProperty -Path $BackgroundMenuKey -Name "Icon" -Value "$TargetExecutablePath,0"
Set-ItemProperty -Path $BackgroundCommandKey -Name "(Default)" -Value "`"$TargetExecutablePath`" `"%V`""

Write-Host "    Background context menu: OK" -ForegroundColor Green

# 3. Context menu for each supported file type
foreach ($ext in $SupportedExtensions) {
    $FileTypeMenuKey = Join-Path $RegistryBase "SystemFileAssociations\$ext\shell\$ApplicationName"
    $FileTypeCommandKey = Join-Path $FileTypeMenuKey "command"

    New-Item -Path $FileTypeMenuKey -Force | Out-Null
    New-Item -Path $FileTypeCommandKey -Force | Out-Null

    Set-ItemProperty -Path $FileTypeMenuKey -Name "(Default)" -Value "Merge with other text files"
    Set-ItemProperty -Path $FileTypeMenuKey -Name "Icon" -Value "$TargetExecutablePath,0"
    Set-ItemProperty -Path $FileTypeCommandKey -Name "(Default)" -Value "`"$TargetExecutablePath`" `"%1`""
}

Write-Host "    File type menus: OK ($($SupportedExtensions.Count) extensions)" -ForegroundColor Green

# 4. Multi-selection NOT supported
# Note: Windows doesn't support passing multiple selected files via *\shell
# Users should right-click on the containing folder or inside folder background instead
Write-Host "    Multi-selection menu: SKIPPED (use folder menu instead)" -ForegroundColor Yellow

# =========================
# Conferma finale
# =========================

Write-Host ""
Write-Host "INSTALLATION COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host ""
Write-Host "Executable path: $TargetExecutablePath"
Write-Host "Log directory   : $LogDirectory"
Write-Host "Context menu    : Enabled"
Write-Host ""
