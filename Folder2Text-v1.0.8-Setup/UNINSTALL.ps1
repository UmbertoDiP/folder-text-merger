# =========================
# Folder2Text v1.0.8 - Silent Uninstaller
# =========================
# Completely silent operation with ROBUST self-deletion

$ErrorActionPreference = "SilentlyContinue"
$ApplicationName = "Folder2Text"
$InstallDir = Join-Path $env:LOCALAPPDATA $ApplicationName
$RegistryBase = "HKCU:\Software\Classes"

# 1. Remove context menu entries
try {
    $Keys = @(
        "Directory\shell\$ApplicationName",
        "Directory\Background\shell\$ApplicationName"
    )

    foreach ($key in $Keys) {
        $fullPath = Join-Path $RegistryBase $key
        if (Test-Path $fullPath) {
            Remove-Item $fullPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
} catch { }

# 2. Remove file type associations
try {
    $SystemFileAssoc = Join-Path $RegistryBase "SystemFileAssociations"
    if (Test-Path $SystemFileAssoc) {
        Get-ChildItem $SystemFileAssoc -ErrorAction SilentlyContinue | ForEach-Object {
            $appPath = Join-Path $_.PSPath "shell\$ApplicationName"
            if (Test-Path $appPath) {
                Remove-Item $appPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
} catch { }

# 3. Remove from Control Panel
try {
    $UninstallKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ApplicationName"
    if (Test-Path $UninstallKey) {
        Remove-Item $UninstallKey -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }
} catch { }

# 4. Deferred self-deletion: Create ROBUST VBScript helper in TEMP
try {
    $CleanupScript = Join-Path $env:TEMP "Folder2Text_Cleanup.vbs"
    
    # We build the VBS content line by line for clarity and correct variable injection
    # This VBS loops for 10 seconds trying to delete the folder
    $VbsLines = @(
        'Set objFSO = CreateObject("Scripting.FileSystemObject")',
        'strFolder = "' + $InstallDir + '"',
        'strScript = WScript.ScriptFullName',
        '',
        "' Loop up to 20 times (approx 10 seconds) waiting for file unlock",
        'For i = 1 To 20',
        '    WScript.Sleep 500',
        '    On Error Resume Next',
        '    If objFSO.FolderExists(strFolder) Then',
        '        objFSO.DeleteFolder strFolder, True',
        '    End If',
        '    If Err.Number = 0 Then Exit For',
        '    Err.Clear',
        '    On Error Goto 0',
        'Next',
        '',
        "' Self-delete VBS",
        'On Error Resume Next',
        'If objFSO.FileExists(strScript) Then',
        '    objFSO.DeleteFile strScript, True',
        'End If'
    )
    
    $VbsContent = $VbsLines -join [Environment]::NewLine
    
    Set-Content -Path $CleanupScript -Value $VbsContent -Encoding ASCII -Force -ErrorAction SilentlyContinue

    # Launch cleanup script silently (hidden window)
    Start-Process -FilePath "wscript.exe" -ArgumentList ""$CleanupScript"" -WindowStyle Hidden -ErrorAction SilentlyContinue
} catch { }

# Exit immediately so the VBS can delete this folder
