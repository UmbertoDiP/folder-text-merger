# FolderTextMerger

[![Python 3.12](https://img.shields.io/badge/python-3.12-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

A high-performance CLI tool to merge multiple text files from folders into a single output file. Perfect for code reviews, documentation consolidation, and project analysis.

## 🎯 Features

- ✅ **Recursive folder traversal** - Process entire directory trees
- ✅ **Smart file detection** - Binary file filtering with 85% ASCII threshold
- ✅ **Unicode support** - Full UTF-8 encoding (café, €, →, 😀, 日本語)
- ✅ **Size limits** - Configurable max file size (default 10MB)
- ✅ **Performance** - ~1.78 MB/s processing speed
- ✅ **Debug logging** - Comprehensive logging to %TEMP%
- ✅ **Context menu ready** - Windows Explorer integration
- ✅ **Error handling** - Robust exit codes (0/2/3)

## 📁 Project Structure

```
FolderTextMerger/
├── src/                          # Source code
│   ├── FolderTextMerger.py      # Main application
│   └── FolderTextMerger.spec    # PyInstaller spec file
├── scripts/                      # Installation and utility scripts
│   ├── installer.ps1            # Install to system
│   ├── uninstaller.ps1          # Remove from system
│   └── rebuild-install.ps1      # Build and install
├── docs/                         # Documentation
│   ├── LICENSE                  # MIT License
│   ├── RECOVERY_REPORT.md       # Python 3.13→3.12 migration
│   ├── FINAL_TEST_REPORT.md     # Test results
│   └── CONTEXT_MENU_CLEANUP_REPORT.md
├── tests/                        # Test suites
│   └── testiamo/                # Test scenarios
├── backup/                       # Backup files (git-ignored)
├── build/                        # Build artifacts (git-ignored)
├── dist/                         # Compiled executables (git-ignored)
├── FolderTextMerger.exe         # Production executable
└── README.md                     # This file
```

## 📦 Installation

### Windows Executable (Recommended)

#### Automatic Installation

```powershell
# Run installer from scripts folder
.\scripts\installer.ps1
```

This will:
- Install `FolderTextMerger.exe` to `%LOCALAPPDATA%\FolderTextMerger\` (user) or `C:\Program Files\FolderTextMerger\` (admin)
- Add context menu to Windows Explorer (4 locations: folders, files, multi-select, background)
- Create log directory at `%LOCALAPPDATA%\FolderTextMerger\logs\` (30 days retention)

#### Manual Installation

Download the latest `FolderTextMerger.exe` from [Releases](../../releases) and place it in a permanent location (e.g., `C:\Program Files\FolderTextMerger\`).

### Uninstallation

```powershell
# Remove FolderTextMerger completely
.\scripts\uninstaller.ps1
```

This will:
- Remove context menu integration
- Delete executable and installation directory
- Clean up registry entries
- Preserve log files (can be manually deleted)

### From Source

```bash
# Clone repository
git clone https://gitlab.com/YOUR_USERNAME/folder-text-merger.git
cd folder-text-merger

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install pyinstaller

# Build executable
pyinstaller --onefile --clean src/FolderTextMerger.py
```

## 🚀 Quick Start

### Basic Usage

```bash
# Merge all text files in a folder
FolderTextMerger.exe /path/to/folder

# Merge specific files
FolderTextMerger.exe file1.txt file2.py file3.md

# Custom output path
FolderTextMerger.exe /path/to/folder -o merged_output.txt

# Increase size limit to 20MB
FolderTextMerger.exe /path/to/folder --max-size-mb 20
```

### Windows Explorer Integration

Right-click on files/folders and select "Merge with FolderTextMerger" (requires registry setup - see [Installation Guide](docs/INSTALLATION.md)).

## 📚 Documentation

- [Recovery Report](docs/RECOVERY_REPORT.md) - Technical details on Python 3.13 → 3.12 migration
- [Final Test Report](docs/FINAL_TEST_REPORT.md) - Complete test results (21/21 tests passing)
- [Installation Guide](docs/INSTALLATION.md) - Detailed setup instructions
- [User Guide](docs/USER_GUIDE.md) - Comprehensive usage examples

## 🧪 Testing

The project includes comprehensive test suites:

```bash
# Run basic tests
python tests/testiamo/test_runner.py

# Run integration tests
python tests/testiamo/comprehensive_test.py

# Run context menu simulations
python tests/testiamo/context_menu_scenarios.py
```

**Test Results**: 21/21 (100% pass rate)

## 📊 Performance Metrics

| File Count | Total Size | Processing Time | Throughput |
|------------|------------|-----------------|------------|
| 4          | 5 KB       | <100ms          | ~50 KB/s   |
| 5          | 820 KB     | 460ms           | ~1.78 MB/s |
| 2          | 13 MB      | <2s             | ~6.5 MB/s  |

## 🛠️ Development

### Requirements

- Python 3.12+
- PyInstaller 6.17.0+

### Build

```bash
# Clean build
rm -rf build dist *.spec

# Compile
pyinstaller --onefile --clean src/FolderTextMerger.py

# Verify
dist/FolderTextMerger.exe --help
```

### Testing

```bash
# Quick test
python src/FolderTextMerger.py tests/testiamo/test_real_scenario -o test_output.txt

# Full test suite
python tests/testiamo/comprehensive_test.py
```

## 📁 Important Paths

### Application Files
- **Executable**: `C:\Users\{username}\AppData\Local\FolderTextMerger\FolderTextMerger.exe`
- **Logs**: `C:\Users\{username}\AppData\Local\FolderTextMerger\logs\`

### Log Files
Current logs are stored at:
```
C:\Users\{YourUsername}\AppData\Local\FolderTextMerger\logs\debug.log
```

Quick access PowerShell commands:
```powershell
# Open log file
notepad $env:LOCALAPPDATA\FolderTextMerger\logs\debug.log

# Open log folder
explorer $env:LOCALAPPDATA\FolderTextMerger\logs
```

### Log Retention
- **Rotation**: Daily (automatic)
- **Retention**: 30 days (auto-cleanup)
- **Format**: `debug.log` (current) + `debug.log.YYYY-MM-DD` (archived)

### What Gets Logged
✅ Always logged:
- Application start/stop
- Arguments received
- Total files processed
- Errors and exceptions
- Output file path

🔧 Development mode only (DEV_MODE=True):
- Individual file processing
- Files skipped (with reason)
- Detailed validation steps

## 🐛 Troubleshooting

### Issue: Application doesn't work
1. Check logs: `%LOCALAPPDATA%\FolderTextMerger\logs\debug.log`
2. Verify executable exists: `%LOCALAPPDATA%\FolderTextMerger\FolderTextMerger.exe`
3. Restart Windows Explorer (Task Manager → Windows Explorer → Restart)

### Issue: Context menu not visible
1. Restart Windows Explorer
2. Reinstall: `.\scripts\rebuild-install.ps1`
3. Check registry: `Get-ChildItem 'HKCU:\Software\Classes\Directory\shell\FolderTextMerger'`

### Issue: "output-*.txt" files are skipped
This is intentional to prevent merging previous output files. Output files are excluded by name pattern.

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with Python 3.12.10
- Packaged with PyInstaller 6.17.0
- Tested on Windows 11

## 📞 Support

For issues, questions, or contributions, please open an issue on [GitLab](../../issues).

---

**Version**: 1.1.0-rc4
**Status**: 🟢 Production Ready
**Last Updated**: 2026-01-07
