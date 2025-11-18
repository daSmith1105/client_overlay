# Windows Setup Instructions

## What You Need to Do on Your Windows Machine

### 1. Transfer Files
Copy the entire `client_overlay` folder to your Windows machine via:
- USB drive
- Network share
- Cloud storage (Dropbox, OneDrive, etc.)
- Git repository

### 2. Download FFmpeg for Windows
1. Visit: https://www.gyan.dev/ffmpeg/builds/
2. Download: **ffmpeg-release-essentials.zip** (or ffmpeg-git-essentials.7z)
3. Extract the archive
4. Navigate to the `bin` folder inside
5. Copy `ffmpeg.exe` to: `client_overlay\windows\`

**IMPORTANT**: You must download ffmpeg.exe BEFORE running rebuild.bat. The build script will bundle ffmpeg.exe inside the executable automatically.

### 3. Install Python (if not already installed)
1. Download from: https://www.python.org/downloads/
2. Run installer
3. **IMPORTANT**: Check "Add Python to PATH" during installation
4. Verify installation:
   - Open Command Prompt
   - Type: `python --version`
   - Should show Python 3.8 or higher

### 4. Build the Application
1. Open File Explorer
2. Navigate to: `client_overlay\windows\`
3. Double-click: `rebuild.bat`
4. Wait for build to complete (1-2 minutes)
5. You should see "BUILD SUCCESSFUL!" message

### 5. (Optional) Create Installer for Distribution
If you want to create a professional installer:
1. Download and install Inno Setup from: https://jrsoftware.org/isinfo.php
2. Right-click `OverlayBurner_Setup.iss` and select "Compile"
3. Find the installer in: `windows\Output\OverlayBurner_Setup.exe`
4. See `CREATE_INSTALLER.md` for detailed instructions

**Note**: This step is optional. You can distribute just the `.bat` and `.exe` files without creating an installer.

### 6. Run the Application
1. In `client_overlay\windows\`
2. Double-click: `OverlayBurner.bat`
3. Choose "Browse Files" or "Browse Folders"
4. Select your videos
5. Watch the progress window
6. Find processed videos in `with_overlay\` subfolder

## File Checklist

After building, your `windows` folder should contain:
- ✅ `OverlayBurner.bat` (launcher - double-click this to run)
- ✅ `OverlayBurner.exe` (self-contained executable with ffmpeg bundled inside)
- ✅ `ffmpeg.exe` (used during build, kept for future rebuilds)
- ✅ `rebuild.bat` (build script)
- ✅ `README.md` (Windows documentation)
- ✅ `overlay_env\` (Python virtual environment - auto-created)

**Note**: The built `OverlayBurner.exe` has ffmpeg bundled inside, so you only need to distribute the .bat and .exe files!

## Testing

Use a test video named like: `cam1-20251114150213.mp4`

Expected output:
- File: `with_overlay\cam1-20251114150213_overlay.mp4`
- Overlay at lower-left showing:
  - Camera name
  - Date (MM-DD-YYYY)
  - Dynamic time (HH:MM:SS)

## Troubleshooting

### "Python is not installed or not in PATH"
- Reinstall Python and check "Add Python to PATH"
- Or add Python manually to PATH in System Environment Variables

### "ffmpeg.exe not found"
- Download FFmpeg from https://www.gyan.dev/ffmpeg/builds/
- Extract and copy `ffmpeg.exe` to `windows\` folder
- Run `rebuild.bat` again

### Build fails with PyInstaller error
- Close antivirus software temporarily
- Delete `overlay_env` folder
- Run `rebuild.bat` again

### Videos not processing
- Check `%TEMP%\overlay_debug.txt` for errors
- Ensure videos are named correctly (YYYYMMDD format)
- Verify videos contain H.264 SEI metadata

## Distribution

To share with other Windows users:
1. Build the application (ffmpeg gets bundled inside)
2. Create a folder containing ONLY:
   - `OverlayBurner.bat`
   - `OverlayBurner.exe`
3. Zip the folder
4. Others can unzip and run without Python OR FFmpeg installation!

The executable is completely self-contained with ffmpeg bundled inside.

## Questions?

See `windows/README.md` for detailed documentation.
