# Creating the Windows Installer

This guide shows you how to create a single-file installer for OverlayBurner using Inno Setup.

## Prerequisites

1. **Build the executable first**:
   ```cmd
   cd windows\
   rebuild.bat
   ```
   This creates `OverlayBurner.exe` with ffmpeg bundled inside.

2. **Download Inno Setup** (one-time setup):
   - Visit: https://jrsoftware.org/isinfo.php
   - Download: **Inno Setup 6.x** (latest version)
   - Install Inno Setup on your Windows machine
   - Free and open-source

## Creating the Installer

### Method 1: Right-Click Compile (Easiest)

1. Navigate to `client_overlay\windows\` in File Explorer
2. Right-click `OverlayBurner_Setup.iss`
3. Select **"Compile"**
4. Wait for compilation to complete (30-60 seconds)
5. Find the installer in: `windows\Output\OverlayBurner_Setup.exe`

### Method 2: Using Inno Setup GUI

1. Open Inno Setup Compiler
2. Click **File → Open**
3. Select `OverlayBurner_Setup.iss`
4. Click **Build → Compile** (or press F9)
5. Find the installer in: `windows\Output\OverlayBurner_Setup.exe`

### Method 3: Command Line

```cmd
cd windows\
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" OverlayBurner_Setup.iss
```

## Installer Details

The created installer (`OverlayBurner_Setup.exe`) will:

✅ **Install to**: `C:\Program Files\OverlayBurner\`
✅ **Create shortcuts**:
   - Start Menu: `OverlayBurner`
   - Desktop (optional, user choice)
✅ **Include files**:
   - `OverlayBurner.bat` (launcher)
   - `OverlayBurner.exe` (self-contained with ffmpeg)
   - `README.md` (documentation)
✅ **Add uninstaller**: Accessible from Windows Settings → Apps
✅ **Size**: ~85 MB (includes everything)

## Customizing the Installer

Edit `OverlayBurner_Setup.iss` to customize:

### Company/Publisher Information

```ini
#define MyAppPublisher "Your Company Name"
#define MyAppURL "https://yourwebsite.com"
```

### Version Number

```ini
#define MyAppVersion "1.0"
```

### Icon

Update the icon file path (currently uses `overlayburner.png`):

```ini
SetupIconFile=..\overlayburner.png
```

Or create/use a `.ico` file for better quality.

### Installation Directory

Change default install location:

```ini
DefaultDirName={autopf}\{#MyAppName}  ; Current: C:\Program Files\OverlayBurner
```

### Desktop Icon

Desktop shortcut is currently **optional** (user chooses during install).
To make it default:

```ini
Name: "desktopicon"; ...; Flags: unchecked  ; Remove 'unchecked' to enable by default
```

## Distribution

After creating the installer:

1. **Test it**:
   - Run `OverlayBurner_Setup.exe` on a clean Windows machine
   - Verify installation works
   - Test the app processes videos correctly

2. **Distribute**:
   - Upload to your website, file sharing service, etc.
   - Users download ONE file: `OverlayBurner_Setup.exe` (~85 MB)
   - Double-click to install
   - No Python, no FFmpeg, no additional setup required!

## Signing the Installer (Optional)

For professional distribution, you can digitally sign the installer:

1. Obtain a code signing certificate
2. Use `signtool.exe` to sign the installer:
   ```cmd
   signtool sign /f YourCertificate.pfx /p password /t http://timestamp.digicert.com OverlayBurner_Setup.exe
   ```

This removes Windows SmartScreen warnings.

## Rebuilding After Code Changes

When you update the code:

1. Run `rebuild.bat` to rebuild `OverlayBurner.exe`
2. Update version number in `OverlayBurner_Setup.iss`
3. Compile the installer again
4. Distribute the new `OverlayBurner_Setup.exe`

## Troubleshooting

### "Cannot find OverlayBurner.exe"

Ensure you ran `rebuild.bat` first to create the executable.

### Installer won't compile

Check that all source files exist:
- `OverlayBurner.bat`
- `OverlayBurner.exe`
- `README.md`

### Installer too large

This is expected - ffmpeg is bundled inside `OverlayBurner.exe` (~80 MB).
The installer uses maximum compression (`lzma2/ultra64`).

### Windows SmartScreen warning

This is normal for unsigned installers. Options:
1. Digitally sign the installer (recommended for distribution)
2. Users can click "More info" → "Run anyway"
3. Build reputation by distributing the same signed installer

## File Structure

After installation, users will have:

```
C:\Program Files\OverlayBurner\
├── OverlayBurner.bat      # Launcher
├── OverlayBurner.exe      # Main executable (self-contained)
├── README.md              # Documentation
└── unins000.exe          # Uninstaller (auto-created)
```

## Uninstallation

Users can uninstall via:
- Windows Settings → Apps → OverlayBurner → Uninstall
- Start Menu → OverlayBurner → Uninstall
- Control Panel → Programs and Features

All files and shortcuts are automatically removed.

## Advanced: Silent Installation

For IT deployments, the installer supports silent mode:

```cmd
OverlayBurner_Setup.exe /SILENT
```

Or completely silent:

```cmd
OverlayBurner_Setup.exe /VERYSILENT
```

Custom install directory:

```cmd
OverlayBurner_Setup.exe /DIR="C:\CustomPath\OverlayBurner" /SILENT
```

---

**Need help?** See the Inno Setup documentation: https://jrsoftware.org/ishelp/
