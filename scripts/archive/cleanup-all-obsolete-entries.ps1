# Script completo per rimuovere TUTTE le voci obsolete dal menu contestuale
# Include backup automatico

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PULIZIA COMPLETA MENU CONTESTUALE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backupFolder = "C:\Users\umber\Desktop\FolderTextMerger\registry-backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Lista COMPLETA di tutte le voci da rimuovere
$entriesToRemove = @(
    # Voci FolderTextMerger
    @{
        Name = "FolderTextMerger"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\Directory\shell\FolderTextMerger",
            "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\FolderTextMerger"
        )
    },

    # Voci obsolete Crea Lista
    @{
        Name = "Crea Lista di File"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Crea Lista di File"
        )
    },
    @{
        Name = "Crea Lista File"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Crea Lista File",
            "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell\Crea Lista File"
        )
    },

    # Voci obsolete Unisci
    @{
        Name = "Unisci e Copia Testi"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Unisci e Copia Testi"
        )
    },
    @{
        Name = "Unisci e Esporta Testi"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\Unisci e Esporta Testi"
        )
    },
    @{
        Name = "Unisci e Copia Testi (Multipli)"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\*\shell\Unisci e Copia Testi (Multipli)",
            "Registry::HKEY_CURRENT_USER\Software\Classes\*\shell\Unisci e Copia Testi (Multipli)"
        )
    },
    @{
        Name = "Unisci e Esporta Testi (Multipli)"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\*\shell\Unisci e Esporta Testi (Multipli)",
            "Registry::HKEY_CURRENT_USER\Software\Classes\*\shell\Unisci e Esporta Testi (Multipli)"
        )
    },

    # Voci camelCase
    @{
        Name = "Rinomina in camelCase con Trattini"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\*\shell\Rinomina in camelCase con Trattini",
            "Registry::HKEY_CURRENT_USER\Software\Classes\*\shell\Rinomina in camelCase con Trattini"
        )
    },
    @{
        Name = "Rinomina in camelCase con Trattini (Multipli)"
        Paths = @(
            "Registry::HKEY_CLASSES_ROOT\*\shell\Rinomina in camelCase con Trattini (Multipli)",
            "Registry::HKEY_CURRENT_USER\Software\Classes\*\shell\Rinomina in camelCase con Trattini (Multipli)"
        )
    }
)

$totalRemoved = 0
$totalNotFound = 0

foreach ($entry in $entriesToRemove) {
    $entryName = $entry.Name

    Write-Host "Elaborazione: '$entryName'" -ForegroundColor Yellow

    foreach ($regPath in $entry.Paths) {
        if (Test-Path $regPath) {
            Write-Host "  Trovata in: $regPath" -ForegroundColor Green

            # Backup
            $exportPath = $regPath -replace "Registry::", "" -replace "\\", "\"
            $backupFile = Join-Path $backupFolder "$timestamp-$($entryName -replace '[\\/:*?""<>|()\[\] ]', '_').reg"

            $regCommand = "reg export `"$exportPath`" `"$backupFile`" /y"
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c $regCommand" -Wait -NoNewWindow 2>&1 | Out-Null

            if (Test-Path $backupFile) {
                Write-Host "    OK Backup salvato" -ForegroundColor Green
            }

            # Rimuovi
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $regPath)) {
                Write-Host "    OK RIMOSSA" -ForegroundColor Green
                $totalRemoved++
            } else {
                Write-Host "    ERRORE impossibile rimuovere" -ForegroundColor Red
            }
        } else {
            $totalNotFound++
        }
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIEPILOGO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Chiavi rimosse: $totalRemoved" -ForegroundColor Green
Write-Host "Chiavi non trovate: $totalNotFound" -ForegroundColor Gray
Write-Host ""

if ($totalRemoved -gt 0) {
    Write-Host "IMPORTANTE: Riavvia Esplora Risorse per vedere le modifiche" -ForegroundColor Yellow
    Write-Host "Task Manager -> Esplora risorse -> Riavvia" -ForegroundColor White
    Write-Host ""
    Write-Host "Backup salvati in: $backupFolder" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Operazione completata" -ForegroundColor Green
Write-Host ""
