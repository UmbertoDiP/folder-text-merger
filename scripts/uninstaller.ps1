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

# Load supported extensions for cleanup
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ConfigFile = Join-Path $ProjectRoot "config\supported_extensions.txt"

$SupportedExtensions = @()
if (Test-Path $ConfigFile) {
    $SupportedExtensions = @(
        Get-Content $ConfigFile |
        Where-Object { $_ -match '^\.[a-z0-9]+$' } |
        ForEach-Object { $_.Trim() }
    )
    Write-Host "    Loaded $($SupportedExtensions.Count) extensions for cleanup" -ForegroundColor Cyan
}

$removedCount = 0

# 1. Remove folder context menu
$FolderMenuKey = Join-Path $RegistryBase "Directory\shell\$ApplicationName"
if (Test-Path $FolderMenuKey) {
    try {
        Remove-Item -Path $FolderMenuKey -Recurse -Force -ErrorAction Stop
        Write-Host "    Folder menu removed" -ForegroundColor Green
        $removedCount++
    } catch {
        Write-Host "    WARNING: Folder menu: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 2. Remove background context menu
$BackgroundMenuKey = Join-Path $RegistryBase "Directory\Background\shell\$ApplicationName"
if (Test-Path $BackgroundMenuKey) {
    try {
        Remove-Item -Path $BackgroundMenuKey -Recurse -Force -ErrorAction Stop
        Write-Host "    Background menu removed" -ForegroundColor Green
        $removedCount++
    } catch {
        Write-Host "    WARNING: Background menu: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 3. Remove file type menus
foreach ($ext in $SupportedExtensions) {
    $FileTypeMenuKey = Join-Path $RegistryBase "SystemFileAssociations\$ext\shell\$ApplicationName"
    if (Test-Path $FileTypeMenuKey) {
        try {
            Remove-Item -Path $FileTypeMenuKey -Recurse -Force -ErrorAction Stop
            $removedCount++
        } catch {
            Write-Host "    WARNING: Failed to remove $ext menu" -ForegroundColor Yellow
        }
    }
}
if ($SupportedExtensions.Count -gt 0) {
    Write-Host "    File type menus removed ($($SupportedExtensions.Count) extensions)" -ForegroundColor Green
}

# 4. Remove multi-selection menu
$MultiSelectMenuKey = Join-Path $RegistryBase "*\shell\$ApplicationName"
if (Test-Path $MultiSelectMenuKey) {
    try {
        Remove-Item -Path $MultiSelectMenuKey -Recurse -Force -ErrorAction Stop
        Write-Host "    Multi-selection menu removed" -ForegroundColor Green
        $removedCount++
    } catch {
        Write-Host "    WARNING: Multi-selection menu: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 5. Legacy HKCR cleanup
$HKCRContextMenu = "Registry::HKEY_CLASSES_ROOT\Directory\shell\$ApplicationName"
if (Test-Path $HKCRContextMenu) {
    try {
        Remove-Item -Path $HKCRContextMenu -Recurse -Force -ErrorAction Stop
        Write-Host "    Legacy menu removed (HKCR)" -ForegroundColor Green
        $removedCount++
    } catch {
        Write-Host "    WARNING: Legacy menu: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "    Total menus removed: $removedCount" -ForegroundColor Cyan

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
