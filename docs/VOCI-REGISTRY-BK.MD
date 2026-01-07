
📋 Elenco Voci Registry Rimosse dall'Uninstaller
1. Folder Menu (1 voce)
HKCU:\Software\Classes\Directory\shell\FolderTextMerger
Quando: click destro su una cartella
2. Background Menu (1 voce)
HKCU:\Software\Classes\Directory\Background\shell\FolderTextMerger
Quando: click destro nello spazio vuoto dentro una cartella
3. File Type Menus (65 voci - una per estensione)
HKCU:\Software\Classes\SystemFileAssociations\.txt\shell\FolderTextMerger
HKCU:\Software\Classes\SystemFileAssociations\.log\shell\FolderTextMerger
HKCU:\Software\Classes\SystemFileAssociations\.md\shell\FolderTextMerger
... (e così via per tutte le 65 estensioni)
4. Multi-Selection Menu (1 voce)
HKCU:\Software\Classes\*\shell\FolderTextMerger
Quando: selezioni più file/cartelle e fai click destro
5. Legacy HKCR (1 voce fallback)
HKEY_CLASSES_ROOT\Directory\shell\FolderTextMerger
Per compatibilità con installazioni vecchie
Totale: 69 voci registry (1 + 1 + 65 + 1 + 1)

Ora lanciamo la reinstallazione completa: