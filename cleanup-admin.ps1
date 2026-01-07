# RICHIEDE PRIVILEGI AMMINISTRATORE
# Script per rimuovere voci obsolete dal menu contestuale

# Verifica se sta girando come admin
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
$IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Host "ERRORE: Questo script richiede privilegi di amministratore" -ForegroundColor Red
    Write-Host ""
    Write-Host "Rilancia PowerShell come amministratore e riesegui lo script" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PULIZIA MENU CONTESTUALE (ADMIN)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backupFolder = "C:\Users\umber\Desktop\FolderTextMerger\registry-backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Lista COMPLETA voci da rimuovere
$keysToRemove = @(
    "HKEY_CLASSES_ROOT\Directory\shell\FolderTextMerger",
    "HKEY_CURRENT_USER\Software\Classes\Directory\shell\FolderTextMerger",
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Crea Lista di File",
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Crea Lista File",
    "HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Crea Lista File",
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Unisci e Copia Testi",
    "HKEY_CLASSES_ROOT\Directory\Background\shell\Unisci e Esporta Testi",
    "HKEY_CLASSES_ROOT\*\shell\Unisci e Copia Testi (Multipli)",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Unisci e Copia Testi (Multipli)",
    "HKEY_CLASSES_ROOT\*\shell\Unisci e Esporta Testi (Multipli)",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Unisci e Esporta Testi (Multipli)",
    "HKEY_CLASSES_ROOT\*\shell\Rinomina in camelCase con Trattini",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Rinomina in camelCase con Trattini",
    "HKEY_CLASSES_ROOT\*\shell\Rinomina in camelCase con Trattini (Multipli)",
    "HKEY_CURRENT_USER\Software\Classes\*\shell\Rinomina in camelCase con Trattini (Multipli)"
)

$removed = 0
$notFound = 0

foreach ($key in $keysToRemove) {
    $keyName = $key.Split('\')[-1]

    Write-Host "Controllo: $keyName" -ForegroundColor Yellow

    # Backup
    $backupFile = Join-Path $backupFolder "$timestamp-$($keyName -replace '[\\/:*?""<>|()\[\] ]', '_').reg"
    $result = reg export "$key" "$backupFile" /y 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Trovata - backup salvato" -ForegroundColor Green

        # Rimuovi con reg delete (più affidabile di Remove-Item)
        $result = reg delete "$key" /f 2>$null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK RIMOSSA" -ForegroundColor Green
            $removed++
        } else {
            Write-Host "  ERRORE durante rimozione" -ForegroundColor Red
        }
    } else {
        $notFound++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIEPILOGO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Chiavi rimosse: $removed" -ForegroundColor Green
Write-Host "Chiavi non trovate: $notFound" -ForegroundColor Gray
Write-Host ""

if ($removed -gt 0) {
    Write-Host "Backup salvati in: $backupFolder" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Riavvio Esplora Risorse..." -ForegroundColor Yellow

    taskkill /F /IM explorer.exe 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    Start-Process explorer.exe

    Write-Host "OK Esplora Risorse riavviato" -ForegroundColor Green
}

Write-Host ""
Write-Host "Operazione completata" -ForegroundColor Green
Write-Host ""
Pause
