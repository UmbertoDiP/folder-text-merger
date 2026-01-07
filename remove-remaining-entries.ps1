# RICHIEDE ADMIN - Rimozione voci rimanenti

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
Write-Host "RIMOZIONE VOCI RIMANENTI" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backupFolder = "C:\Users\umber\Desktop\FolderTextMerger\registry-backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Voci ancora presenti da rimuovere
$keysToRemove = @(
    "HKEY_CURRENT_USER\Software\Classes\*\shell\FolderTextMerger",
    "HKEY_CLASSES_ROOT\*\shell\FolderTextMerger",
    # Aggiungo anche altre location possibili di FolderTextMerger
    "HKEY_CLASSES_ROOT\AllFilesystemObjects\shell\FolderTextMerger",
    "HKEY_CURRENT_USER\Software\Classes\AllFilesystemObjects\shell\FolderTextMerger"
)

Write-Host "Cerco e rimuovo FolderTextMerger da tutte le location..." -ForegroundColor Yellow
Write-Host ""

$removed = 0

foreach ($key in $keysToRemove) {
    $keyName = $key.Split('\')[-1]
    $shortPath = $key.Substring($key.IndexOf('\') + 1)

    # Prova backup
    $backupFile = Join-Path $backupFolder "$timestamp-FolderTextMerger-$($shortPath -replace '[\\/:*?""<>|() ]', '_').reg"
    $result = reg export "$key" "$backupFile" /y 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Trovata: $key" -ForegroundColor Green
        Write-Host "  Backup: OK" -ForegroundColor Gray

        # Rimuovi
        $result = reg delete "$key" /f 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  Rimossa: OK" -ForegroundColor Green
            $removed++
        } else {
            Write-Host "  Rimossa: ERRORE" -ForegroundColor Red
        }
    }

    Write-Host ""
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
}

Write-Host "Operazione completata" -ForegroundColor Green
Write-Host ""
Write-Host "NOTA: Se vedi ancora voci 'Copia Contenuto', 'Copia Nome File', etc." -ForegroundColor Yellow
Write-Host "queste sono utility separate. Dimmi quali vuoi rimuovere." -ForegroundColor Yellow
Write-Host ""
Pause
