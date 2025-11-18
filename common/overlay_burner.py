import sys
import subprocess
import struct
import time
import os
import platform
from pathlib import Path

# Determine ffmpeg path based on platform and execution mode
if getattr(sys, 'frozen', False):
    # Running as PyInstaller bundle
    if platform.system() == 'Windows':
        # On Windows, ffmpeg.exe is bundled in _MEIPASS (temp extraction folder)
        if hasattr(sys, '_MEIPASS'):
            FFMPEG_PATH = str(Path(sys._MEIPASS) / "ffmpeg.exe")
        else:
            # Fallback to same directory as executable
            FFMPEG_PATH = str(Path(sys.executable).parent / "ffmpeg.exe")
    else:
        # On macOS, ffmpeg is in the same dir as executable
        FFMPEG_PATH = str(Path(sys.executable).parent / "ffmpeg")
else:
    # Running as script - ffmpeg is in platform-specific directory
    if platform.system() == 'Windows':
        FFMPEG_PATH = str(Path(__file__).parent.parent / "windows" / "ffmpeg.exe")
    else:
        FFMPEG_PATH = str(Path(__file__).parent.parent / "mac" / "ffmpeg")

LOG_FILE = Path(sys.executable).with_name("overlay_log.txt") if getattr(sys, 'frozen', False) else Path("overlay_log.txt")

def log(msg):
    line = f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {msg}"
    print(line)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except: pass

def user_pause(title, msg):
    log(f"{title}: {msg}")
    try:
        input("\nPress Enter to close...")
    except (EOFError, OSError):
        # Running from Automator - no interactive terminal
        pass

def find_sei(data, debug=False):
    pos = 0
    sei_found = 0
    while True:
        s = data.find(b'\x00\x00\x00\x01\x06\x05', pos)
        if s == -1: break
        sei_found += 1
        off = s + 6
        size = 0
        while off < len(data) and data[off] == 0xFF:
            size += 255
            off += 1
        if off >= len(data): break
        size += data[off]
        off += 1
        payload = data[off:off + size]

        if debug and sei_found <= 3:
            log(f"  SEI #{sei_found}: size={size}, first 40 bytes: {payload[:40].hex()}")
            # Add detailed check
            log(f"    Check pattern: payload[0:16]=={b'\\xaa\\xff'*8}: {payload[0:16] == b'\\xaa\\xff'*8}")
            log(f"    Check pattern: payload[16:18]=={b'\\xaa\\xaa'}: {payload[16:18] == b'\\xaa\\xaa'}")
            log(f"    Check pattern: payload[18]==0xab: {payload[18] == 0xab if len(payload) > 18 else 'too short'}")
            log(f"    Check pattern: payload[19]==0xb2: {payload[19] == 0xb2 if len(payload) > 19 else 'too short'}")

        # Check for the pattern: 0xaa 0xff repeated 8 times, then 0xaa 0xaa 0xab 0xb2
        if (len(payload) > 34 and 
            payload[0:16] == b'\xaa\xff' * 8 and 
            payload[16:18] == b'\xaa\xaa' and
            payload[18] == 0xab and
            payload[19] == 0xb2):
            
            # Structure: [header] [0xb2] [0x02 0x00] [0xc8 0x00] [timestamp_2bytes] [camera_name...]
            # Camera name starts at byte 27
            # Timestamp is 2 bytes at offset 24-25 (seconds since midnight)
            
            try:
                # Extract camera name (starts at byte 27)
                name_offset = 27
                name_bytes = payload[name_offset:name_offset + 32]  # Read up to 32 bytes
                # Decode and clean: remove null bytes, non-printable chars, and strip
                name = name_bytes.split(b'\x00')[0].decode('utf-8', errors='ignore').strip()
                # Remove any non-printable characters
                name = ''.join(char for char in name if char.isprintable())
                # Remove leading 'i' if present (artifact from encoding)
                if name.startswith('i'):
                    name = name[1:]
                
                # Extract timestamp (2 bytes little-endian at offset 24)
                ts_offset = 24
                seconds_today = struct.unpack_from('<H', payload, ts_offset)[0]
                
                if debug:
                    log(f"  [OK] Parsing: name='{name}', seconds_today={seconds_today}")
                
                # Validate: name should have printable chars
                if name and len(name) > 2:
                    # Convert seconds since midnight to readable time
                    hours = seconds_today // 3600
                    minutes = (seconds_today % 3600) // 60
                    seconds = seconds_today % 60
                    
                    # Use the video file's date + this time
                    # For now, we'll format it as HH:MM:SS
                    timestamp_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
                    
                    if debug:
                        log(f"  [SUCCESS] cam='{name}', time={timestamp_str}")
                    return name, timestamp_str
            except Exception as e:
                if debug:
                    log(f"  Parse error: {e}")
                pass
                    
        pos = s + 1
    
    if debug:
        log(f"  Total SEI NAL units found: {sei_found}")
    return None, None

def process(path, current_num=1, total_num=1, progress_data=None):
    log(f"Processing: {path.name}")
    
    # Update progress data if provided
    if progress_data is not None:
        progress_data['current'] = current_num
        progress_data['current_file'] = path.name
    
    # Determine output directory - always use same directory as source file
    output_dir = path.parent / "with_overlay"
    expected_output = output_dir / (path.stem + "_overlay.mp4")
    
    if expected_output.exists():
        log(f"Skipping {path.name} - overlay already exists at {expected_output.relative_to(path.parent)}")
        if progress_data is not None:
            progress_data['skipped'] += 1
            progress_data['skipped_files'].append(path.name)
        return "skipped"
    
    log(f"Starting SEI extraction with debug logging...")
    log(f"Using ffmpeg: {FFMPEG_PATH}")
    
    import time
    start_time = time.time()
    
    proc = subprocess.Popen(
        [FFMPEG_PATH, "-i", str(path), "-c:v", "copy", "-bsf:v", "h264_mp4toannexb", "-f", "h264", "-"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
    )
    chunk = b""
    cam = ts_start = None
    chunk_count = 0
    while True:
        data = proc.stdout.read(1048576)
        if not data: break
        chunk_count += 1
        chunk += data
        n, t = find_sei(chunk, debug=(chunk_count <= 2))  # Debug first 2 chunks
        if n and not ts_start:  # Get first timestamp
            cam, ts_start = n, t
            log(f"  First metadata found: cam='{n}', time={t}")
        chunk = chunk if len(chunk) < 100000 else chunk[-100000:]  # Keep buffer manageable
    proc.wait()
    proc.stdout.close()
    log(f"Processed {chunk_count} chunk(s) of video data")

    cam = cam or "NO CAMERA NAME"
    ts_start = ts_start or "00:00:00"
    
    # Extract date from filename if available (format: cam1-20251114150213.mp4)
    try:
        # Look for pattern YYYYMMDD in filename
        import re
        match = re.search(r'(\d{8})', path.name)
        if match:
            date_str = match.group(1)
            # Format as MM-DD-YYYY
            date_display = f"{date_str[4:6]}-{date_str[6:8]}-{date_str[0:4]}"
        else:
            date_display = "Unknown Date"
    except:
        date_display = "Unknown Date"
    
    log(f"Camera: {cam}, Date: {date_display}, Start time: {ts_start}")

    # Convert start time to seconds for gmtime offset
    h, m, s = map(int, ts_start.split(':'))
    start_seconds = h * 3600 + m * 60 + s

    # Try multiple font paths for macOS
    font_paths = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNSText.ttf",
        "/Library/Fonts/Arial.ttf"
    ]
    
    font = None
    for fp in font_paths:
        if Path(fp).exists():
            font = fp
            log(f"Using font: {fp}")
            break
    
    # Escape for ffmpeg
    safe_cam = cam.replace("\\", "\\\\").replace("'", "'\\''").replace(":", "\\:")
    safe_date = date_display.replace("\\", "\\\\").replace("'", "'\\''").replace(":", "\\:")
    
    # Create three text overlays: camera name, date, and dynamic time
    # For time, build the format string using expr to concatenate hours, minutes, seconds
    # Calculate offset seconds and use eif/expr to build HH:MM:SS string
    time_expr = (
        f"%{{eif\\:mod(trunc(({start_seconds}+t)/3600)\\,24)\\:d\\:2}}\\:"
        f"%{{eif\\:mod(trunc(({start_seconds}+t)/60)\\,60)\\:d\\:2}}\\:"
        f"%{{eif\\:mod(trunc({start_seconds}+t)\\,60)\\:d\\:2}}"
    )
    
    if not font:
        log("WARNING: No standard font found, using FFmpeg default")
        vf = (f"drawtext=fontsize=48:fontcolor=white:borderw=4:bordercolor=black:x=20:y=main_h-180:text='{safe_cam}',"
              f"drawtext=fontsize=48:fontcolor=white:borderw=4:bordercolor=black:x=20:y=main_h-120:text='{safe_date}',"
              f"drawtext=fontsize=48:fontcolor=white:borderw=4:bordercolor=black:x=20:y=main_h-60:text='{time_expr}'")
    else:
        vf = (f"drawtext=fontfile={font}:fontsize=48:fontcolor=white:borderw=4:bordercolor=black:x=20:y=main_h-180:text='{safe_cam}',"
              f"drawtext=fontfile={font}:fontsize=48:fontcolor=white:borderw=4:bordercolor=black:x=20:y=main_h-120:text='{safe_date}',"
              f"drawtext=fontfile={font}:fontsize=48:fontcolor=white:borderw=4:bordercolor=black:x=20:y=main_h-60:text='{time_expr}'")

    # Create output directory 'with_overlay' in the same folder as the input video
    output_dir = path.parent / "with_overlay"
    try:
        output_dir.mkdir(exist_ok=True)
        log(f"Output directory: {output_dir}")
    except PermissionError:
        error_msg = f"ERROR: Cannot create directory {output_dir} - permission denied"
        log(error_msg)
        subprocess.run([
            "osascript", "-e",
            f'display dialog "Permission Error\\n\\nCannot create output folder:\\n{output_dir}\\n\\nPlease check folder permissions." buttons {{"OK"}} with title "Overlay Burner Error" with icon stop'
        ])
        return
    except Exception as e:
        error_msg = f"ERROR: Failed to create directory {output_dir}: {e}"
        log(error_msg)
        subprocess.run([
            "osascript", "-e",
            f'display dialog "Error Creating Folder\\n\\n{str(e)}\\n\\nCannot create output folder at:\\n{output_dir}" buttons {{"OK"}} with title "Overlay Burner Error" with icon stop'
        ])
        return
    
    out = output_dir / (path.stem + "_overlay.mp4")

    cmd = [FFMPEG_PATH, "-i", str(path), "-vf", vf, "-c:v", "libx264", "-preset", "ultrafast", "-crf", "23", "-c:a", "copy", "-strict", "-2", "-y", str(out)]
    log(f"FFmpeg command: {' '.join(cmd)}")
    log(f"Video filter: {vf}")
    result = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    
    elapsed = time.time() - start_time
    
    if result.returncode == 0:
        log(f"Created: {out.name} in {output_dir.name}/ (took {elapsed:.1f}s)")
        if progress_data is not None:
            progress_data['success'] += 1
        return "success"
    else:
        err = result.stderr.decode(errors='ignore')
        log(f"FFmpeg error (full output):")
        log(err)
        if progress_data is not None:
            progress_data['failed'] += 1
        return "failed"

def main():
    log("=== Overlay Burner Started ===")
    
    # Get the folder where the app/script is located
    if getattr(sys, 'frozen', False):
        # Running as PyInstaller bundle inside Automator.app/Contents/Resources/
        # The actual video folder is passed via environment or we use current working directory
        folder = Path.cwd()
    else:
        # Running as script
        folder = Path(__file__).parent
    
    log(f"Folder: {folder}")

    # Check if specific items (files/folders) were passed as arguments
    videos = []
    
    if len(sys.argv) > 1:
        # Parse selection from argument (comma-separated paths from AppleScript)
        selection_str = sys.argv[1]
        selected_paths = [p.strip() for p in selection_str.split(',') if p.strip()]
        
        # Process each selected item
        for path_str in selected_paths:
            path = Path(path_str)
            if path.is_dir():
                # It's a folder - collect all videos recursively
                folder_videos = [p for p in path.rglob("*.mp4") if "_overlay.mp4" not in p.name.lower()]
                videos.extend(folder_videos)
                log(f"Found {len(folder_videos)} video(s) in folder: {path}")
            elif path.is_file() and path.suffix.lower() == '.mp4' and '_overlay.mp4' not in path.name.lower():
                # It's a video file
                videos.append(path)
                log(f"Added file: {path}")
        
        log(f"Processing {len(videos)} selected video(s)")
    else:
        # No arguments - process all videos in current folder
        videos = [p for p in folder.rglob("*.mp4") if "_overlay.mp4" not in p.name.lower()]
        log(f"Found {len(videos)} video(s) in folder")
    
    if not videos:
        user_pause("No videos", f"No .mp4 files to process")
        return

    log(f"Total videos to process: {len(videos)}")
    
    import time
    total_start = time.time()
    processing_times = []
    
    # Progress tracking data
    progress_data = {
        'total': len(videos),
        'current': 0,
        'current_file': '',
        'success': 0,
        'skipped': 0,
        'failed': 0,
        'est_time': '',
        'skipped_files': []  # Track which files were skipped
    }
    
    # Create a progress log file
    progress_log = Path("/tmp/overlay_burner_progress.txt")
    
    # Open Terminal window with a script that clears screen and shows progress
    # The script displays the progress until it sees __EXIT__, then closes the window
    term_script = subprocess.Popen([
        "osascript", "-e",
        f'tell application "Terminal" to do script "clear && while true; do clear; cat {progress_log} 2>/dev/null || echo \\"Starting...\\"; if grep -q __EXIT__ {progress_log} 2>/dev/null; then exit; fi; sleep 0.5; done"',
        "-e",
        'tell application "Terminal" to activate'
    ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # Get the Terminal window ID so we can close it later
    time.sleep(1)  # Give Terminal time to open
    
    for idx, v in enumerate(videos, 1):
        # Update progress log file
        completed = progress_data['success'] + progress_data['skipped'] + progress_data['failed']
        pct = int(completed / len(videos) * 100) if completed > 0 else 0
        
        with open(progress_log, 'w') as f:
            f.write(f"\n\n\n")
            f.write(f"╔{'═' * 58}╗\n")
            f.write(f"║{' ' * 15}OVERLAY BURNER PROGRESS{' ' * 20}║\n")
            f.write(f"╚{'═' * 58}╝\n\n")
            f.write(f"  Processing file {idx} of {len(videos)}\n\n")
            f.write(f"  Current: {v.name}\n\n")
            
            # Progress bar
            bar_length = 50
            filled = int(bar_length * completed / len(videos)) if completed > 0 else 0
            bar = '█' * filled + '░' * (bar_length - filled)
            f.write(f"  {bar} {pct}%\n\n")
            
            f.write(f"  [  OK  ] Completed: {progress_data['success']}\n")
            f.write(f"  [ SKIP ] Skipped:   {progress_data['skipped']}\n")
            f.write(f"  [ FAIL ] Failed:    {progress_data['failed']}\n\n")
            
            if progress_data['est_time']:
                f.write(f"  [ETA] Estimated time remaining: {progress_data['est_time']}\n\n")
            else:
                f.write(f"\n")
        
        log(f"[{idx}/{len(videos)}] Processing: {v.name}")
        
        file_start = time.time()
        result = process(v, current_num=idx, total_num=len(videos), progress_data=progress_data)
        
        if result == "success":
            file_elapsed = time.time() - file_start
            processing_times.append(file_elapsed)
            
            # Calculate estimated time remaining
            if len(processing_times) > 0:
                avg_time = sum(processing_times) / len(processing_times)
                remaining = len(videos) - idx
                est_seconds = avg_time * remaining
                est_mins = int(est_seconds / 60)
                est_secs = int(est_seconds % 60)
                if remaining > 0:
                    progress_data['est_time'] = f"{est_mins}m {est_secs}s"
                    log(f"Progress: {idx}/{len(videos)} complete. Estimated time remaining: {est_mins}m {est_secs}s")
    
    # Final summary
    total_elapsed = time.time() - total_start
    mins = int(total_elapsed / 60)
    secs = int(total_elapsed % 60)
    
    # Write final progress with exit marker
    with open(progress_log, 'w') as f:
        f.write(f"\n\n\n")
        f.write(f"╔{'═' * 58}╗\n")
        f.write(f"║{' ' * 22}COMPLETE!{' ' * 27}║\n")
        f.write(f"╚{'═' * 58}╝\n\n")
        f.write(f"  [  OK  ] Successfully processed: {progress_data['success']}\n")
        f.write(f"  [ SKIP ] Skipped (already done): {progress_data['skipped']}\n")
        f.write(f"  [ FAIL ] Failed: {progress_data['failed']}\n\n")
        
        # Show which files were skipped
        if progress_data['skipped_files']:
            f.write(f"  Previously processed files:\n")
            for skipped_file in progress_data['skipped_files']:
                f.write(f"    • {skipped_file}\n")
            f.write(f"\n")
        
        f.write(f"  Total time: {mins}m {secs}s\n\n")
        f.write(f"  Output files saved to: with_overlay/\n\n\n")
        f.write(f"__EXIT__")  # Marker to tell the terminal loop to exit (hidden with extra newlines)
    
    # Give Terminal time to exit
    time.sleep(1)
    
    # Force close any remaining Terminal windows showing our progress
    subprocess.run([
        "osascript", "-e",
        'tell application "Terminal" to close (every window whose name contains "' + str(progress_log) + '")'
    ], stderr=subprocess.DEVNULL)
    
    summary = f"[  OK  ] Success: {progress_data['success']}  [ SKIP ] Skipped: {progress_data['skipped']}  [ FAIL ] Failed: {progress_data['failed']}\n\nTotal time: {mins}m {secs}s"
    
    log(summary)
    user_pause("Done", summary)

if __name__ == "__main__":
    main()
