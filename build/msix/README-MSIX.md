# MSIX Package Creation - TODO

## Quando creare il pacchetto MSIX

Il pacchetto MSIX è **obbligatorio** per pubblicare su Microsoft Store, ma **non ancora necessario** per la distribuzione diretta agli amici.

## Prima di iniziare

### Prerequisiti

1. **Windows 10 SDK** (include MakeAppx.exe e SignTool.exe)
   - Download: https://developer.microsoft.com/windows/downloads/windows-sdk/
   - Path tipico: `C:\Program Files (x86)\Windows Kits\10\bin\10.0.xxxxx.0\x64\`

2. **Account Microsoft Developer**
   - Registrazione: https://partner.microsoft.com/dashboard
   - Costo: €19 una tantum (gratuito per studenti/startup)

3. **Certificato di firma digitale**
   - Per Store: fornito automaticamente da Microsoft dopo registrazione
   - Per distribuzione diretta: puoi creare certificato self-signed (gli utenti vedranno warning)

### File necessari

- `AppxManifest.xml` - Manifest MSIX con metadati applicazione
- `Assets/` - Icons (44x44, 150x150, 310x310 px)
- Script PowerShell per packaging automatico

## Procedura completa

### Step 1: Creare AppxManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities">

  <Identity Name="FolderTextMerger"
            Publisher="CN=YourPublisher"
            Version="1.0.4.0" />

  <Properties>
    <DisplayName>FolderTextMerger</DisplayName>
    <PublisherDisplayName>Your Name</PublisherDisplayName>
    <Logo>Assets\StoreLogo.png</Logo>
  </Properties>

  <Dependencies>
    <TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.17763.0" MaxVersionTested="10.0.19041.0" />
  </Dependencies>

  <Resources>
    <Resource Language="en-us" />
    <Resource Language="it-it" />
  </Resources>

  <Applications>
    <Application Id="FolderTextMerger" Executable="FolderTextMerger.exe" EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements DisplayName="FolderTextMerger"
                          Description="Merge multiple text files into one"
                          BackgroundColor="transparent"
                          Square150x150Logo="Assets\Square150x150Logo.png"
                          Square44x44Logo="Assets\Square44x44Logo.png">
      </uap:VisualElements>

      <Extensions>
        <!-- Context menu registration -->
        <uap:Extension Category="windows.fileTypeAssociation">
          <uap:FileTypeAssociation Name="foldertextmerger">
            <uap:SupportedFileTypes>
              <uap:FileType>.txt</uap:FileType>
              <uap:FileType>.py</uap:FileType>
              <uap:FileType>.java</uap:FileType>
              <!-- Add all supported extensions from config -->
            </uap:SupportedFileTypes>
          </uap:FileTypeAssociation>
        </uap:Extension>
      </Extensions>
    </Application>
  </Applications>

  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
    <Capability Name="internetClient" />
  </Capabilities>
</Package>
```

### Step 2: Preparare Assets

Creare icone nelle dimensioni richieste:
- `Square44x44Logo.png` (44×44 px)
- `Square150x150Logo.png` (150×150 px)
- `StoreLogo.png` (50×50 px)
- `Wide310x150Logo.png` (310×150 px) - opzionale

Usare tool come: https://www.img2go.com/resize-image

### Step 3: Creare certificato self-signed (solo per test)

```powershell
# Crea certificato self-signed
New-SelfSignedCertificate `
    -Type Custom `
    -Subject "CN=YourName" `
    -KeyUsage DigitalSignature `
    -FriendlyName "FolderTextMerger" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")

# Export certificato
$cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.Subject -match "YourName"}
$pwd = ConvertTo-SecureString -String "YourPassword" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "FolderTextMerger.pfx" -Password $pwd
```

### Step 4: Packaging con MakeAppx

```powershell
# Path SDK
$SDKPath = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64"
$MakeAppx = "$SDKPath\makeappx.exe"
$SignTool = "$SDKPath\signtool.exe"

# Crea package
& $MakeAppx pack /d "PackageFiles" /p "FolderTextMerger_1.0.4.0_x64.msix" /o

# Firma package
& $SignTool sign /fd SHA256 /a /f "FolderTextMerger.pfx" /p "YourPassword" "FolderTextMerger_1.0.4.0_x64.msix"
```

### Step 5: Script completo di automazione

Creare `build-msix.ps1` in questa cartella:

```powershell
# Leggi versione da FolderTextMerger.py
$Version = "1.0.4.0"

# Prepara struttura
$PackageDir = "PackageFiles"
New-Item -ItemType Directory -Path $PackageDir -Force

# Copia files
Copy-Item "../../dist/exe/FolderTextMerger.exe" $PackageDir
Copy-Item "../../config" $PackageDir -Recurse
Copy-Item "AppxManifest.xml" $PackageDir
Copy-Item "Assets" $PackageDir -Recurse

# Build package
$SDKPath = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64"
& "$SDKPath\makeappx.exe" pack /d $PackageDir /p "../../dist/msix/FolderTextMerger_${Version}_x64.msix" /o

# Sign package (se certificato disponibile)
if (Test-Path "FolderTextMerger.pfx") {
    & "$SDKPath\signtool.exe" sign /fd SHA256 /a /f "FolderTextMerger.pfx" /p "password" "../../dist/msix/FolderTextMerger_${Version}_x64.msix"
}

Write-Host "MSIX package created successfully!"
```

## Pubblicazione su Microsoft Store

### 1. Registrazione Developer Account
- Vai su https://partner.microsoft.com/dashboard
- Registrati come sviluppatore individuale o aziendale
- Paga €19 (o usa voucher studente)

### 2. Creare app nel Partner Center
- Dashboard → Apps and games → New product
- Inserisci nome app: "FolderTextMerger"
- Riserva nome

### 3. Configurare app
- **Product listings**: descrizione, screenshot, icone
- **Pricing and availability**: gratuito o a pagamento
- **Properties**: categoria, requisiti di sistema
- **Age ratings**: IARC rating
- **Packages**: upload MSIX firmato

### 4. Certificazione
Microsoft rivede l'app (2-3 giorni lavorativi):
- Verifica sicurezza
- Controllo contenuti
- Test funzionalità

### 5. Pubblicazione
Dopo approvazione, l'app è disponibile nello Store!

## Alternative per distribuzione diretta (senza Store)

### Opzione 1: MSIX non firmato
Gli utenti possono installare, ma vedranno warning di sicurezza.

### Opzione 2: Certificato self-signed
Gli utenti devono installare il certificato prima del package:
```powershell
# Installa certificato (come admin)
Import-Certificate -FilePath "FolderTextMerger.cer" -CertStoreLocation Cert:\LocalMachine\TrustedPeople
```

### Opzione 3: Usa Inno Setup (CONSIGLIATO per amici)
Crea installer EXE tradizionale (vedi `../innosetup/`).

## Link utili

- **MSIX Documentation**: https://docs.microsoft.com/windows/msix/
- **Partner Center Dashboard**: https://partner.microsoft.com/dashboard
- **MSIX Packaging Tool**: https://www.microsoft.com/store/productId/9N5LW3JBCXKF
- **App Installer**: https://www.microsoft.com/p/app-installer/9nblggh4nns1

## Note importanti

- **MSIX è sandboxed**: alcune operazioni potrebbero richiedere permessi speciali
- **Context menu**: richiede capability `runFullTrust`
- **Versioning**: formato X.Y.Z.0 (4 numeri obbligatori)
- **File size**: Store accetta fino a 25 GB
- **Aggiornamenti**: gestiti automaticamente da Windows

## Status

- ⏳ **TODO**: Da implementare quando pronto per Microsoft Store
- ✅ **Alternative disponibili**: Inno Setup (EXE installer) per distribuzione diretta
- ✅ **Distribuzione attuale**: ZIP con PowerShell installer

---

**Ultimo aggiornamento**: 2026-01-09
**Versione app**: 1.0.4
