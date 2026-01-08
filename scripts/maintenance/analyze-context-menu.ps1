# Script per analizzare voci menu contestuale Windows

Write-Host "=== MENU CONTESTUALE FILE (click destro su file) ===" -ForegroundColor Cyan
Write-Host ""

# Voci per TUTTI i file
$fileContextPaths = @(
    "Registry::HKEY_CLASSES_ROOT\*\shell",
    "Registry::HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers"
)

$fileEntries = @()

foreach ($path in $fileContextPaths) {
    if (Test-Path $path) {
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $name = $item.PSChildName
            $displayName = $name

            # Try to get friendly name
            $defaultValue = (Get-ItemProperty -Path $item.PSPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
            if ($defaultValue) {
                $displayName = "$name ($defaultValue)"
            }

            $fileEntries += [PSCustomObject]@{
                Name = $name
                DisplayName = $displayName
                Type = if ($path -like "*shellex*") { "Shell Extension" } else { "Shell Command" }
                Path = $item.PSPath
            }
        }
    }
}

Write-Host "Voci trovate per FILE:" -ForegroundColor Yellow
$fileEntries | Sort-Object Name | Format-Table -AutoSize Name, Type

Write-Host ""
Write-Host "=== MENU CONTESTUALE CARTELLE (click destro su folder) ===" -ForegroundColor Cyan
Write-Host ""

# Voci per cartelle
$folderContextPaths = @(
    "Registry::HKEY_CLASSES_ROOT\Directory\shell",
    "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell",
    "Registry::HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers"
)

$folderEntries = @()

foreach ($path in $folderContextPaths) {
    if (Test-Path $path) {
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $name = $item.PSChildName
            $displayName = $name

            # Try to get friendly name
            $defaultValue = (Get-ItemProperty -Path $item.PSPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
            if ($defaultValue) {
                $displayName = "$name ($defaultValue)"
            }

            $location = "Folder"
            if ($path -like "*Background*") {
                $location = "Folder Background"
            }

            $folderEntries += [PSCustomObject]@{
                Name = $name
                DisplayName = $displayName
                Location = $location
                Type = if ($path -like "*shellex*") { "Shell Extension" } else { "Shell Command" }
                Path = $item.PSPath
            }
        }
    }
}

Write-Host "Voci trovate per CARTELLE:" -ForegroundColor Yellow
$folderEntries | Sort-Object Location, Name | Format-Table -AutoSize Name, Location, Type

# Export to file for easier review
$outputPath = "C:\Users\umber\Desktop\FolderTextMerger\context-menu-analysis.txt"
$output = @"
========================================
ANALISI MENU CONTESTUALE WINDOWS
Data: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

FILE CONTEXT MENU ENTRIES:
--------------------------
$($fileEntries | Sort-Object Name | Format-Table -AutoSize | Out-String)

FOLDER CONTEXT MENU ENTRIES:
----------------------------
$($folderEntries | Sort-Object Location, Name | Format-Table -AutoSize | Out-String)

DETTAGLI PERCORSI REGISTRO:
---------------------------

FILE ENTRIES (percorsi completi):
"@

foreach ($entry in ($fileEntries | Sort-Object Name)) {
    $output += "`n$($entry.Name) -> $($entry.Path)"
}

$output += "`n`nFOLDER ENTRIES (percorsi completi):"

foreach ($entry in ($folderEntries | Sort-Object Name)) {
    $output += "`n$($entry.Name) -> $($entry.Path)"
}

$output | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host ""
Write-Host "Analisi salvata in: $outputPath" -ForegroundColor Green
