# Folder2Text

[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.11-brightgreen.svg)]()

Merge multiple text files from folders into a single output file. Perfect for sharing code with AI assistants, code reviews, and documentation consolidation.

## 🎯 Features

- ✅ **60+ file types supported** - .txt, .py, .java, .js, .md, .cpp, .sql, .pdf, and more
- ✅ **PDF text extraction** - Extracts text from PDF documents (NEW in v1.0.11)
- ✅ **Smart selection validation** - Context menu with intelligent file type checking (NEW in v1.0.11)
- ✅ **Context menu integration** - Right-click folders/files in Windows Explorer
- ✅ **Smart binary detection** - Automatically skips binary files
- ✅ **Cross-drive support** - Works across different disk volumes (C:, D:, F:, etc.)
- ✅ **Silent execution** - No console windows (windowed mode)
- ✅ **Comprehensive summary** - File statistics and extraction report
- ✅ **Windows integration** - Registered in Programs & Features (Control Panel)
- ✅ **No admin rights required** - Installs to user profile

## 📦 Installation

### Method 1: EXE Installer (Recommended for End Users)

1. Download `Folder2Text-v1.0.9-Setup.exe`
2. Run installer (double-click)
3. Follow wizard → Next → Install → Finish
4. Done! 🎉

**Advantages:**

- ✅ Graphical wizard interface
- ✅ Automatic uninstaller in Control Panel
- ✅ No PowerShell execution required
- ✅ Progress bar and visual feedback

### Method 2: ZIP + PowerShell (Advanced Users)

1. Download `Folder2Text-v1.0.9-Setup.zip`
2. Extract all files
3. Right-click **INSTALL.ps1** → "Run with PowerShell"
4. Done! 🎉

**Advantages:**

- ✅ Portable installation
- ✅ No installer required
- ✅ Scriptable deployment

### Usage

**Option 1**: Right-click on a folder → "Folder2Text - Extract text from folder"

**Option 2**: Right-click inside a folder (on background) → "Folder2Text - Extract text from folder"

**Option 3**: Right-click on text files → "Folder2Text - Extract text from folder"

Output file format: `output-[foldername]-[timestamp].txt`

### Uninstallation

**Option 1** (Recommended): Settings > Apps > Apps & features > Folder2Text > Uninstall

**Option 2**: Right-click on **UNINSTALL.ps1** → "Run with PowerShell"

## 📊 Example Output

```
Process completed successfully!

Summary:
  Total files scanned: 895
  Files included: 360
  Files excluded: 535
  Output size: 27.89 MB
  Output location: C:\Users\username\Desktop\output-project-20260109-163734.txt
```

## 🛠️ Development

### Build from Source

```bash
# Clone repository
git clone https://github.com/UmbertoDiP/folder-text-merger.git
cd folder-text-merger

# Install dependencies
pip install pyinstaller

# Build executable
cd src
python -m PyInstaller --onefile --windowed --name=Folder2Text --icon=../assets/app_icon.ico Folder2Text.py

# Create distribution package
cd ../build
powershell -ExecutionPolicy Bypass -File create-distribution.ps1
```

### Project Structure

```
FolderTextMerger/
├── src/                              # Source code
│   ├── Folder2Text.py                # Main application (v1.0.9)
│   ├── Folder2Text.spec              # PyInstaller config
│   └── icon.png                      # Source icon (512x512)
├── assets/                           # Application assets
│   ├── app_icon.ico                  # Windows icon (multi-size)
│   └── app_icon.png                  # PNG backup
├── build/                            # Build system
│   ├── create-distribution.ps1       # ZIP distribution creator
│   ├── inno-setup/                   # Inno Setup EXE installer
│   │   ├── Folder2Text.iss           # Inno Setup script
│   │   ├── build-installer.ps1       # Build automation
│   │   └── output/                   # Generated EXE installers
│   ├── msix/                         # Microsoft Store package (future)
│   │   ├── AppxManifest.xml          # MSIX manifest (TBD)
│   │   ├── assets/                   # Store icons
│   │   └── output/                   # Generated MSIX packages
│   └── pyinstaller/                  # PyInstaller artifacts
├── config/                           # Configuration
│   └── supported_extensions.txt      # 60+ file types
├── distribution/                     # ZIP distribution files
│   ├── INSTALL.ps1                   # PowerShell installer
│   ├── UNINSTALL.ps1                 # PowerShell uninstaller
│   ├── scan-context-menu.ps1         # Diagnostic tool
│   └── clean-legacy-entries.ps1      # Cleanup utility
├── docs/                             # Documentation
│   ├── prompt-rigenerazione-rc-successiva.md  # Build guide
│   ├── inno-setup-guide.md           # EXE installer guide
│   ├── msix-package-guide.md         # Microsoft Store guide
│   └── LICENSE                       # MIT License
└── Folder2Text.exe                   # Production executable
```

## 📁 Important Paths

- **Executable**: `%LOCALAPPDATA%\Folder2Text\Folder2Text.exe`
- **Logs**: `%LOCALAPPDATA%\Folder2Text\logs\debug.log`
- **Config**: `%LOCALAPPDATA%\Folder2Text\config\`

Quick access:
```powershell
# Open log file
notepad $env:LOCALAPPDATA\Folder2Text\logs\debug.log

# Open installation folder
explorer $env:LOCALAPPDATA\Folder2Text
```

## 🐛 Troubleshooting

**Issue: Context menu not visible**
1. Restart Windows Explorer (Task Manager → Windows Explorer → Restart)
2. Reinstall: Extract ZIP and run INSTALL.ps1

**Issue: Application doesn't work**

1. Check logs: `%LOCALAPPDATA%\Folder2Text\logs\debug.log`
2. Verify executable exists
3. Reinstall from ZIP package

**Issue: Execution policy error**
1. Open PowerShell as Administrator
2. Run: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
3. Retry installation

## 🔒 Privacy

- ✅ All processing is local (no internet required)
- ✅ No data collection or telemetry
- ✅ Open source code

## 📄 License

MIT License - See [LICENSE](docs/LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Python 3.12.10
- Packaged with PyInstaller 6.17.0
- Tested on Windows 10/11

## 📞 Support

For issues or questions: [GitHub Issues](https://github.com/UmbertoDiP/folder-text-merger/issues)

## 🚀 Distribution Options

### Current (v1.0.9)

- **ZIP + PowerShell** - Available now (`Folder2Text-v1.0.9-Setup.zip`)
- **Inno Setup EXE** - Ready for build (see [docs/inno-setup-guide.md](docs/inno-setup-guide.md))

### Future

- **Microsoft Store (MSIX)** - Planned after beta testing (see [docs/msix-package-guide.md](docs/msix-package-guide.md))
- **Windows Package Manager (winget)** - Under consideration

For build instructions and distribution guides, see:

- [Build Guide](docs/prompt-rigenerazione-rc-successiva.md) - Complete build workflow
- [Inno Setup Guide](docs/inno-setup-guide.md) - EXE installer creation
- [MSIX Guide](docs/msix-package-guide.md) - Microsoft Store packaging

---

**Version**: 1.0.11
**Status**: 🟢 Production Ready
**Last Updated**: 2026-01-10
