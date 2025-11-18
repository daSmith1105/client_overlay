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
    pause
    exit /b 1
)

echo [OK] ffmpeg.exe found - will be bundled into executable
echo.

REM Build the executable
echo [NOTE] Building OverlayBurner.exe with bundled ffmpeg...
echo.

REM Change to common directory where overlay_burner.py is located
cd ..\common

REM Build with PyInstaller - include ffmpeg.exe as a binary
pyinstaller --clean --onefile --name %APP_NAME% --add-binary "..\windows\ffmpeg.exe;." overlay_burner.py
if !ERRORLEVEL! neq 0 (
    echo [ERROR] PyInstaller build failed
    cd ..\windows
    pause
    exit /b 1
)
echo.
echo [OK] Build completed (ffmpeg.exe bundled inside)
echo.

REM Go back to windows directory
cd ..\windows

REM Copy executable to windows directory
echo [NOTE] Copying self-contained executable...
if exist "..\common\dist\%APP_NAME%.exe" (
    copy /Y "..\common\dist\%APP_NAME%.exe" "%APP_NAME%.exe" >nul
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to copy executable
        pause
        exit /b 1
    )
    echo [OK] Copied %APP_NAME%.exe (with bundled ffmpeg) to windows directory
) else (
    echo [ERROR] Built executable not found
    pause
    exit /b 1
)
echo.

REM Display file info
echo [SUCCESS] Build complete!
echo.
echo Self-contained executable created:
dir /b "%APP_NAME%.exe" 2>nul
dir /b "%APP_NAME%.bat" 2>nul
echo.
echo NOTE: ffmpeg.exe is bundled INSIDE %APP_NAME%.exe
echo       You can distribute just %APP_NAME%.bat + %APP_NAME%.exe
echo.

REM Clean up build artifacts
echo [NOTE] Cleaning up build artifacts...
if exist "..\common\build" rmdir /s /q "..\common\build"
if exist "..\common\dist" rmdir /s /q "..\common\dist"
if exist "..\common\%APP_NAME%.spec" del /q "..\common\%APP_NAME%.spec"
echo [OK] Cleanup complete
echo.

echo ╔═══════════════════════════════════════════════════════════╗
echo ║                   BUILD SUCCESSFUL!                       ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo The executable is now self-contained with ffmpeg bundled inside!
echo.
echo To run: Double-click %APP_NAME%.bat
echo.
echo To distribute: Share %APP_NAME%.bat + %APP_NAME%.exe
echo                (no need to include ffmpeg.exe separately)
echo.

pause
