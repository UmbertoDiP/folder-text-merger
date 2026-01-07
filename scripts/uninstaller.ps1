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

Write-Host ""
Write-Host "=== FolderTextMerger UNINSTALLER ===" -ForegroundColor Cyan
Write-Host ""

# =========================
# Rimozione menu contestuale
# =========================

Write-Host ">>> Removing context menu integration..."

$ContextMenuKey = Join-Path $RegistryBase "Directory\shell\$ApplicationName"

if (Test-Path $ContextMenuKey) {
    try {
        Remove-Item -Path $ContextMenuKey -Recurse -Force -ErrorAction Stop
        Write-Host "    Context menu removed" -ForegroundColor Green
    } catch {
        Write-Host "    WARNING: Could not remove context menu: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    Context menu not found (already removed)" -ForegroundColor Gray
}

# Rimuovi anche da HKCR se esiste (fallback per installazioni precedenti)
$HKCRContextMenu = "Registry::HKEY_CLASSES_ROOT\Directory\shell\$ApplicationName"
if (Test-Path $HKCRContextMenu) {
    try {
        Remove-Item -Path $HKCRContextMenu -Recurse -Force -ErrorAction Stop
        Write-Host "    Legacy context menu removed (HKCR)" -ForegroundColor Green
    } catch {
        Write-Host "    WARNING: Could not remove legacy context menu" -ForegroundColor Yellow
    }
}

# =========================
# Rimozione file eseguibile
# =========================

Write-Host ">>> Removing executable..."

if (Test-Path $TargetExecutablePath) {
    try {
        Remove-Item -Path $TargetExecutablePath -Force -ErrorAction Stop
        Write-Host "    Executable removed: $TargetExecutablePath" -ForegroundColor Green
    } catch {
        Write-Host "    WARNING: Could not remove executable: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    Executable not found (already removed)" -ForegroundColor Gray
}

# =========================
# Rimozione directory installazione
# =========================

Write-Host ">>> Removing installation directory..."

if (Test-Path $InstallDirectory) {
    try {
        # Verifica se la cartella è vuota
        $remainingItems = Get-ChildItem -Path $InstallDirectory -Force -ErrorAction SilentlyContinue

        if ($remainingItems.Count -eq 0) {
            Remove-Item -Path $InstallDirectory -Force -ErrorAction Stop
            Write-Host "    Installation directory removed" -ForegroundColor Green
        } else {
            Write-Host "    WARNING: Installation directory not empty, keeping it" -ForegroundColor Yellow
            Write-Host "    Remaining items: $($remainingItems.Count)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    WARNING: Could not remove directory: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    Installation directory not found (already removed)" -ForegroundColor Gray
}

# =========================
# Gestione log directory
# =========================

Write-Host ">>> Checking log directory..."

if (Test-Path $LogDirectory) {
    $logFiles = Get-ChildItem -Path $LogDirectory -File -ErrorAction SilentlyContinue

    if ($logFiles.Count -gt 0) {
        Write-Host "    Log directory contains $($logFiles.Count) file(s)" -ForegroundColor Yellow
        Write-Host "    Keeping log directory: $LogDirectory" -ForegroundColor Yellow
        Write-Host "    (You can manually delete it if you want to remove logs)" -ForegroundColor Gray
    } else {
        try {
            Remove-Item -Path $LogDirectory -Recurse -Force -ErrorAction Stop

            # Prova a rimuovere anche la parent directory se vuota
            $parentDir = Split-Path $LogDirectory -Parent
            if ((Test-Path $parentDir) -and ((Get-ChildItem $parentDir -Force).Count -eq 0)) {
                Remove-Item -Path $parentDir -Force -ErrorAction SilentlyContinue
            }

            Write-Host "    Log directory removed" -ForegroundColor Green
        } catch {
            Write-Host "    WARNING: Could not remove log directory: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "    Log directory not found" -ForegroundColor Gray
}

# =========================
# Conferma finale
# =========================

Write-Host ""
Write-Host "UNINSTALLATION COMPLETED" -ForegroundColor Green
Write-Host ""
Write-Host "FolderTextMerger has been removed from your system." -ForegroundColor White
Write-Host ""
Write-Host "NOTE: You may need to restart Windows Explorer to see changes in the context menu." -ForegroundColor Yellow
Write-Host "      (Task Manager → Windows Explorer → Restart)" -ForegroundColor Gray
Write-Host ""
