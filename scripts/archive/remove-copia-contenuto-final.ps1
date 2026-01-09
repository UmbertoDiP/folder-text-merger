# RICHIEDE ADMIN - Trova e rimuove "Copia Contenuto"

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
$IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "ERRORE: Richiesti privilegi amministratore" -ForegroundColor Red
    Pause
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIMOZIONE COPIA CONTENUTO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backupFolder = "C:\Users\umber\Desktop\FolderTextMerger\registry-backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Cerca in TUTTE le possibili location
$keysToTry = @(
    "HKEY_CLASSES_ROOT\*\shell\Copia Contenuto",
    "HKEY_CLASSES_ROOT\AllFilesystemObjects\shell\Copia Contenuto",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Copia Contenuto",
    "HKEY_LOCAL_MACHINE\Software\Classes\*\shell\Copia Contenuto",
    # Aggiungo anche le altre voci copia per sicurezza
    "HKEY_CLASSES_ROOT\*\shell\Copia Nome File",
    "HKEY_CLASSES_ROOT\*\shell\Copia Nome File con Estensione",
    "HKEY_CLASSES_ROOT\*\shell\Copia Nomi File Selezionati con Estensione",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Copia Nome File",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Copia Nome File con Estensione",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Copia Nomi File Selezionati con Estensione"
)

Write-Host "Cercando tutte le voci 'Copia'..." -ForegroundColor Yellow
Write-Host ""

$removed = 0

foreach ($key in $keysToTry) {
    # Prova esportazione (verifica esistenza)
    $backupFile = Join-Path $backupFolder "$timestamp-$($key.Split('\')[-1] -replace ' ', '_').reg"
    $null = reg export "$key" "$backupFile" /y 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "TROVATA: $key" -ForegroundColor Green

        # Rimuovi
        $null = reg delete "$key" /f 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK RIMOSSA" -ForegroundColor Green
            $removed++
        } else {
            Write-Host "  ERRORE durante rimozione" -ForegroundColor Red
        }

        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Chiavi rimosse: $removed" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($removed -gt 0) {
    Write-Host "Riavvio Esplora Risorse..." -ForegroundColor Yellow
    taskkill /F /IM explorer.exe 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Start-Process explorer.exe
    Write-Host "OK Riavviato" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backup salvati in: $backupFolder" -ForegroundColor Cyan
} else {
    Write-Host "Nessuna voce trovata. Possibili cause:" -ForegroundColor Yellow
    Write-Host "  - La voce ha un nome leggermente diverso" -ForegroundColor Gray
    Write-Host "  - E' in una location non standard" -ForegroundColor Gray
    Write-Host "  - E' gestita da un programma esterno" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Apri RegEdit e cerca manualmente 'Copia Contenuto'" -ForegroundColor Yellow
}

Write-Host ""
Pause
