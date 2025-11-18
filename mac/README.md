# OverlayBurner

A macOS application that automatically overlays camera metadata (camera name, date, and timestamp) onto security camera videos by extracting H.264 SEI (Supplemental Enhancement Information) data.

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
- **Progress tracking** - Live Terminal window shows processing progress with ETA
- **Flexible selection** - Choose folders or individual files via macOS file picker
- **Same-directory output** - Processed files saved to `with_overlay/` subfolder

## Requirements

- macOS 10.13+ (High Sierra or newer)
- **Apple Silicon Macs (M1/M2/M3/M4)**: Rosetta 2 required (automatically prompted for installation)
- **Intel Macs**: No additional requirements
- Python 3.x (for building only - not required for end users)
- FFmpeg 8.0+ (included in repository)
- PyInstaller (automatically installed by rebuild script)

## Compatibility

### Architecture Support

This application is built with **x86_64 (Intel)** binaries and will run on:

✅ **Intel Macs** - Native execution, all macOS versions 10.13+

✅ **Apple Silicon Macs (M1/M2/M3/M4)** - Runs via Rosetta 2 translation layer
- Rosetta 2 will be automatically prompted for installation on first run
- Performance is excellent under Rosetta 2 (negligible difference from native)

### First Run on Apple Silicon

When you first launch the app on an Apple Silicon Mac without Rosetta 2:
1. A dialog will ask permission to install Rosetta 2
2. Click "Install Rosetta" 
3. Wait for installation to complete (1-2 minutes)
4. Run the app again

### Manual Rosetta 2 Installation

If needed, you can install Rosetta 2 manually via Terminal:
```bash
softwareupdate --install-rosetta --agree-to-license
```

## Project Structure

```
client_overlay/
├── overlay_burner.py          # Main Python script
├── automator_shell_script     # Automator wrapper script
├── rebuild                    # Build script (creates app bundle)
├── ffmpeg                     # FFmpeg binary (80MB)
├── OverlayBurner.app/        # macOS application bundle
│   └── Contents/
│       └── Resources/
│           ├── OverlayBurner  # PyInstaller executable
│           └── ffmpeg         # FFmpeg binary (copied during build)
└── overlay_env/              # Python virtual environment (auto-created)
```

## Setup

### First-Time Setup

1. **Clone or download this repository**
   ```bash
   cd /path/to/client_overlay
   ```

2. **Run the rebuild script** (this will set up everything automatically)
   ```bash
   python3 rebuild.py
   ```
   
   The rebuild script will:
   - Create a Python virtual environment (`overlay_env/`)
   - Install PyInstaller
   - Build the executable
   - Copy files to the app bundle
   - Copy FFmpeg to the app bundle

3. **The app is ready to use!**
   - Double-click `OverlayBurner.app` to launch

### FFmpeg Note

The `ffmpeg` binary (80MB) must be present in the repository root. If it's missing:
- Download FFmpeg 8.0+ static build for macOS
- Place the `ffmpeg` binary in the `client_overlay/` directory
- Run `python3 rebuild.py` again

## Usage

### Running the App

1. **Double-click `OverlayBurner.app`**

2. **Choose selection method:**
   - **Browse Folders** - Select one or more folders to process all `.mp4` files
   - **Browse Files** - Select specific `.mp4` files to process

3. **Select your videos:**
   - All selected files must be from the same directory
   - The app will recursively search folders for `.mp4` files

4. **Watch progress:**
   - A Terminal window will show live progress
   - Displays current file, progress bar, success/skip/fail counts, and ETA

5. **Find processed videos:**
   - Output files saved to `with_overlay/` subfolder
   - Original filename with `_overlay.mp4` suffix
   - Example: `cam1-20251114150213.mp4` → `cam1-20251114150213_overlay.mp4`

### File Naming Convention

Videos must follow this naming pattern for date extraction:
```
cam1-YYYYMMDDHHMMSS.mp4
```
Example: `cam1-20251114150213.mp4` (November 14, 2025, 3:02:13 PM)

If the filename doesn't match this pattern, the date will show as "Unknown Date".

## Development

### Rebuilding After Changes

After modifying `overlay_burner.py` or other files:

```bash
python3 rebuild.py
```

This will rebuild the executable and update the app bundle.

### Updating Automator Script

If you modify `automator_shell_script`:

1. Open `OverlayBurner.app` with Automator (right-click → Open With → Automator)
2. Replace the shell script content with your updated script
3. Save and close Automator

### Project Files

- **`overlay_burner.py`** - Main processing logic, SEI parsing, FFmpeg integration
- **`automator_shell_script`** - Shell wrapper that handles file selection dialogs
- **`rebuild.py`** - Automated build script
- **`ffmpeg`** - FFmpeg binary for video processing

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

### Rosetta 2 Not Installed (Apple Silicon Macs Only)

If you see an error about Rosetta 2:
1. The app will automatically prompt you to install it
2. Click "Install Rosetta" and wait for installation
3. Alternatively, install manually: `softwareupdate --install-rosetta --agree-to-license`
4. Run the app again after installation

### Terminal Window Doesn't Close

Check Terminal Preferences:
1. Open Terminal → Preferences
2. Select your profile (usually "Basic")
3. Go to "Shell" tab
4. Set "When the shell exits" to "Close if the shell exited cleanly"

### Permission Errors

If the app can't create the `with_overlay/` folder:
- Check folder permissions
- Try running from a different directory
- Ensure you have write access to the video directory

### Videos Not Found

- Ensure files are `.mp4` format
- Check that files don't already have `_overlay.mp4` in the name
- Verify all selected files are from the same directory

### FFmpeg Not Found Error

```
FileNotFoundError: [Errno 2] No such file or directory: '.../ffmpeg'
```

Solution:
1. Ensure `ffmpeg` binary is in the repository root
2. Run `python3 rebuild.py` to copy it to the app bundle

## Debug Logs

Debug information is saved to:
- `/tmp/overlay_debug.txt` - Shell script execution log
- `/tmp/overlay_burner.log` - Python processing log
- `/tmp/overlay_burner_progress.txt` - Terminal progress display
