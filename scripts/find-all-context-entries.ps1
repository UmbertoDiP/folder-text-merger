# Script per trovare TUTTE le voci di menu contestuale nel registro

$entries = @()

# Location comuni per voci menu contestuale
$locations = @(
    "Registry::HKEY_CLASSES_ROOT\*\shell",
    "Registry::HKEY_CLASSES_ROOT\AllFilesystemObjects\shell",
    "Registry::HKEY_CLASSES_ROOT\Directory\shell",
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell",
    "Registry::HKEY_CLASSES_ROOT\Folder\shell",
    "Registry::HKEY_CURRENT_USER\Software\Classes\*\shell",
    "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\shell",
    "Registry::HKEY_CURRENT_USER\Software\Classes\Directory\Background\shell",
    "Registry::HKEY_LOCAL_MACHINE\Software\Classes\*\shell",
    "Registry::HKEY_LOCAL_MACHINE\Software\Classes\Directory\shell"
)

Write-Host "Scansione completa menu contestuale..." -ForegroundColor Cyan
Write-Host ""

foreach ($location in $locations) {
    if (Test-Path $location) {
        $items = Get-ChildItem -Path $location -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            $name = $item.PSChildName

            # Filtra solo le voci che ci interessano (quelle evidenziate)
            if ($name -like "*camelCase*" -or
                $name -like "*Unisci*" -or
                $name -like "*FolderTextMerger*" -or
                $name -like "*Crea Lista*") {

                $entries += [PSCustomObject]@{
                    Name = $name
                    Location = $location
                    FullPath = $item.PSPath
                }

                Write-Host "TROVATA: $name" -ForegroundColor Yellow
                Write-Host "  Location: $location" -ForegroundColor Gray
                Write-Host ""
            }
        }
    }
}

if ($entries.Count -eq 0) {
    Write-Host "Nessuna voce trovata." -ForegroundColor Green
} else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "RIEPILOGO: $($entries.Count) voci trovate" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $entries | Format-Table -AutoSize Name, Location
}

# Salva risultati
$outputFile = "C:\Users\umber\Desktop\FolderTextMerger\found-context-entries.txt"
$entries | Format-List Name, Location, FullPath | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Dettagli salvati in: $outputFile" -ForegroundColor Cyan
