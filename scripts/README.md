# Scripts Directory

This directory contains utility scripts for FolderTextMerger maintenance and development.

## Active Scripts

### maintenance/
Scripts for maintaining the application in production:
- Registry cleanup utilities
- Debug helpers
- System maintenance tools

## Archive

### archive/
Historical installation scripts (now obsolete - replaced by `build/create-distribution.ps1`):
- `installer.ps1` - Old manual installer
- `uninstaller.ps1` - Old manual uninstaller
- `rebuild-install.ps1` - Old build-and-install script
- Legacy cleanup and diagnostic scripts

**Note**: These scripts are kept for reference only. For installation, use the ZIP distribution package created by `build/create-distribution.ps1`.

## Current Installation Method

The current recommended installation method is:

1. Generate distribution package:

   ```powershell
   cd build
   .\create-distribution.ps1
   ```

2. Distribute the generated ZIP file:

   ```text
   FolderTextMerger-v1.0.5-Setup.zip
   ```

3. Users extract and run:

   ```powershell
   Right-click INSTALL.ps1 -> Run with PowerShell
   ```

This provides:

- Automatic context menu registration
- Windows Programs & Features integration
- Clean uninstall capability
- Configuration file management
- Self-contained distribution

---

**Last Updated**: 2026-01-09
