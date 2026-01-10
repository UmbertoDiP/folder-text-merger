# Folder2Text

[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.8-brightgreen.svg)]()

Merge multiple text files from folders into a single output file. Perfect for sharing code with AI assistants, code reviews, and documentation consolidation.

## 🎯 Features

- ✅ **60+ file types supported** - .txt, .py, .java, .js, .md, .cpp, .sql, and more
- ✅ **Context menu integration** - Right-click folders/files in Windows Explorer
- ✅ **Smart binary detection** - Automatically skips binary files
- ✅ **Cross-drive support** - Works across different disk volumes (C:, D:, F:, etc.)
- ✅ **Silent execution** - No console windows (windowed mode)
- ✅ **Comprehensive summary** - File statistics and extraction report
- ✅ **Windows integration** - Registered in Programs & Features (Control Panel)
- ✅ **No admin rights required** - Installs to user profile

## 📦 Quick Start

### Installation

1. Download `Folder2Text-v1.0.8-Setup.zip`
2. Extract all files
3. Right-click **INSTALL.ps1** → "Run with PowerShell"
4. Done! 🎉

### Usage

**Option 1**: Right-click on a folder → "Folder2Text - Extract text from folder"

**Option 2**: Right-click inside a folder (on background) → "Folder2Text - Extract text from folder"

**Option 3**: Right-click on text files → "Merge with other text files"

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
Folder2Text/
├── src/                          # Source code
│   └── Folder2Text.py       # Main application (v1.0.5)
├── build/                        # Build scripts
│   ├── create-distribution.ps1   # Distribution package creator
│   └── msix/                     # MSIX package (future: Microsoft Store)
├── config/                       # Configuration
│   └── supported_extensions.txt  # 60+ file types
├── docs/                         # Documentation
│   ├── LICENSE                   # MIT License
│   └── archive/                  # Historical reports
├── scripts/                      # Utilities
│   ├── maintenance/              # Maintenance scripts
│   └── archive/                  # Old installation scripts (obsolete)
├── tests/                        # Test suites
└── Folder2Text.exe          # Production executable
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

---

**Version**: 1.0.8
**Status**: 🟢 Production Ready
**Last Updated**: 2026-01-09
