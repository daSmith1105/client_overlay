; OverlayBurner Inno Setup Installer Script
; This script creates a professional Windows installer for OverlayBurner
; 
; INSTRUCTIONS:
; 1. Download and install Inno Setup from: https://jrsoftware.org/isinfo.php
; 2. Build OverlayBurner.exe using rebuild.bat (ensures ffmpeg is bundled)
; 3. Right-click this file and select "Compile" (or open in Inno Setup and press F9)
; 4. The installer will be created in: windows\Output\OverlayBurner_Setup.exe
; 5. Distribute that single .exe file to users!

#define MyAppName "DividiaOverlayBurner"
#define MyAppVersion "1.0"
#define MyAppPublisher "Dividia"
#define MyAppURL "https://yourwebsite.com"
#define MyAppExeName "DividiaOverlayBurner.bat"

[Setup]
; Basic app information
AppId={{8F2C9A45-1B3D-4E6F-9C7A-2D8E5F1A9B4C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Installation directories
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes

; Output settings
OutputDir=Output
OutputBaseFilename=DividiaOverlayBurner_Setup
Compression=lzma2/ultra64
SolidCompression=yes

; Windows version requirements
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Installer UI settings
WizardStyle=modern
SetupIconFile=..\overlayburner.png
UninstallDisplayIcon={app}\{#MyAppExeName}

; License and info files (optional - uncomment if you have these)
;LicenseFile=LICENSE.txt
;InfoBeforeFile=README.txt

; Privileges
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main application files
Source: "DividiaOverlayBurner.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "DividiaOverlayBurner.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme

; NOTE: Don't include ffmpeg.exe separately - it's bundled inside OverlayBurner.exe

[Icons]
; Start Menu shortcut
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Comment: "Process security camera videos with metadata overlay"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{group}\README"; Filename: "{app}\README.md"

; Desktop shortcut (if user selected it)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; Comment: "Process security camera videos"

[Run]
; Option to launch app after installation
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Custom code to check for requirements or display messages

procedure InitializeWizard();
begin
  // Custom initialization if needed
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  
  // You could add checks here, for example:
  // - Check Windows version
  // - Display welcome message
  // - Check disk space
end;

[Messages]
; Custom messages
WelcomeLabel2=This will install [name/ver] on your computer.%n%nOverlayBurner automatically overlays camera metadata (camera name, date, and timestamp) onto security camera videos.%n%nNo additional software (Python, FFmpeg) is required.
FinishedHeadingLabel=Installation Complete
FinishedLabelNoIcons=OverlayBurner has been installed successfully.%n%nYou can now process security camera videos with embedded metadata overlays.

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
