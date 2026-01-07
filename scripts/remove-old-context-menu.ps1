# Script per rimuovere voci obsolete dal menu contestuale
# Crea backup automatico prima di eliminare

$ErrorActionPreference = "Continue"

# Voci da rimuovere (Background\shell)
$toRemove = @(
    "Crea Lista di File",
    "Crea Lista File",
    "Unisci e Copia Testi",
    "Unisci e Esporta Testi"
)

$basePath = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell"
$backupFolder = "C:\Users\umber\Desktop\FolderTextMerger\registry-backup"

# Crea cartella backup se non esiste
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Host "Cartella backup creata: $backupFolder" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIMOZIONE VOCI MENU CONTESTUALE OBSOLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$removed = 0
$notFound = 0

foreach ($entry in $toRemove) {
    $regPath = Join-Path $basePath $entry

    Write-Host "Elaborazione: '$entry'" -ForegroundColor Yellow

    if (Test-Path $regPath) {
        # Backup della chiave prima di rimuoverla
        $backupFile = Join-Path $backupFolder "$timestamp-$($entry -replace '[\\/:*?""<>|]', '_').reg"

        # Export registry key for backup
        $regCommand = "reg export `"HKEY_CLASSES_ROOT\Directory\Background\shell\$entry`" `"$backupFile`" /y"
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $regCommand" -Wait -NoNewWindow -RedirectStandardOutput "nul" 2>&1 | Out-Null

        if (Test-Path $backupFile) {
            Write-Host "  ✓ Backup salvato: $backupFile" -ForegroundColor Green
        }

        # Rimuovi la chiave
        try {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ RIMOSSA con successo" -ForegroundColor Green
            $removed++
        } catch {
            Write-Host "  ✗ ERRORE durante rimozione: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  - Non trovata (già rimossa o non esiste)" -ForegroundColor Gray
        $notFound++
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIEPILOGO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Voci rimosse:    $removed" -ForegroundColor Green
Write-Host "Voci non trovate: $notFound" -ForegroundColor Gray
Write-Host ""

if ($removed -gt 0) {
    Write-Host "⚠️  IMPORTANTE: Per vedere le modifiche, riavvia Esplora Risorse:" -ForegroundColor Yellow
    Write-Host "   - Apri Task Manager (Ctrl+Shift+Esc)" -ForegroundColor White
    Write-Host "   - Trova 'Esplora risorse' o 'Windows Explorer'" -ForegroundColor White
    Write-Host "   - Click destro → Riavvia" -ForegroundColor White
    Write-Host ""
    Write-Host "Backup salvati in: $backupFolder" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Operazione completata!" -ForegroundColor Green
Write-Host ""
