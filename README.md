# OverlayBurner - Cross-Platform Video Overlay Tool

Automatically overlay camera metadata (camera name, date, and dynamic timestamp) onto security camera videos by extracting H.264 SEI (Supplemental Enhancement Information) data.

## Platform Support

This project supports both **macOS** and **Windows** with platform-specific implementations:

- **macOS Version**: See `mac/README.md`
- **Windows Version**: See `windows/README.md`

## Quick Start

### For macOS Users

```bash
cd mac/
python3 rebuild.py
# Then double-click OverlayBurner.app
```

### For Windows Users

```cmd
cd windows\
rebuild.bat
REM Then double-click OverlayBurner.bat
```

## Project Structure

```
client_overlay/
├── README.md                  # This file
├── common/                    # Shared cross-platform code
│   └── overlay_burner.py      # Platform-independent Python logic
├── mac/                       # macOS-specific files
│   ├── README.md              # macOS setup instructions
│   ├── OverlayBurner.app/     # macOS application bundle
│   ├── automator_shell_script # macOS launcher script
│   ├── rebuild.py             # macOS build script
│   └── ffmpeg                 # macOS FFmpeg binary (x86_64)
└── windows/                   # Windows-specific files
    ├── README.md              # Windows setup instructions
    ├── OverlayBurner.bat      # Windows launcher
    ├── rebuild.bat            # Windows build script
    └── ffmpeg.exe             # Windows FFmpeg binary (download separately)
```

## Features

- **Dynamic timestamp overlay** - Time updates frame-by-frame (not static)
- **Batch processing** - Process folders or individual files
- **Skip duplicates** - Automatically skips previously processed videos
- **Live progress tracking** - Real-time progress display with ETA
- **Cross-platform** - Identical functionality on macOS and Windows
- **Same-directory output** - Creates `with_overlay/` subfolder

## How It Works

1. **SEI Data Extraction**: Parses H.264 SEI NAL units to extract camera name and timestamp
2. **FFmpeg Processing**: Uses drawtext filter with expression-based dynamic timestamps
3. **Overlay Generation**: Burns three-line overlay (camera, date, time) at lower-left corner

### Metadata Format

- **Camera Name**: Extracted from byte 27 of SEI payload
- **Timestamp**: 2-byte little-endian value at byte 24 (seconds since midnight)
- **Date**: Extracted from filename pattern `YYYYMMDD`

### Overlay Layout

```
Camera Name        ← Lower-left corner
MM-DD-YYYY         ← +60px above
HH:MM:SS (dynamic) ← +120px above
```

## Development

### Shared Code

The core processing logic in `common/overlay_burner.py` uses Python's `platform` module for cross-platform compatibility:

- **Path handling**: Uses `pathlib.Path` for universal path operations
- **FFmpeg location**: Detects platform and adjusts binary path
- **Font selection**: Platform-specific font paths (macOS vs Windows)
- **Progress display**: Platform-specific window management

### Platform-Specific Wrappers

- **macOS**: Automator application with AppleScript dialogs and Terminal progress
- **Windows**: Batch file with PowerShell dialogs and CMD progress window

### Building for Both Platforms

**On macOS:**
```bash
cd mac/
python3 rebuild.py
```

**On Windows:**
```cmd
cd windows\
rebuild.bat
```

## Requirements

### macOS
- macOS 10.13+ (High Sierra or newer)
- Python 3.x (for building)
- Rosetta 2 (for Apple Silicon Macs)
- FFmpeg (included)

### Windows
- Windows 10/11
- Python 3.8+ (for building)
- FFmpeg (download separately)

## Testing

Test videos should follow this naming pattern:
```
cam1-YYYYMMDDHHMMSS.mp4
```

Example: `cam1-20251114150213.mp4`

## Compatibility Notes

### macOS
- **Intel Macs**: Native execution
- **Apple Silicon (M1/M2/M3/M4)**: Runs via Rosetta 2 (auto-installed on first run)

### Windows
- **64-bit Windows 10/11**: Fully supported
- **32-bit systems**: Not tested (may require rebuilding with 32-bit Python)

## Troubleshooting

See platform-specific README files:
- `mac/README.md` - macOS troubleshooting
- `windows/README.md` - Windows troubleshooting

## Contributing

When contributing code:
1. Keep shared logic in `common/overlay_burner.py`
2. Platform-specific code goes in `mac/` or `windows/`
3. Test on both platforms before committing
4. Update both READMEs if functionality changes

## License

[Add your license information here]

## Credits

Developed for processing security camera footage with embedded H.264 SEI metadata.

Cross-platform support for macOS and Windows.
