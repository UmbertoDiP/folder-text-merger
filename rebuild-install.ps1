Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# =========================
# Configurazione base
# =========================

$ProjectRoot = $PSScriptRoot
$PythonFileName = "FolderTextMerger.py"
$PythonFilePath = Join-Path $ProjectRoot $PythonFileName
$ExecutableName = "FolderTextMerger.exe"
$DistDirectory = Join-Path $ProjectRoot "dist"
$BuildDirectory = Join-Path $ProjectRoot "build"
$DistExecutablePath = Join-Path $DistDirectory $ExecutableName
$InstallerScriptPath = Join-Path $ProjectRoot "installer.ps1"

Write-Host ""
Write-Host "=== FolderTextMerger BUILD SYSTEM ===" -ForegroundColor Cyan
Write-Host ""

# =========================
# Verifiche preliminari
# =========================

if (-not (Test-Path $PythonFilePath)) {
    throw "Python source file not found: $PythonFilePath"
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "Python interpreter not found in PATH"
}

# =========================
# Incremento versione (rc)
# =========================

Write-Host ">>> Incrementing version (rc)..."

$PythonSource = Get-Content -Path $PythonFilePath -Encoding UTF8

$VersionUpdated = $false

for ($Index = 0; $Index -lt $PythonSource.Length; $Index++) {
    if ($PythonSource[$Index] -match 'VERSION\s*=\s*"([^"]+)-rc(\d+)"') {

        $BaseVersion = $Matches[1]
        $CurrentRc = [int]$Matches[2]
        $NextRc = $CurrentRc + 1

        $PythonSource[$Index] = "VERSION = `"$BaseVersion-rc$NextRc`""
        $VersionUpdated = $true
        break
    }
}

if (-not $VersionUpdated) {
    throw "Unable to locate VERSION declaration for rc increment"
}

Set-Content -Path $PythonFilePath -Value $PythonSource -Encoding UTF8
Write-Host ">>> Version updated successfully"

# =========================
# Pulizia build precedenti
# =========================

Write-Host ">>> Cleaning previous build artifacts..."

if (Test-Path $BuildDirectory) {
    Remove-Item -Path $BuildDirectory -Recurse -Force
}

if (Test-Path $DistDirectory) {
    Remove-Item -Path $DistDirectory -Recurse -Force
}

# =========================
# Compilazione PyInstaller
# =========================

Write-Host ">>> Running PyInstaller..."

python -m PyInstaller `
    --onefile `
    --clean `
    --name "FolderTextMerger" `
    $PythonFilePath

if (-not (Test-Path $DistExecutablePath)) {
    throw "Build failed: executable not found at $DistExecutablePath"
}

Write-Host ">>> Executable built successfully"

# =========================
# Avvio installer
# =========================

if (-not (Test-Path $InstallerScriptPath)) {
    throw "Installer script not found: $InstallerScriptPath"
}

Write-Host ">>> Launching installer..."

powershell.exe `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $InstallerScriptPath

# =========================
# Riavvio Explorer
# =========================

Write-Host ">>> Restarting Windows Explorer..."

Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process explorer

Write-Host ""
Write-Host "REBUILD COMPLETED SUCCESSFULLY" -ForegroundColor Green
Write-Host ""

Pause
