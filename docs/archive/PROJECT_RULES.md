# FolderTextMerger - Project Rules

## Core Rule: Centralized Extension Configuration

**CRITICAL**: All supported file extensions MUST be defined in ONE place and used everywhere.

### Single Source of Truth
**File**: [config/supported_extensions.txt](config/supported_extensions.txt)

This file contains ALL file extensions that FolderTextMerger can merge.

### Where This Config is Used

1. **Python Application** (`src/FolderTextMerger.py`)
   - Hardcoded `SUPPORTED_EXTENSIONS` set
   - **TODO**: Refactor to read from config file

2. **PowerShell Installer** (`scripts/installer.ps1`)
   - ✅ Reads from config file
   - Registers Windows context menu for each extension

3. **PowerShell Uninstaller** (`scripts/uninstaller.ps1`)
   - ✅ Reads from config file
   - Removes all registered context menu entries

4. **Documentation** (README, help files)
   - Should reference config file as source

### Supported Extensions (65 total)

#### Text Documents (6)
`.txt`, `.log`, `.md`, `.rst`, `.adoc`, `.asciidoc`

#### Markup Languages (7)
`.xml`, `.xsd`, `.xsl`, `.xslt`, `.html`, `.htm`, `.svg`

#### Data Formats (8)
`.json`, `.jsonc`, `.json5`, `.yaml`, `.yml`, `.csv`, `.tsv`

#### Configuration Files (5)
`.properties`, `.ini`, `.cfg`, `.conf`, `.toml`

#### Python (2)
`.py`, `.pyw`

#### JavaScript/TypeScript (6)
`.js`, `.mjs`, `.cjs`, `.ts`, `.tsx`, `.jsx`

#### C/C++/Java (5)
`.java`, `.c`, `.h`, `.cpp`, `.hpp`

#### Other Programming Languages (11)
`.cs`, `.go`, `.rs`, `.kt`, `.kts`, `.swift`, `.dart`, `.php`, `.rb`, `.scala`, `.groovy`

#### Shell Scripts (5)
`.sh`, `.bash`, `.bat`, `.cmd`, `.ps1`

#### Database (1)
`.sql`

#### LaTeX (3)
`.tex`, `.latex`, `.bib`

#### Patches (2)
`.diff`, `.patch`

#### Rich Text (1)
`.rtf`

---

## Context Menu Registration

The installer registers **4 different context menu locations**:

### 1. Folder Context Menu
- **Trigger**: Right-click on a folder
- **Registry**: `HKCU:\Software\Classes\Directory\shell\FolderTextMerger`
- **Display**: "Folder2Text - Extract text from folder"
- **Action**: Merge all supported files in that folder

### 2. Folder Background Menu
- **Trigger**: Right-click in empty space inside a folder
- **Registry**: `HKCU:\Software\Classes\Directory\Background\shell\FolderTextMerger`
- **Display**: "Folder2Text - Extract text from folder"
- **Action**: Merge all supported files in current folder

### 3. File Type Menus (65 extensions)
- **Trigger**: Right-click on a `.txt`, `.py`, `.md`, etc. file
- **Registry**: `HKCU:\Software\Classes\SystemFileAssociations\{ext}\shell\FolderTextMerger`
- **Display**: "Folder2Text - Extract text from folder"
- **Action**: Merge the selected file with others in same folder

### 4. Multi-Selection Menu
- **Trigger**: Select multiple files/folders, then right-click
- **Registry**: `HKCU:\Software\Classes\*\shell\FolderTextMerger`
- **Display**: "Merge selected text files"
- **Action**: Merge all selected items

---

## Icon Requirements

### Icon File
- **Location**: [assets/app_icon.ico](assets/app_icon.ico)
- **Format**: Windows ICO with multiple resolutions
- **Resolutions**: 256×256, 128×128, 64×64, 48×48, 32×32, 16×16
- **Embedded**: Yes, in executable via PyInstaller

### Registry Icon Format
- **Format**: `{path_to_exe},0`
- **Example**: `C:\Users\...\FolderTextMerger.exe,0`
- **Note**: The `,0` suffix tells Windows to extract icon resource #0 from the EXE

---

## Adding New Extensions

### Step-by-Step Process

1. **Add to config file**:
   ```
   # Edit: config/supported_extensions.txt
   .newext
   ```

2. **Update Python code** (TODO: automate this):
   ```python
   # Edit: src/FolderTextMerger.py
   SUPPORTED_EXTENSIONS: Set[str] = {
       # ... existing extensions ...
       ".newext",
   }
   ```

3. **Rebuild and reinstall**:
   ```powershell
   .\scripts\rebuild-install.ps1
   ```

4. **Verify**:
   - Right-click on a `.newext` file
   - Should see "Folder2Text - Extract text from folder" menu

---

## Version Management

### Version File
- **Location**: `src/FolderTextMerger.py` (line 1)
- **Format**: `VERSION = "1.1.0-rc6"`
- **Auto-increment**: `rebuild-install.ps1` increments rc number

### Build Process
```powershell
# Full rebuild + install
.\scripts\rebuild-install.ps1

# Manual steps
pyinstaller FolderTextMerger.spec
.\scripts\installer.ps1
```

---

## Testing Checklist

After any changes, verify:

- [ ] Icon visible in all 4 context menu locations
- [ ] Right-click on folder works
- [ ] Right-click on `.txt` file works
- [ ] Right-click on `.py` file works
- [ ] Multi-select (2+ files) works
- [ ] Background menu (inside folder) works
- [ ] Output file created correctly
- [ ] Logs written to AppData

---

## Future Improvements

### TODO: Refactor Python to Read Config
Currently Python has hardcoded extensions. Should read from config:

```python
# Proposed refactor
CONFIG_FILE = Path(__file__).parent.parent / "config" / "supported_extensions.txt"

def load_supported_extensions() -> Set[str]:
    with open(CONFIG_FILE) as f:
        return {
            line.strip()
            for line in f
            if line.strip() and line.strip().startswith(".")
        }

SUPPORTED_EXTENSIONS = load_supported_extensions()
```

### TODO: Installer Wizard
Create `.msi` installer with GUI for:
- Custom install location
- Desktop shortcut option
- Start menu entry
- Uninstaller entry in Control Panel

---

## Critical Rules Summary

1. ✅ **Single source of truth**: `config/supported_extensions.txt`
2. ✅ **Always use `,0` suffix** for icon paths in registry
3. ✅ **4 context menu locations**: folder, background, files, multi-select
4. ✅ **65 extensions supported** (as of v1.1.0-rc6)
5. ⚠️  **Python needs refactor** to read config (currently hardcoded)
6. ✅ **Icon embedded** in EXE via PyInstaller

---

## Logging System Rules

### Log Location
**Path**: `C:\Users\{username}\AppData\Local\FolderTextMerger\logs\`

### Log Behavior
1. **Rotation**: Daily (TimedRotatingFileHandler with `when="D"`)
2. **Retention**: 30 days (`LOG_RETENTION_DAYS = 30`)
3. **Auto-cleanup**: Files older than 30 days are automatically deleted
4. **Log file**: `debug.log` (current day) + `debug.log.YYYY-MM-DD` (older days)

### Development Mode
**Constant**: `DEV_MODE` in `src/FolderTextMerger.py`

```python
DEV_MODE = False  # Production mode (default)
DEV_MODE = True   # Development mode (verbose file logs)
```

### What Gets Logged

#### Always Logged (Production + Dev)
- ✅ Application start/stop
- ✅ Arguments received
- ✅ Total files merged (summary)
- ✅ Errors and exceptions
- ✅ Critical operations (file write, temp file handling)
- ✅ Final output file path

#### Only in DEV_MODE
- 🔧 Individual file processing ("Merged file: xyz.txt")
- 🔧 Skipped files (unsupported, binary, oversized)
- 🔧 Detailed file validation steps

### Log Format
```
YYYY-MM-DD HH:MM:SS,mmm - LEVEL - Message
```

Example:
```
2026-01-08 15:30:45,123 - INFO - Process completed successfully: output.txt
2026-01-08 15:30:45,124 - ERROR - Error processing file test.bin: UnicodeDecodeError
```

### Why This Design?
- **30 days retention**: Enough for debugging intermittent issues
- **DEV_MODE toggle**: Prevents log bloat in production (users don't need file-by-file logs)
- **Always log errors**: Critical for remote debugging
- **Auto-cleanup**: No manual maintenance needed

### Debugging Issues
1. **Enable DEV_MODE**: Set `DEV_MODE = True` in source
2. **Rebuild**: `.\scripts\rebuild-install.ps1`
3. **Reproduce issue**
4. **Check logs**: Open `C:\Users\{user}\AppData\Local\FolderTextMerger\logs\debug.log`
5. **Disable DEV_MODE**: Set back to `False` for production

---

## Silent Operation (No Console Window)

### Configuration
**File**: `FolderTextMerger.spec`
```python
console=False  # Windowed mode (no console flash)
```

### User Notification
- **Method**: Windows 10 Toast Notification
- **Library**: `win10toast`
- **Message**: "Merged X files successfully! output-filename.txt"
- **Duration**: 5 seconds
- **Threaded**: Yes (non-blocking)

### Fallback
If toast library fails, operation completes silently (no notification).

---

**Last Updated**: 2026-01-08
**Version**: 1.1.0-rc8
