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

## 📦 Installation

### Windows Executable (Recommended)

Download the latest `FolderTextMerger.exe` from [Releases](../../releases) and place it in a permanent location (e.g., `C:\Program Files\FolderTextMerger\`).

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
pyinstaller --onefile --clean FolderTextMerger.py
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

- [Recovery Report](RECOVERY_REPORT.md) - Technical details on Python 3.13 → 3.12 migration
- [Final Test Report](FINAL_TEST_REPORT.md) - Complete test results (21/21 tests passing)
- [Installation Guide](docs/INSTALLATION.md) - Detailed setup instructions
- [User Guide](docs/USER_GUIDE.md) - Comprehensive usage examples

## 🧪 Testing

The project includes comprehensive test suites:

```bash
# Run basic tests
python testiamo/test_runner.py

# Run integration tests
python testiamo/comprehensive_test.py

# Run context menu simulations
python testiamo/context_menu_scenarios.py
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
pyinstaller --onefile --clean FolderTextMerger.py

# Verify
dist/FolderTextMerger.exe --help
```

### Testing

```bash
# Quick test
python FolderTextMerger.py testiamo/test_real_scenario -o test_output.txt

# Full test suite
python testiamo/comprehensive_test.py
```

## 🐛 Troubleshooting

### Issue: "The file does not have an app associated with it"

**Solution**: This indicates a corrupt PE header. Use Python 3.12 instead of 3.13 (see [RECOVERY_REPORT.md](RECOVERY_REPORT.md)).

### Issue: File skipped as "binary-like"

**Solution**: File contains <85% ASCII characters. This is intentional to avoid binary files. Add more ASCII text or adjust `TEXT_DETECTION_THRESHOLD` in source.

### Issue: No files found

**Solution**: Check debug log at `%TEMP%\FolderTextMerger_Debug.log` for details on which paths were scanned.

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
