# OverlayBurner - Windows Edition

A Windows application that automatically overlays camera metadata (camera name, date, and timestamp) onto security camera videos by extracting H.264 SEI (Supplemental Enhancement Information) data.

## Overview

OverlayBurner processes security camera MP4 videos and burns in metadata overlays at the lower-left corner of each frame. The overlay includes:
- Camera name (e.g., "Front Parking 2")
- Date in MM-DD-YYYY format (extracted from filename)
- Dynamic timestamp in HH:MM:SS format (synchronized with video playback)

The application uses H.264 SEI binary data embedded in the video stream to extract accurate frame-by-frame timestamps and camera identification.

## Features

- **Dynamic timestamp overlay** - Time updates correctly for each frame (not static)
- **Batch processing** - Process entire folders or select specific files
- **Skip duplicates** - Automatically skips files that have already been processed
- **Progress tracking** - Live Command Prompt window shows processing progress with ETA
- **Flexible selection** - Choose folders or individual files via Windows file picker
- **Same-directory output** - Processed files saved to `with_overlay\` subfolder

## Requirements

- Windows 10 or Windows 11
- Python 3.8+ (for building only - not required for end users)
- FFmpeg (bundled inside executable after build - download once for building)

## Project Structure

```
windows/
├── OverlayBurner.bat      # Main launcher (double-click to run)
├── OverlayBurner.exe      # Self-contained executable with bundled ffmpeg
├── ffmpeg.exe             # FFmpeg binary (needed for build, bundled into .exe)
├── rebuild.bat            # Build script (bundles ffmpeg into .exe)
└── overlay_env/           # Python virtual environment (auto-created)
```

## Setup

### First-Time Setup on Windows

1. **Transfer files to your Windows machine**
   - Copy the entire `client_overlay` folder to your Windows machine

2. **Download FFmpeg for Windows**
   - Visit: https://www.gyan.dev/ffmpeg/builds/
   - Download: **ffmpeg-release-essentials.zip** (or **ffmpeg-git-essentials.7z**)
   - Extract the archive
   - Copy `ffmpeg.exe` from the `bin` folder to `client_overlay\windows\`
   - **Note**: This is only needed once for building. The build script will bundle ffmpeg inside the .exe

3. **Install Python 3.8+** (if not already installed)
   - Download from: https://www.python.org/downloads/
   - During installation, **check "Add Python to PATH"**
   - Verify: Open Command Prompt and type `python --version`

4. **Build the executable**
   - Navigate to `client_overlay\windows\`
   - Double-click `rebuild.bat`
   - Wait for the build to complete (1-2 minutes)
   - This will create `OverlayBurner.exe` with ffmpeg bundled inside

5. **The app is ready to use!**
   - Double-click `OverlayBurner.bat` to launch

### Rebuilding After Changes

After modifying the Python code in `common\overlay_burner.py`:

1. Navigate to `client_overlay\windows\`
2. Double-click `rebuild.bat`
3. Wait for rebuild to complete

## Usage

### Running the App

1. **Double-click `OverlayBurner.bat`**

2. **Choose selection method:**
   - **Browse Files** - Select specific `.mp4` files to process
   - **Browse Folders** - Select a folder to process all `.mp4` files

3. **Select your videos:**
   - Multiple files can be selected (Ctrl+Click or Shift+Click)
   - All selected files should be from the same directory

4. **Watch progress:**
   - A Command Prompt window will show live progress
   - Displays current file, progress bar, success/skip/fail counts, and ETA
   - Window auto-closes after 3 seconds when complete

5. **Find processed videos:**
   - Output files saved to `with_overlay\` subfolder
   - Original filename with `_overlay.mp4` suffix
   - Example: `cam1-20251114150213.mp4` → `cam1-20251114150213_overlay.mp4`

### File Naming Convention

Videos must follow this naming pattern for date extraction:
```
cam1-YYYYMMDDHHMMSS.mp4
```
Example: `cam1-20251114150213.mp4` (November 14, 2025, 3:02:13 PM)

If the filename doesn't match this pattern, the date will show as "Unknown Date".

## Technical Details

### H.264 SEI Parsing

The application searches for SEI (Supplemental Enhancement Information) NAL units in H.264 video streams using a specific binary pattern:

```
0xaa 0xff (repeated 8 times)
0xaa 0xaa 0xab 0xb2
```

Camera metadata is extracted from byte offsets:
- Byte 27: Camera name (null-terminated string)
- Byte 24-25: Timestamp (2-byte little-endian, seconds since midnight)

### FFmpeg Overlay

The timestamp overlay uses FFmpeg's `drawtext` filter with expression-based time calculation:

```bash
drawtext=text='Camera Name'
drawtext=text='MM-DD-YYYY'
drawtext=text='%{eif\:mod(trunc((START_SECONDS+t)/3600)\,24)\:d\:2}:%{eif\:mod(trunc((START_SECONDS+t)/60)\,60)\:d\:2}:%{eif\:mod(trunc(START_SECONDS+t)\,60)\:d\:2}'
```

This creates a dynamic timestamp that updates frame-by-frame based on the video's current playback position.

### Output Format

- Codec: H.264 (libx264)
- Preset: ultrafast
- CRF: 23
- Audio: Copy (original audio stream preserved)

## Troubleshooting

### "Python is not installed or not in PATH"

Install Python 3.8+ and ensure "Add Python to PATH" is checked during installation.

Verify: Open Command Prompt and type:
```cmd
python --version
```

### "ffmpeg.exe not found"

Download FFmpeg:
1. Visit: https://www.gyan.dev/ffmpeg/builds/
2. Download: ffmpeg-release-essentials.zip
3. Extract `ffmpeg.exe` from `bin` folder
4. Place in `client_overlay\windows\` directory
5. Rebuild the application

### Permission Errors

If the app can't create the `with_overlay\` folder:
- Check folder permissions
- Try running from a different directory
- Run Command Prompt as Administrator

### Videos Not Found

- Ensure files are `.mp4` format
- Check that files don't already have `_overlay.mp4` in the name
- Verify all selected files are from the same directory

### Build Fails

If `rebuild.bat` fails:
1. Ensure Python is installed and in PATH
2. Close any antivirus software temporarily (may block PyInstaller)
3. Delete `overlay_env` folder and run `rebuild.bat` again
4. Check `%TEMP%\overlay_debug.txt` for error details

## Debug Logs

Debug information is saved to:
- `%TEMP%\overlay_debug.txt` - Batch script execution log
- `%TEMP%\overlay_burner_progress.txt` - Command Prompt progress display

To view:
```cmd
notepad %TEMP%\overlay_debug.txt
```

## Differences from macOS Version

- **Launcher**: `.bat` file instead of `.app` bundle
- **File dialogs**: Windows Forms instead of AppleScript
- **Progress window**: Command Prompt instead of Terminal
- **Paths**: Backslashes (`\`) instead of forward slashes (`/`)
- **Temp directory**: `%TEMP%` instead of `/tmp`

## Building for Distribution

To create a portable version for other Windows machines:

1. Build the executable: `rebuild.bat` (ffmpeg gets bundled inside automatically)
2. Create a folder named `OverlayBurner`
3. Copy ONLY these files into it:
   - `OverlayBurner.bat`
   - `OverlayBurner.exe` (self-contained with ffmpeg inside)
4. Zip the folder
5. Distribute the ZIP file

Users can unzip and double-click `OverlayBurner.bat` - **no Python, no FFmpeg installation needed**!

The executable is completely self-contained with ffmpeg bundled inside.

## Python Dependencies

The application uses only Python standard library modules:
- `sys`, `subprocess`, `struct`, `time`, `os`, `platform`, `pathlib`, `re`

PyInstaller bundles all dependencies into the `.exe` file.

## System Requirements

- **OS**: Windows 10 (64-bit) or Windows 11
- **RAM**: 4GB minimum, 8GB recommended
- **Disk Space**: 200MB for application + space for processed videos
- **CPU**: Any modern Intel/AMD processor

## License

[Add your license information here]

## Credits

Developed for processing security camera footage with embedded H.264 SEI metadata.

---

**For macOS version**: See `README.md` in the project root.
