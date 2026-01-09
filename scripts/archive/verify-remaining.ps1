# Verifica voci ancora presenti nel registro

Write-Host "Verifica voci obsolete ancora presenti..." -ForegroundColor Cyan
Write-Host ""

$keysToCheck = @(
    @{Path = "HKCR:\Directory\shell\FolderTextMerger"; Name = "FolderTextMerger (Folder)"},
    @{Path = "HKCU:\Software\Classes\Directory\shell\FolderTextMerger"; Name = "FolderTextMerger (Folder HKCU)"},
    @{Path = "HKCR:\*\shell\FolderTextMerger"; Name = "FolderTextMerger (Files)"},
    @{Path = "HKCU:\Software\Classes\*\shell\FolderTextMerger"; Name = "FolderTextMerger (Files HKCU)"},
    @{Path = "HKCR:\Directory\Background\shell\Crea Lista di File"; Name = "Crea Lista di File"},
    @{Path = "HKCR:\Directory\Background\shell\Crea Lista File"; Name = "Crea Lista File"},
    @{Path = "HKCR:\Directory\Background\shell\Unisci e Copia Testi"; Name = "Unisci e Copia Testi"},
    @{Path = "HKCR:\Directory\Background\shell\Unisci e Esporta Testi"; Name = "Unisci e Esporta Testi"},
    @{Path = "HKCR:\*\shell\Unisci e Copia Testi (Multipli)"; Name = "Unisci e Copia Testi (Multipli)"},
    @{Path = "HKCR:\*\shell\Unisci e Esporta Testi (Multipli)"; Name = "Unisci e Esporta Testi (Multipli)"},
    @{Path = "HKCR:\*\shell\Rinomina in camelCase con Trattini"; Name = "Rinomina in camelCase con Trattini"},
    @{Path = "HKCR:\*\shell\Rinomina in camelCase con Trattini (Multipli)"; Name = "Rinomina in camelCase con Trattini (Multipli)"}
)

$stillPresent = @()

foreach ($key in $keysToCheck) {
    if (Test-Path $key.Path) {
        Write-Host "ANCORA PRESENTE: $($key.Name)" -ForegroundColor Red
        Write-Host "  Path: $($key.Path)" -ForegroundColor Gray
        $stillPresent += $key
        Write-Host ""
    }
}

Write-Host "========================================" -ForegroundColor Cyan
if ($stillPresent.Count -eq 0) {
    Write-Host "OK - Tutte le voci sono state rimosse!" -ForegroundColor Green
} else {
    Write-Host "ATTENZIONE: $($stillPresent.Count) voci ancora presenti" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Voci da rimuovere:" -ForegroundColor Yellow
    foreach ($key in $stillPresent) {
        Write-Host "  - $($key.Name)" -ForegroundColor White
    }
}
Write-Host "========================================" -ForegroundColor Cyan
