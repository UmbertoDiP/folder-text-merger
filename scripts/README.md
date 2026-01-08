# FolderTextMerger - Installation Scripts

## Main Scripts (Use These)

### installer.ps1
**Purpose**: Install FolderTextMerger and register context menu
**Usage**:
```powershell
.\installer.ps1
```
- Copies executable to installation directory
- Registers context menu for folders and files
- Creates log directory
- Works with or without admin privileges

### uninstaller.ps1
**Purpose**: Completely remove FolderTextMerger
**Usage**:
```powershell
.\uninstaller.ps1
```
- Removes executable from installation directory
- Removes all context menu entries
- Keeps logs directory (optional cleanup)

### rebuild-install.ps1
**Purpose**: Quick uninstall + reinstall (for development)
**Usage**:
```powershell
.\rebuild-install.ps1
```
- Runs uninstaller
- Rebuilds executable with PyInstaller
- Runs installer
- Useful during development cycles

---

## Support Folders

### `maintenance/`
Diagnostic and inspection scripts:
- `analyze-context-menu.ps1` - Analyze current context menu configuration
- `find-all-context-entries.ps1` - Find all FolderTextMerger registry entries
- `get-context-menu.ps1` - Quick check of context menu status

### `archive/`
Legacy cleanup scripts (rarely needed):
- `cleanup-all-obsolete-entries.ps1` - Remove old/broken entries
- `remove-foldertextmerger-context.ps1` - Remove only context menu
- `remove-old-context-menu.ps1` - Remove legacy entries

---

## Quick Reference

**First time installation**:
```powershell
cd scripts
.\installer.ps1
```

**Uninstall**:
```powershell
cd scripts
.\uninstaller.ps1
```

**Development cycle** (after code changes):
```powershell
cd scripts
.\rebuild-install.ps1
```

---

## Installation Paths

**Without admin privileges**:
- Executable: `%LOCALAPPDATA%\FolderTextMerger\FolderTextMerger.exe`
- Registry: `HKCU:\Software\Classes`

**With admin privileges**:
- Executable: `C:\Program Files\FolderTextMerger\FolderTextMerger.exe`
- Registry: `HKLM:\Software\Classes`

**Logs** (always):
- Location: `%LOCALAPPDATA%\FolderTextMerger\logs\`
