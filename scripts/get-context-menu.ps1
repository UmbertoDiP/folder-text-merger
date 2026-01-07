# Script semplificato per elencare voci menu contestuale

$output = @()

# FILE CONTEXT MENU
$output += "=== FILE CONTEXT MENU (click destro su file) ==="
$output += ""

$filePaths = @(
    "HKCR:\*\shell"
)

foreach ($basePath in $filePaths) {
    if (Test-Path $basePath) {
        $items = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $output += "- $($item.PSChildName)"
        }
    }
}

$output += ""
$output += "=== FOLDER CONTEXT MENU (click destro su cartella) ==="
$output += ""

$folderPaths = @(
    "HKCR:\Directory\shell",
    "HKCR:\Directory\Background\shell"
)

foreach ($basePath in $folderPaths) {
    if (Test-Path $basePath) {
        $location = if ($basePath -like "*Background*") { "[Background]" } else { "[Folder]" }
        $items = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $output += "- $location $($item.PSChildName)"
        }
    }
}

$output | Out-String
