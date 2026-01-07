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

$ContextMenuKey = Join-Path $RegistryBase "Directory\shell\$ApplicationName"
$CommandKey = Join-Path $ContextMenuKey "command"

New-Item -Path $ContextMenuKey -Force | Out-Null
New-Item -Path $CommandKey -Force | Out-Null

Set-ItemProperty `
    -Path $ContextMenuKey `
    -Name "(Default)" `
    -Value "Merge text files here"

Set-ItemProperty `
    -Path $ContextMenuKey `
    -Name "Icon" `
    -Value $TargetExecutablePath

$CommandValue = "`"$TargetExecutablePath`" `"%1`""

Set-ItemProperty `
    -Path $CommandKey `
    -Name "(Default)" `
    -Value $CommandValue

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
