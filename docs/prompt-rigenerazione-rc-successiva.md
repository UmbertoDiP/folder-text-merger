# Prompt - Rigenerazione Release Candidate Successiva

## Contesto
Questo documento descrive il workflow completo per rigenerare una nuova release candidate (RC) di Folder2Text dopo modifiche al codice o agli asset.

---

## Prerequisiti

### Struttura Progetto
```
FolderTextMerger/
├── src/
│   ├── Folder2Text.py           # VERSION = "X.Y.Z" (da aggiornare)
│   ├── Folder2Text.spec         # PyInstaller config
│   └── icon.png                 # Source icona (se da cambiare)
├── assets/
│   ├── app_icon.ico             # Icona compilata (auto-generata)
│   └── app_icon.png             # PNG backup
├── build/
│   ├── create-distribution.ps1  # $Version = "X.Y.Z" (da aggiornare)
│   └── pyinstaller/
├── distribution/                # Generata da build script
│   ├── INSTALL.ps1              # $Version = "X.Y.Z" (da aggiornare)
│   ├── UNINSTALL.ps1            # Header version (da aggiornare)
│   ├── scan-context-menu.ps1    # Diagnostic
│   └── clean-legacy-entries.ps1 # Legacy cleanup
├── config/
│   └── supported_extensions.txt # 60+ estensioni
├── Folder2Text.exe              # Compilato (auto-generato)
└── Folder2Text-vX.Y.Z-Setup.zip # Distribuzione finale
```

### Tool Richiesti
- Python 3.13+ con PyInstaller
- Pillow (PIL) per conversione PNG → ICO
- PowerShell 5.1+

---

## Workflow Completo: Rigenerazione RC Successiva

### STEP 0: Disinstalla Versione Corrente (Opzionale ma Consigliato)

**Scopo**: Pulire registry e installazione precedente prima di testare nuova versione.

```bash
cd "C:\Users\umber\Documents\MyProjects\FolderTextMerger\distribution"
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File UNINSTALL.ps1
```

**Verifica pulizia**:
```bash
powershell.exe -ExecutionPolicy Bypass -File scan-context-menu.ps1
```

**Output atteso**: `Found 0 context menu entries`

**Note**:
- Uninstaller è silent (nessun output)
- Rimuove: directory `%LOCALAPPDATA%\Folder2Text`, registry entries, Control Panel entry
- Se rimangono voci legacy: esegui `clean-legacy-entries.ps1`

---

### STEP 1: Incrementa Versione

**File da aggiornare** (4 file):

#### 1.1 - `src/Folder2Text.py`
```python
# Linea 18
VERSION = "1.0.10"  # Incrementa da 1.0.9 → 1.0.10
```

#### 1.2 - `build/create-distribution.ps1`
```powershell
# Linea 11
$Version = "1.0.10"  # Incrementa versione
```

#### 1.3 - `distribution/INSTALL.ps1`
```powershell
# Linea 2 (header commento)
# Folder2Text v1.0.10 - Standalone Installer

# Linea 12
$Version = "1.0.10"
```

#### 1.4 - `distribution/UNINSTALL.ps1`
```powershell
# Linea 2 (header commento)
# Folder2Text v1.0.10 - Silent Uninstaller
```

**Comando rapido per aggiornare tutte le versioni**:
```bash
# Usa Edit tool con replace_all=false per ogni file
# Oppure manualmente con editor
```

---

### STEP 2: Aggiorna Icona (Se Necessario)

**Scenario**: Vuoi cambiare l'icona dell'applicazione.

#### 2.1 - Sostituisci PNG Source
```bash
# Copia nuova icona (512x512 PNG raccomandato)
cp "path/to/new/icon.png" "C:\Users\umber\Documents\MyProjects\FolderTextMerger\src\icon.png"
```

#### 2.2 - Converti PNG → ICO
```bash
cd "C:\Users\umber\Documents\MyProjects\FolderTextMerger"

python -c "
from PIL import Image
img = Image.open('src/icon.png')
if img.mode != 'RGBA':
    img = img.convert('RGBA')
sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
img.save('assets/app_icon.ico', format='ICO', sizes=sizes)
print('Icon converted: assets/app_icon.ico')
"
```

**Output**: `assets/app_icon.ico` aggiornato con multi-size (16px → 256px)

**Note**:
- `Folder2Text.spec` punta già a `../assets/app_icon.ico` (linea 38)
- Conversione include 6 risoluzioni per compatibilità Windows
- ICO viene embedded nell'exe durante compilazione PyInstaller

---

### STEP 3: Compila Eseguibile

```bash
cd "C:\Users\umber\Documents\MyProjects\FolderTextMerger\src"

# Build con PyInstaller (pulisce cache precedente)
python -m PyInstaller --clean --noconfirm Folder2Text.spec
```

**Output**: `src/dist/Folder2Text.exe` (11+ MB)

**Verifica build**:
- Controlla messaggi `INFO: Building EXE completed successfully`
- File esiste: `src/dist/Folder2Text.exe`
- Nessun errore critico

#### 3.1 - Copia Exe in Project Root
```bash
cp "C:\Users\umber\Documents\MyProjects\FolderTextMerger\src\dist\Folder2Text.exe" \
   "C:\Users\umber\Documents\MyProjects\FolderTextMerger\Folder2Text.exe"
```

**Perché**: Lo script `create-distribution.ps1` cerca l'exe nella root del progetto.

---

### STEP 4: Genera Distribuzione ZIP

```bash
cd "C:\Users\umber\Documents\MyProjects\FolderTextMerger\build"

# Esegui script build
powershell.exe -ExecutionPolicy Bypass -File create-distribution.ps1
```

**Operazioni automatiche**:
1. Pulisce cartella `distribution/` precedente
2. Copia `Folder2Text.exe` → `distribution/`
3. Copia `config/supported_extensions.txt` → `distribution/config/`
4. Copia template installer/uninstaller (da `build/templates/` se esistono, altrimenti da root)
5. Genera `README.txt`
6. Crea ZIP: `Folder2Text-vX.Y.Z-Setup.zip`

**Output**:
```
=== Creating Distribution Package v1.0.10 ===

Package: Folder2Text-v1.0.10-Setup.zip
Location: C:\Users\umber\Documents\MyProjects\FolderTextMerger
Size: ~11.34 MB

Contents:
  - Folder2Text.exe
  - INSTALL.ps1
  - UNINSTALL.ps1
  - README.txt
  - config/supported_extensions.txt
```

**Path ZIP finale**:
```
C:\Users\umber\Documents\MyProjects\FolderTextMerger\Folder2Text-v1.0.10-Setup.zip
```

---

### STEP 5: Test Locale (Opzionale)

#### 5.1 - Estrai ZIP in Temp
```powershell
$tempDir = "C:\Temp\Folder2Text-Test"
Expand-Archive -Path "C:\Users\umber\Documents\MyProjects\FolderTextMerger\Folder2Text-v1.0.10-Setup.zip" `
               -DestinationPath $tempDir -Force
```

#### 5.2 - Installa
```powershell
cd $tempDir
.\INSTALL.ps1
```

**Verifica installazione**:
- Directory creata: `%LOCALAPPDATA%\Folder2Text\`
- Exe copiato: `%LOCALAPPDATA%\Folder2Text\Folder2Text.exe`
- Context menu appare su cartelle/file
- Entry in Control Panel: Settings > Apps > Folder2Text

#### 5.3 - Test Context Menu
```powershell
# Crea cartella test
mkdir "C:\Temp\TestFolder"
echo "test content" > "C:\Temp\TestFolder\file1.txt"
echo "test content 2" > "C:\Temp\TestFolder\file2.py"

# Click destro su TestFolder → "Folder2Text – Convert folder to text"
# Verifica output-TestFolder-[timestamp].txt creato in C:\Temp\
```

#### 5.4 - Test Uninstall
```powershell
cd $tempDir
.\UNINSTALL.ps1

# Verifica pulizia
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\umber\Documents\MyProjects\FolderTextMerger\distribution\scan-context-menu.ps1"
# Output atteso: "Found 0 context menu entries"
```

---

## Comandi Quick Reference

### Workflow Completo (Un Solo Blocco)

```bash
# === STEP 0: Uninstall precedente ===
cd "C:\Users\umber\Documents\MyProjects\FolderTextMerger\distribution"
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File UNINSTALL.ps1

# === STEP 1: Update versions (manualmente nei 4 file) ===
# src/Folder2Text.py          → VERSION = "1.0.10"
# build/create-distribution.ps1 → $Version = "1.0.10"
# distribution/INSTALL.ps1      → $Version = "1.0.10" + header
# distribution/UNINSTALL.ps1    → header comment

# === STEP 2: Aggiorna icona (se necessario) ===
cd "C:\Users\umber\Documents\MyProjects\FolderTextMerger"
python -c "from PIL import Image; img = Image.open('src/icon.png').convert('RGBA'); img.save('assets/app_icon.ico', format='ICO', sizes=[(256,256),(128,128),(64,64),(48,48),(32,32),(16,16)])"

# === STEP 3: Compila exe ===
cd src
python -m PyInstaller --clean --noconfirm Folder2Text.spec
cp dist/Folder2Text.exe ../Folder2Text.exe

# === STEP 4: Genera ZIP ===
cd ../build
powershell.exe -ExecutionPolicy Bypass -File create-distribution.ps1

# === OUTPUT ===
# ZIP disponibile in: C:\Users\umber\Documents\MyProjects\FolderTextMerger\Folder2Text-v1.0.10-Setup.zip
```

---

## Troubleshooting

### Problema: PyInstaller non trovato
```bash
# Installa PyInstaller
pip install pyinstaller

# Verifica installazione
python -m PyInstaller --version
```

### Problema: Pillow non trovato (conversione icona)
```bash
pip install Pillow

# Test
python -c "from PIL import Image; print('Pillow OK')"
```

### Problema: Icon.ico non trovato durante build
**Causa**: Path errato in `Folder2Text.spec`

**Verifica**:
```python
# Folder2Text.spec linea 38
icon=['..\\assets\\app_icon.ico']  # Path relativo da src/
```

**Fix**: Assicurati che `assets/app_icon.ico` esista prima di build

### Problema: ZIP contiene vecchia versione exe
**Causa**: Exe non copiato in project root dopo build

**Fix**:
```bash
cp src/dist/Folder2Text.exe ./Folder2Text.exe
```

### Problema: Uninstaller non rimuove tutte le voci
**Causa**: Voci legacy con nomi diversi (es. "FolderTextMerger")

**Fix**:
```bash
cd distribution
.\clean-legacy-entries.ps1
```

### Problema: Context menu non appare dopo install
**Causa**: Registry non aggiornato o explorer.exe caching

**Fix**:
```powershell
# Restart Explorer
taskkill /f /im explorer.exe
start explorer.exe

# Verifica registry manualmente
.\scan-context-menu.ps1
```

---

## File Versioning Checklist

Prima di generare nuova RC, verifica che **TUTTI questi file** abbiano versione aggiornata:

- [ ] `src/Folder2Text.py` → `VERSION = "X.Y.Z"` (linea 18)
- [ ] `build/create-distribution.ps1` → `$Version = "X.Y.Z"` (linea 11)
- [ ] `distribution/INSTALL.ps1` → Header (linea 2) + `$Version = "X.Y.Z"` (linea 12)
- [ ] `distribution/UNINSTALL.ps1` → Header (linea 2)
- [ ] `assets/app_icon.ico` → Aggiornato se icona cambiata
- [ ] `Folder2Text.exe` → Ricompilato con PyInstaller
- [ ] `Folder2Text-vX.Y.Z-Setup.zip` → Generato con versione corretta

---

## Versioni Precedenti

| Versione | Data | Novità |
|----------|------|--------|
| 1.0.9 | 2026-01-10 | Icona aggiornata da `src/icon.png` |
| 1.0.8 | 2026-01-10 | Registry cleanup scripts, version bump |
| 1.0.7 | 2026-01-09 | Silent execution, Control Panel integration |
| 1.0.6 | 2025-XX-XX | Rebrand to Folder2Text |
| 1.0.5 | 2025-XX-XX | Cross-drive operations (shutil.move) |

---

## Note Importanti

### Registry Keys Location
Tutti i registry keys sono in **HKCU** (user scope), non HKLM:
- `HKCU:\Software\Classes\Directory\shell\Folder2Text`
- `HKCU:\Software\Classes\Directory\Background\shell\Folder2Text`
- `HKCU:\Software\Classes\SystemFileAssociations\[.ext]\shell\Folder2Text`

**Vantaggio**: Nessun admin richiesto per installazione/disinstallazione

### Distribution Package Content
Il ZIP contiene:
1. `Folder2Text.exe` - Applicazione (11+ MB, windowed mode)
2. `INSTALL.ps1` - Installer PowerShell (registra context menu)
3. `UNINSTALL.ps1` - Uninstaller PowerShell (cleanup completo)
4. `README.txt` - Istruzioni installazione
5. `config/supported_extensions.txt` - 60+ estensioni supportate

**Non include**:
- Codice sorgente Python
- PyInstaller spec files
- Build scripts
- Diagnostic tools (scan, clean) - disponibili in repo ma non necessari per utenti finali

### Context Menu Integration
Tre entry points:
1. **Folder Menu**: Click destro su cartella
2. **Folder Background Menu**: Click destro su spazio vuoto in cartella
3. **File Type Menus**: Click destro su 60+ tipi file supportati

**Testo menu**:
- Cartelle: "Folder2Text – Convert folder to text"
- File: "Merge with other text files"

**Comando eseguito**: `"%LOCALAPPDATA%\Folder2Text\Folder2Text.exe" "%1"` (o `%V` per background)

---

## Path Output Finale

Dopo esecuzione completa del workflow:

```
C:\Users\umber\Documents\MyProjects\FolderTextMerger\Folder2Text-v1.0.10-Setup.zip
```

**Distribuisci questo ZIP agli amici.**

---

## Prossimi Task (Non Coperti da Questo Workflow)

1. **Inno Setup Installer** - Creare `.exe` installer invece di ZIP
2. **Microsoft Store Package** - Creare `.msix` per Store
3. **Code Signing** - Firmare exe con certificato (rimuove warning SmartScreen)
4. **Auto-Update** - Sistema aggiornamento automatico
5. **Telemetria** - Tracking usage (opzionale, privacy-aware)

---

**Fine Documento**
