# RICHIEDE ADMIN - Rimozione voci "Copia" dal menu contestuale

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
$IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "ERRORE: Richiesti privilegi amministratore" -ForegroundColor Red
    Write-Host "Rilancia PowerShell come amministratore" -ForegroundColor Yellow
    Pause
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIMOZIONE VOCI COPIA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backupFolder = "C:\Users\umber\Desktop\FolderTextMerger\registry-backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Voci da rimuovere - cercale in tutte le location possibili
$entriesToRemove = @(
    "Copia Contenuto",
    "Copia Nome File",
    "Copia Nome File con Estensione",
    "Copia Nomi File Selezionati con Estensione"
)

$locations = @(
    "HKEY_CLASSES_ROOT\*\shell",
    "HKEY_CLASSES_ROOT\AllFilesystemObjects\shell",
    "HKEY_CLASSES_ROOT\Directory\shell",
    "HKEY_CLASSES_ROOT\Directory\Background\shell",
    "HKEY_CURRENT_USER\Software\Classes\*\shell",
    "HKEY_CURRENT_USER\Software\Classes\AllFilesystemObjects\shell",
    "HKEY_CURRENT_USER\Software\Classes\Directory\shell",
    "HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell"
)

$removed = 0
$notFound = 0

foreach ($entry in $entriesToRemove) {
    Write-Host "Cercando: '$entry'" -ForegroundColor Yellow
    $foundInAnyLocation = $false

    foreach ($location in $locations) {
        $fullPath = "$location\$entry"

        # Prova backup
        $backupFile = Join-Path $backupFolder "$timestamp-$($entry -replace '[\\/:*?""<>|()\[\] ]', '_').reg"
        $result = reg export "$fullPath" "$backupFile" /y 2>$null

        if ($LASTEXITCODE -eq 0) {
            if (-not $foundInAnyLocation) {
                Write-Host "  Trovata in: $location" -ForegroundColor Green
                $foundInAnyLocation = $true
            } else {
                Write-Host "  Trovata anche in: $location" -ForegroundColor Green
            }

            Write-Host "    Backup: OK" -ForegroundColor Gray

            # Rimuovi
            $result = reg delete "$fullPath" /f 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Host "    Rimossa: OK" -ForegroundColor Green
                $removed++
            } else {
                Write-Host "    Rimossa: ERRORE" -ForegroundColor Red
            }
        }
    }

    if (-not $foundInAnyLocation) {
        Write-Host "  Non trovata" -ForegroundColor Gray
        $notFound++
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIEPILOGO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Chiavi rimosse: $removed" -ForegroundColor Green
Write-Host "Voci non trovate: $notFound" -ForegroundColor Gray
Write-Host ""

if ($removed -gt 0) {
    Write-Host "Backup salvati in: $backupFolder" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Riavvio Esplora Risorse..." -ForegroundColor Yellow
    taskkill /F /IM explorer.exe 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
    Write-Host "OK Riavviato" -ForegroundColor Green
}

Write-Host ""
Write-Host "Operazione completata" -ForegroundColor Green
Write-Host ""
Pause
