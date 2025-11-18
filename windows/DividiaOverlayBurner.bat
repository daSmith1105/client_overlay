@echo off
REM DividiaOverlayBurner - Windows Launcher
REM This script provides file/folder selection dialogs and launches the overlay burner

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "EXEC_PATH=%SCRIPT_DIR%DividiaOverlayBurner.exe"

REM Create temp files for PowerShell output
set "TEMP_SELECTION=%TEMP%\overlay_selection.txt"
set "TEMP_DEBUG=%TEMP%\overlay_debug.txt"

REM Debug logging
echo === Overlay Burner Debug === > "%TEMP_DEBUG%"
echo Script: %~f0 >> "%TEMP_DEBUG%"
echo Executable: %EXEC_PATH% >> "%TEMP_DEBUG%"

REM PowerShell script for selection dialog
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"Add-Type -AssemblyName System.Windows.Forms; " ^
"$form = New-Object System.Windows.Forms.Form; " ^
"$form.Text = 'Dividia Overlay Burner'; " ^
"$form.Size = New-Object System.Drawing.Size(400, 200); " ^
"$form.StartPosition = 'CenterScreen'; " ^
"$form.FormBorderStyle = 'FixedDialog'; " ^
"$form.MaximizeBox = $false; " ^
"$form.TopMost = $true; " ^
"$label = New-Object System.Windows.Forms.Label; " ^
"$label.Text = 'How would you like to select items to process?'; " ^
"$label.Location = New-Object System.Drawing.Point(30, 30); " ^
"$label.Size = New-Object System.Drawing.Size(340, 30); " ^
"$form.Controls.Add($label); " ^
"$btnFiles = New-Object System.Windows.Forms.Button; " ^
"$btnFiles.Text = 'Browse Files'; " ^
"$btnFiles.Location = New-Object System.Drawing.Point(50, 70); " ^
"$btnFiles.Size = New-Object System.Drawing.Size(120, 40); " ^
"$btnFiles.Add_Click({ $form.Tag = 'FILES'; $form.Close() }); " ^
"$form.Controls.Add($btnFiles); " ^
"$btnFolders = New-Object System.Windows.Forms.Button; " ^
"$btnFolders.Text = 'Browse Folders'; " ^
"$btnFolders.Location = New-Object System.Drawing.Point(220, 70); " ^
"$btnFolders.Size = New-Object System.Drawing.Size(120, 40); " ^
"$btnFolders.Add_Click({ $form.Tag = 'FOLDERS'; $form.Close() }); " ^
"$form.Controls.Add($btnFolders); " ^
"$form.ShowDialog() | Out-Null; " ^
"exit ($form.Tag -eq 'FILES' ? 1 : ($form.Tag -eq 'FOLDERS' ? 2 : 0))"

set METHOD_CODE=%ERRORLEVEL%

if %METHOD_CODE%==0 (
    echo User cancelled selection >> "%TEMP_DEBUG%"
    exit /b 0
)

REM Now show file/folder browser based on selection
if %METHOD_CODE%==1 (
    echo Method: Browse Files >> "%TEMP_DEBUG%"
    
    REM Browse for files
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName System.Windows.Forms; " ^
    "$dialog = New-Object System.Windows.Forms.OpenFileDialog; " ^
    "$dialog.Title = 'Select video file(s) to process'; " ^
    "$dialog.Filter = 'MP4 Files (*.mp4)|*.mp4'; " ^
    "$dialog.Multiselect = $true; " ^
    "if ($dialog.ShowDialog() -eq 'OK') { " ^
    "    $dialog.FileNames -join '|' | Out-File -Encoding UTF8 '%TEMP_SELECTION%'; " ^
    "    exit 0; " ^
    "} else { exit 1 }"
    
    if !ERRORLEVEL! neq 0 (
        echo No files selected >> "%TEMP_DEBUG%"
        exit /b 0
    )
) else (
    echo Method: Browse Folders >> "%TEMP_DEBUG%"
    
    REM Browse for folder
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Add-Type -AssemblyName System.Windows.Forms; " ^
    "$dialog = New-Object System.Windows.Forms.FolderBrowserDialog; " ^
    "$dialog.Description = 'Select folder(s) to process:'; " ^
    "$dialog.ShowNewFolderButton = $false; " ^
    "if ($dialog.ShowDialog() -eq 'OK') { " ^
    "    $dialog.SelectedPath | Out-File -Encoding UTF8 '%TEMP_SELECTION%'; " ^
    "    exit 0; " ^
    "} else { exit 1 }"
    
    if !ERRORLEVEL! neq 0 (
        echo No folder selected >> "%TEMP_DEBUG%"
        exit /b 0
    )
)

REM Read the selection
set /p SELECTION=<"%TEMP_SELECTION%"
echo Selection: !SELECTION! >> "%TEMP_DEBUG%"

REM Validate that selection exists
if "!SELECTION!"=="" (
    powershell -Command "[System.Windows.Forms.MessageBox]::Show('No files or folders selected. Exiting.', 'Dividia Overlay Burner', 0, 64)" >nul
    exit /b 0
)

REM Parse selection and validate same directory
REM For files: check all are from same directory
REM For folders: can be multiple but we'll process each

REM Check if executable exists
if not exist "%EXEC_PATH%" (
    echo ERROR: Executable not found >> "%TEMP_DEBUG%"
    powershell -Command "[System.Windows.Forms.MessageBox]::Show('ERROR: DividiaOverlayBurner.exe not found at:`n%EXEC_PATH%`n`nPlease rebuild the application.', 'Dividia Overlay Burner Error', 0, 16)" >nul
    exit /b 1
)

REM Get the working directory (first item's directory)
for /f "delims=| tokens=1" %%a in ("!SELECTION!") do (
    set "FIRST_ITEM=%%a"
)

REM Check if first item is a file or folder
if exist "!FIRST_ITEM!\*" (
    REM It's a folder
    set "VIDEO_DIR=!FIRST_ITEM!"
) else (
    REM It's a file - get parent directory
    for %%F in ("!FIRST_ITEM!") do set "VIDEO_DIR=%%~dpF"
)

echo Video directory: !VIDEO_DIR! >> "%TEMP_DEBUG%"
echo Running overlay burner... >> "%TEMP_DEBUG%"

REM Change to video directory and run
cd /d "!VIDEO_DIR!" 2>>"%TEMP_DEBUG%"

REM Run the executable with the selection as argument
"%EXEC_PATH%" "!SELECTION!" >>"%TEMP_DEBUG%" 2>&1

REM Show completion notification
powershell -Command "[System.Windows.Forms.MessageBox]::Show('All videos processed!`n`nCheck for _overlay.mp4 files in the with_overlay folder.', 'Dividia Overlay Burner Complete', 0, 64)" >nul

endlocal
exit /b 0
