# Script temporaneo per rimuovere voce FolderTextMerger obsoleta dal menu contestuale

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIMOZIONE FolderTextMerger (voce obsoleta)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$backupFolder = "C:\Users\umber\Desktop\FolderTextMerger\registry-backup"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Verifica se esiste già la cartella backup
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

# Chiavi possibili (user e system)
$registryPaths = @(
    @{
        Base = "Registry::HKEY_CLASSES_ROOT\Directory\shell\FolderTextMerger"
        Name = "HKCR (System/Current User)"
        ExportPath = "HKEY_CLASSES_ROOT\Directory\shell\FolderTextMerger"
    },
    @{
        Base = "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell\FolderTextMerger"
        Name = "HKCU (Current User)"
        ExportPath = "HKEY_CURRENT_USER\Software\Classes\Directory\shell\FolderTextMerger"
    },
    @{
        Base = "Registry::HKEY_LOCAL_MACHINE\Software\Classes\Directory\shell\FolderTextMerger"
        Name = "HKLM (Local Machine)"
        ExportPath = "HKEY_LOCAL_MACHINE\Software\Classes\Directory\shell\FolderTextMerger"
    }
)

$removed = 0

foreach ($regInfo in $registryPaths) {
    $regPath = $regInfo.Base
    $name = $regInfo.Name
    $exportPath = $regInfo.ExportPath

    Write-Host "Verifica: $name" -ForegroundColor Yellow

    if (Test-Path $regPath) {
        Write-Host "  Trovata!" -ForegroundColor Green

        # Backup
        $backupFile = Join-Path $backupFolder "$timestamp-FolderTextMerger-$($name -replace '[\\/:*?""<>|() ]', '_').reg"

        $regCommand = "reg export `"$exportPath`" `"$backupFile`" /y"
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $regCommand" -Wait -NoNewWindow -RedirectStandardOutput "nul" 2>&1 | Out-Null

        if (Test-Path $backupFile) {
            Write-Host "  ✓ Backup salvato" -ForegroundColor Green
        }

        # Rimuovi
        try {
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "  ✓ RIMOSSA con successo" -ForegroundColor Green
            $removed++
        } catch {
            Write-Host "  ✗ ERRORE: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  - Non trovata" -ForegroundColor Gray
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "RIEPILOGO" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Chiavi rimosse: $removed" -ForegroundColor Green
Write-Host ""

if ($removed -gt 0) {
    Write-Host "⚠️  Riavvia Esplora Risorse per vedere le modifiche:" -ForegroundColor Yellow
    Write-Host "   Task Manager → Esplora risorse → Riavvia" -ForegroundColor White
    Write-Host ""
    Write-Host "Backup salvati in: $backupFolder" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Operazione completata!" -ForegroundColor Green
Write-Host ""
