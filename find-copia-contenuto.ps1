# Cerca "Copia Contenuto" in TUTTE le location possibili

Write-Host "Cercando 'Copia Contenuto' nel registro..." -ForegroundColor Cyan
Write-Host ""

$searchPaths = @(
    "Registry::HKEY_CLASSES_ROOT\*\shell",
    "Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers",
    "Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shell",
    "Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers",
    "Registry::HKEY_CLASSES_ROOT\Directory\shell",
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell",
    "Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers",
    "Registry::HKEY_CLASSES_ROOT\Folder\shell",
    "Registry::HKEY_CURRENT_USER\Software\Classes\*\shell",
    "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell",
    "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell",
    "Registry::HKEY_LOCAL_MACHINE\Software\Classes\*\shell",
    "Registry::HKEY_LOCAL_MACHINE\Software\Classes\Directory\shell"
)

$found = @()

foreach ($basePath in $searchPaths) {
    if (Test-Path $basePath) {
        $items = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            if ($item.PSChildName -like "*Copia*") {
                $found += [PSCustomObject]@{
                    Name = $item.PSChildName
                    Path = $item.PSPath
                    Location = $basePath
                }

                Write-Host "TROVATA: $($item.PSChildName)" -ForegroundColor Green
                Write-Host "  Location: $basePath" -ForegroundColor Gray
                Write-Host "  Full path: $($item.PSPath)" -ForegroundColor Yellow
                Write-Host ""
            }
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host "Nessuna voce 'Copia' trovata" -ForegroundColor Red
} else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Totale voci trovate: $($found.Count)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}
