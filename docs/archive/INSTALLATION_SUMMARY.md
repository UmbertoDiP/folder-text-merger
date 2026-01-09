# ✅ FolderTextMerger - Installazione Completata

## 📋 Status Finale

**Versione**: 1.1.0-rc8  
**Data**: 2026-01-08  
**Status**: ✅ Pronto all'uso

---

## 📁 Dove Trovare Tutto

### 1. Eseguibile Installato
```
C:\Users\{username}\AppData\Local\FolderTextMerger\FolderTextMerger.exe
```

### 2. Log dell'Applicazione
```
C:\Users\{username}\AppData\Local\FolderTextMerger\logs\
```

**Comandi rapidi PowerShell**:
```powershell
# Apri log corrente
notepad $env:LOCALAPPDATA\FolderTextMerger\logs\debug.log

# Apri cartella log
explorer $env:LOCALAPPDATA\FolderTextMerger\logs

# Lista tutti i log
Get-ChildItem $env:LOCALAPPDATA\FolderTextMerger\logs
```

### 3. File Output Generati
I file unificati vengono creati nella **stessa cartella dei file sorgente**:
```
{cartella-sorgente}\output-{nome-cartella}-{timestamp}.txt
```

Esempio:
```
C:\MyProject\output-MyProject-20260108-153045.txt
```

---

## 🖱️ Come Usare

### Opzione 1: Click destro su CARTELLA
1. Vai in Esplora File
2. Click destro su una cartella
3. Seleziona **"Merge text files here"**
4. Attendi notifica toast (5 secondi)
5. File creato nella cartella

### Opzione 2: Click destro su FILE
1. Click destro su un file `.txt`, `.py`, `.md`, etc.
2. Seleziona **"Merge with other text files"**
3. Unisce il file con altri nella stessa cartella

### Opzione 3: Selezione Multipla
1. Seleziona più file/cartelle (CTRL+click)
2. Click destro
3. Seleziona **"Merge selected text files"**

### Opzione 4: Background Cartella
1. Apri una cartella
2. Click destro nello **spazio vuoto**
3. Seleziona **"Merge text files here"**

---

## 📊 Sistema di Logging

### Cosa Viene Loggato

#### ✅ Sempre (Produzione)
- ✅ Start/stop applicazione
- ✅ Argomenti ricevuti
- ✅ Numero totale file processati
- ✅ **Errori e eccezioni** (sempre!)
- ✅ Path file output creato
- ✅ Operazioni critiche (scrittura file, temp files)

#### 🔧 Solo in DEV_MODE
- File individuali processati ("Merged file: xyz.txt")
- File skippati (motivo: unsupported, binary, oversized)
- Validazioni dettagliate per ogni file

### Log Retention
- **Rotazione**: Automatica giornaliera (`when="D"`)
- **Retention**: 30 giorni (`LOG_RETENTION_DAYS = 30`)
- **Pulizia**: Automatica (file > 30 giorni eliminati)

### Formato Log
```
YYYY-MM-DD HH:MM:SS,mmm - LEVEL - Message
```

Esempio:
```log
2026-01-08 15:30:45,123 - INFO - Process completed successfully: output.txt
2026-01-08 15:30:45,124 - ERROR - Error processing file test.bin: UnicodeDecodeError
2026-01-08 15:30:45,125 - DEBUG - Arguments received: ['C:\Projects']
```

### File Log
- **Corrente**: `debug.log`
- **Archiviati**: `debug.log.2026-01-07`, `debug.log.2026-01-06`, etc.

---

## 🔧 Modalità Sviluppo

Per abilitare log dettagliati (file-by-file):

1. Apri `src/FolderTextMerger.py`
2. Cerca `DEV_MODE = False`
3. Cambia in `DEV_MODE = True`
4. Rebuild: `.\scripts\rebuild-install.ps1`

**Quando usare DEV_MODE**:
- Debug di problemi specifici
- Verifica quali file vengono processati
- Analisi dettagliata errori

**Quando NON usare**:
- Produzione (log crescono velocemente)
- Uso normale (informazioni eccessive)

---

## 🎯 Funzionalità Implementate

### ✅ Completate
- [x] Menu contestuale (4 location: folder, file, multi-select, background)
- [x] Icona visibile (embedded in EXE, formato `,0`)
- [x] Operazione silenziosa (no console flash)
- [x] Notifica toast Windows (5 secondi)
- [x] Log con rotazione giornaliera (30 giorni)
- [x] DEV_MODE per log dettagliati
- [x] Esclusione file output precedenti (`output-*.txt`)
- [x] 61 estensioni supportate (config centralizzato)
- [x] Build automatico con versioning
- [x] Installer/Uninstaller completo

### 📝 Registry Configurato
Totale: **65 voci**
- 1x Folder menu
- 1x Background menu  
- 1x Multi-selection menu
- 61x File type menus (una per estensione)
- 1x Legacy fallback (HKCR)

---

## 📚 File Documentazione

1. **README.md** - Guida utente e quick start
2. **PROJECT_RULES.md** - Regole tecniche dettagliate
3. **INSTALLATION_SUMMARY.md** - Questo file
4. **config/supported_extensions.txt** - Lista estensioni (61)

---

## 🐛 Troubleshooting Rapido

### Problema: Menu contestuale non visibile
```powershell
# 1. Riavvia Explorer
Stop-Process -Name explorer -Force
Start-Process explorer.exe

# 2. Verifica registry
Get-ItemProperty -Path 'HKCU:\Software\Classes\Directory\shell\FolderTextMerger'

# 3. Reinstalla se necessario
.\scripts\rebuild-install.ps1
```

### Problema: Applicazione non funziona
```powershell
# 1. Controlla log
notepad $env:LOCALAPPDATA\FolderTextMerger\logs\debug.log

# 2. Verifica eseguibile esiste
Test-Path $env:LOCALAPPDATA\FolderTextMerger\FolderTextMerger.exe

# 3. Testa manuale
& "$env:LOCALAPPDATA\FolderTextMerger\FolderTextMerger.exe" "C:\test-folder"
```

### Problema: File `.txt` skippato
Se il file si chiama `output-*.txt`, viene **intenzionalmente escluso** per evitare di includere output precedenti nel merge successivo.

---

## 🔄 Operazioni Comuni

### Reinstallazione Completa
```powershell
# 1. Disinstalla
.\scripts\uninstaller.ps1

# 2. Rebuild e installa
.\scripts\rebuild-install.ps1
```

### Verifica Installazione
```powershell
# Check eseguibile
if (Test-Path $env:LOCALAPPDATA\FolderTextMerger\FolderTextMerger.exe) {
    Write-Host "✓ Executable OK" -ForegroundColor Green
}

# Check registry
if (Test-Path 'HKCU:\Software\Classes\Directory\shell\FolderTextMerger') {
    Write-Host "✓ Context menu OK" -ForegroundColor Green
}

# Check log folder
if (Test-Path $env:LOCALAPPDATA\FolderTextMerger\logs) {
    Write-Host "✓ Log folder OK" -ForegroundColor Green
}
```

### Pulizia Log Manuale
```powershell
# Elimina log > 30 giorni
Get-ChildItem $env:LOCALAPPDATA\FolderTextMerger\logs\*.log.* |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force
```

---

## 📞 Link Rapidi

- **Log corrente**: `C:\Users\%USERNAME%\AppData\Local\FolderTextMerger\logs\debug.log`
- **Eseguibile**: `C:\Users\%USERNAME%\AppData\Local\FolderTextMerger\FolderTextMerger.exe`
- **Config estensioni**: `config\supported_extensions.txt`
- **Regole progetto**: `PROJECT_RULES.md`

---

**Tutto pronto!** 🎉

Ora puoi:
1. Click destro su qualsiasi cartella/file
2. Selezionare "Merge text files here"
3. Controllare i log in `%LOCALAPPDATA%\FolderTextMerger\logs\debug.log`
