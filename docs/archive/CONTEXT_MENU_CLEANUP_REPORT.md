# Context Menu Cleanup Report

**Data**: 2026-01-08
**Operazione**: Pulizia menu contestuale Windows + Creazione uninstaller

---

## 🎯 Obiettivo

Rimuovere voci obsolete/duplicate dal menu contestuale Windows e creare un uninstaller completo per FolderTextMerger.

---

## 📋 Voci Rimosse

### Background Folder Menu (Click destro su spazio vuoto)

✅ **Rimosse con successo (4 voci)**:
1. "Crea Lista di File" - duplicato
2. "Crea Lista File" - duplicato
3. "Unisci e Copia Testi" - vecchia versione
4. "Unisci e Esporta Testi" - vecchia versione

**Registry location**: `HKEY_CLASSES_ROOT\Directory\Background\shell\`

### Folder Menu (Click destro su cartella)

✅ **Rimosse con successo (2 chiavi)**:
1. `HKEY_CLASSES_ROOT\Directory\shell\FolderTextMerger`
2. `HKEY_CURRENT_USER\Software\Classes\Directory\shell\FolderTextMerger`

**Motivo**: Voce obsoleta che puntava a eseguibile non più installato correttamente

---

## 🛠️ File Creati

### 1. `uninstaller.ps1` (NUOVO)

**Funzionalità**:
- Rimuove voce dal menu contestuale (HKCU/HKLM/HKCR)
- Elimina eseguibile dall'installazione
- Rimuove directory installazione (se vuota)
- Preserva log files (opzionale)
- Compatibile con installazioni user/admin

**Uso**:
```powershell
.\uninstaller.ps1
```

### 2. Script temporanei di pulizia

- `remove-old-context-menu.ps1` - Rimozione 4 voci obsolete
- `remove-foldertextmerger-context.ps1` - Rimozione FolderTextMerger

### 3. Analisi registro

- `menu-contestuale-completo.txt` - Elenco completo voci rilevate
- `analyze-context-menu.ps1` - Script analisi (non funzionante)
- `get-context-menu.ps1` - Script semplificato

---

## 🔍 Problema Identificato: Installer NON gestisce uninstall

### Analisi `installer.ps1`

**Cosa fa l'installer** (righe 82-105):
```powershell
# Registra menu contestuale
$ContextMenuKey = Join-Path $RegistryBase "Directory\shell\$ApplicationName"
New-Item -Path $ContextMenuKey -Force
Set-ItemProperty -Path $ContextMenuKey -Name "(Default)" -Value "Folder2Text – Convert folder to text"
Set-ItemProperty -Path $ContextMenuKey -Name "Icon" -Value $TargetExecutablePath
```

**Cosa MANCA**:
- ❌ Nessuno script di uninstall incluso
- ❌ Nessuna rimozione automatica voci registro
- ❌ Se disinstalli manualmente, le voci rimangono orfane

### Soluzione Implementata

✅ Creato `uninstaller.ps1` che:
- Rileva modalità installazione (user/admin)
- Rimuove chiavi da tutte le location possibili:
  - `HKLM:\Software\Classes\Directory\shell\FolderTextMerger`
  - `HKCU:\Software\Classes\Directory\shell\FolderTextMerger`
  - `HKCR:\Directory\shell\FolderTextMerger` (legacy)
- Rimuove file e cartelle
- Preserva log se presenti

---

## 📦 Backup Creati

Tutti i backup sono salvati in:
```
C:\Users\umber\Desktop\FolderTextMerger\registry-backup\
```

**File backup**:
```
20260108-000840-Crea Lista di File.reg
20260108-000840-Crea Lista File.reg
20260108-000840-Unisci e Copia Testi.reg
20260108-000840-Unisci e Esporta Testi.reg
20260108-000840-FolderTextMerger-HKCR_(System_Current_User).reg
20260108-000840-FolderTextMerger-HKCU_(Current_User).reg
```

**Ripristino** (se necessario):
```powershell
# Doppio click sul file .reg
# Oppure
reg import "backup-file.reg"
```

---

## 📚 Documentazione Aggiornata

### README.md

**Aggiunte**:
- Sezione "Automatic Installation" con `installer.ps1`
- Sezione "Uninstallation" con `uninstaller.ps1`
- Descrizione completa funzionalità uninstaller

**Path**: [README.md](README.md#-installation)

---

## ✅ Verifica Finale

### Stato attuale menu contestuale

**Folder Background** (spazio vuoto cartella):
- ✅ AnyCode
- ✅ cmd
- ✅ git_gui
- ✅ git_shell
- ✅ Powershell
- ✅ VSCode
- ✅ WSL

**Folder** (cartella):
- ✅ AddToPlaylistVLC
- ✅ AnyCode
- ✅ ArubaSign
- ✅ ArubaSignPlatform
- ✅ cmd
- ✅ find
- ✅ git_gui
- ✅ git_shell
- ✅ PlayWithVLC
- ✅ Powershell
- ✅ UpdateEncryptionSettings
- ✅ VSCode
- ✅ WinDirStat
- ✅ WSL

**Note**: FolderTextMerger e voci duplicate/obsolete sono state rimosse con successo.

---

## 🔄 Come Applicare le Modifiche

### 1. Riavvia Esplora Risorse

**Metodo 1 - Task Manager**:
1. `Ctrl+Shift+Esc`
2. Trova "Esplora risorse" / "Windows Explorer"
3. Click destro → Riavvia

**Metodo 2 - PowerShell**:
```powershell
Get-Process explorer | Stop-Process -Force
Start-Process explorer
```

**Metodo 3 - Logout/Login**:
- Logout da Windows
- Login di nuovo

### 2. Verifica Modifiche

- Click destro su una cartella → Menu dovrebbe essere pulito
- Click destro su spazio vuoto cartella → Voci duplicate rimosse
- FolderTextMerger non dovrebbe più apparire

---

## 🚀 Prossimi Passi

### Per lo sviluppatore

1. ✅ Testare `uninstaller.ps1` in ambiente pulito
2. ✅ Aggiungere `uninstaller.ps1` al repository
3. ✅ Documentare uninstaller nel README
4. ⚠️  Considerare integrazione con Windows Uninstall Programs
5. ⚠️  Creare installer MSI/EXE con tool come Inno Setup

### Per l'utente

1. ✅ Riavviare Esplora Risorse per vedere modifiche
2. ✅ Verificare che menu contestuale sia pulito
3. ✅ Se necessario reinstallare FolderTextMerger, usare:
   ```powershell
   .\installer.ps1
   ```
4. ✅ Per disinstallare in futuro, usare:
   ```powershell
   .\uninstaller.ps1
   ```

---

## 📊 Statistiche

**Chiavi registro rimosse**: 6
**Voci menu contestuale pulite**: 6
**Backup creati**: 6
**Script creati**: 3
**Documentazione aggiornata**: README.md

**Tempo operazione**: ~5 minuti
**Esito**: ✅ Successo completo

---

## ⚠️ Note Importanti

1. **I backup sono permanenti** - Non vengono cancellati automaticamente
2. **L'uninstaller preserva i log** - Cancellazione manuale se desiderato
3. **Installazioni multiple** - Se hai installato sia come user che admin, l'uninstaller gestisce entrambe
4. **Explorer restart richiesto** - Le modifiche al menu contestuale richiedono riavvio Explorer

---

**Report generato**: 2026-01-08
**Versione FolderTextMerger**: 1.1.0-rc4
**Status**: ✅ Pulizia completata con successo
