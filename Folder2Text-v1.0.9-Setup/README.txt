# Folder2Text v1.0.9

## Quick Start

1. Right-click on **INSTALL.ps1** and select **"Run with PowerShell"**
2. Wait for installation to complete (few seconds)
3. Done! Right-click on any folder to see "Folder2Text - Extract text from folder"

## What does it do?

Folder2Text combines multiple text files from a folder into a single output file.
Perfect for:
- Sharing code with AI assistants (Claude, ChatGPT, etc.)
- Creating project snapshots
- Reviewing multiple log files
- Documentation gathering

## Features

- Works with 60+ file types (.txt, .py, .java, .js, .md, etc.)
- Automatic binary file detection and exclusion
- Comprehensive summary with file statistics
- Silent execution (no console windows)
- Context menu integration (right-click on folders)

## Usage

**Option 1**: Right-click on a folder â†’ "Folder2Text - Extract text from folder"
**Option 2**: Right-click inside a folder (on background) â†’ "Folder2Text - Extract text from folder"
**Option 3**: Right-click on text files â†’ "Merge with other text files"

Output file will be created in the parent directory with format:
\output-[foldername]-[timestamp].txt\

## Uninstallation

**Option 1** (Recommended): Settings > Apps > Apps & features > Folder2Text > Uninstall

**Option 2**: Right-click on **UNINSTALL.ps1** and select **"Run with PowerShell"**

## System Requirements

- Windows 10/11
- PowerShell (included in Windows)
- No admin rights required

## Privacy

- All processing is local (no internet connection required)
- No data collection
- Open source: https://github.com/UmbertoDiP/folder-text-merger

## Version

1.0.9 (Released: 2026-01-10)

## License

Copyright (c) 2026 Folder2Text. All rights reserved.

---

**Troubleshooting**

If installation fails with "execution policy" error:
1. Open PowerShell as Administrator
2. Run: \Set-ExecutionPolicy RemoteSigned -Scope CurrentUser\
3. Retry installation

For support: https://github.com/UmbertoDiP/folder-text-merger/issues
