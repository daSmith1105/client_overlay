@echo off
REM OverlayBurner - Windows Build Script
REM This script sets up the Python environment and builds the executable

setlocal enabledelayedexpansion

echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║          OVERLAY BURNER - WINDOWS BUILD SCRIPT            ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.

REM Get script directory (project root)
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

set "APP_NAME=DividiaOverlayBurner"

REM Check if Python is installed
python --version >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Python is not installed or not in PATH
    echo.
    echo Please install Python 3.8+ from https://www.python.org/
    echo.
    pause
    exit /b 1
)

echo [OK] Python found:
python --version
echo.

REM Create virtual environment if it doesn't exist
if not exist "overlay_env\" (
    echo [NOTE] Creating virtual environment...
    python -m venv overlay_env
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo [OK] Virtual environment created
    echo.
) else (
    echo [OK] Virtual environment already exists
    echo.
)

REM Activate virtual environment
echo [NOTE] Activating virtual environment...
call overlay_env\Scripts\activate.bat
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Failed to activate virtual environment
    pause
    exit /b 1
)
echo [OK] Virtual environment activated
echo.

REM Install/upgrade PyInstaller
echo [NOTE] Installing PyInstaller...
python -m pip install --upgrade pyinstaller
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Failed to install PyInstaller
    pause
    exit /b 1
)
echo [OK] PyInstaller installed
echo.

REM Check if ffmpeg.exe exists before building
if not exist "ffmpeg.exe" (
    echo [ERROR] ffmpeg.exe not found in windows directory
    echo.
    echo You need to download FFmpeg for Windows BEFORE building:
    echo 1. Visit: https://www.gyan.dev/ffmpeg/builds/
    echo 2. Download: ffmpeg-release-essentials.zip
    echo 3. Extract ffmpeg.exe from bin folder
    echo 4. Place it in: %SCRIPT_DIR%
    echo 5. Run this script again
    echo.
    exit /b 1
)

echo [OK] ffmpeg.exe found - will be bundled into executable
echo.

REM Build the executable
echo [NOTE] Building OverlayBurner.exe with bundled ffmpeg...
echo.

REM Change to common directory where overlay_burner.py is located
cd ..\common

REM Clean build directories manually first to avoid permission issues
if exist "build" rmdir /s /q "build" 2>nul
if exist "dist" rmdir /s /q "dist" 2>nul
if exist "*.spec" del /q "*.spec" 2>nul

REM Build with PyInstaller - include ffmpeg.exe as a binary, no console window
pyinstaller --onefile --noconsole --name DividiaOverlayBurner --add-binary "..\windows\ffmpeg.exe;." overlay_burner.py
if !ERRORLEVEL! neq 0 (
    echo [ERROR] PyInstaller build failed
    cd ..\windows
    exit /b 1
)
echo.
echo [OK] Build completed (ffmpeg.exe bundled inside)
echo.

REM Go back to windows directory
cd ..\windows

REM Copy executable to windows directory (optional - batch file uses common\dist version)
echo [NOTE] Copying self-contained executable...
if exist "..\common\dist\DividiaOverlayBurner.exe" (
    copy /Y "..\common\dist\DividiaOverlayBurner.exe" "DividiaOverlayBurner.exe" >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo [OK] Copied DividiaOverlayBurner.exe with bundled ffmpeg
    ) else (
        echo [WARNING] Could not copy file in use - this is OK, batch uses common\dist version
    )
    echo.
) else (
    echo [ERROR] Built executable not found at ..\common\dist\DividiaOverlayBurner.exe
    exit /b 1
)

REM Display file info
echo [SUCCESS] Build complete!
echo.
echo Self-contained executable created:
dir /b "DividiaOverlayBurner.exe" 2>nul
dir /b "DividiaOverlayBurner.bat" 2>nul
echo.
echo NOTE: ffmpeg.exe is bundled INSIDE DividiaOverlayBurner.exe
echo       You can distribute just the .bat and .exe files
echo.

REM Clean up build artifacts (keep dist folder with exe!)
echo [NOTE] Cleaning up build artifacts...
if exist "..\common\build" rmdir /s /q "..\common\build"
if exist "..\common\DividiaOverlayBurner.spec" del /q "..\common\DividiaOverlayBurner.spec"
echo [OK] Cleanup complete
echo.

echo ╔═══════════════════════════════════════════════════════════╗
echo ║                   BUILD SUCCESSFUL!                       ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo The executable is now self-contained with ffmpeg bundled inside!
echo.
echo To run: Double-click DividiaOverlayBurner.bat
echo.
echo To distribute: Share DividiaOverlayBurner.bat and DividiaOverlayBurner.exe
echo                (no need to include ffmpeg.exe separately)
echo.
