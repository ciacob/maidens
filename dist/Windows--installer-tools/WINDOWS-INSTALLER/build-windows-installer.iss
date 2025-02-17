; Generates Windows installer for MAIDENS application
#define MyAppName "MAIDENS"
#define MyAppVersion "1.5.7"
#define MyAppPublisher "Claudius Tiberiu Iacob"
#define MyAppURL "https://github.com/ciacob/maidens"
#define MyAppExeName "MAIDENS.exe"
#define MyAppSupportUrl "https://github.com/ciacob/maidens/issues"
#define MyAppReleasesUrl "https://github.com/ciacob/maidens/releases"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{EA93D423-66FE-4B50-9D0F-618A338C14F0}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppCopyright={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppSupportUrl}
AppUpdatesURL={#MyAppReleasesUrl}
ChangesAssociations=yes
Compression=lzma
UsePreviousAppDir=no
DefaultDirName={sd}\MAIDENS
DisableProgramGroupPage=yes
LicenseFile={#SourcePath}\..\Legal\License.rtf
OutputDir={#SourcePath}\..\..\..\dist-out
OutputBaseFilename=install-maidens-{#MyAppVersion}
SetupIconFile={#SourcePath}\..\..\..\dist-interim\assets\images\maidens-application-icon.ico
SolidCompression=yes
UsePreviousSetupType=no


[Registry]
; Associate *.maid files
Root: HKLM; Subkey: "Software\Classes\.maid"; ValueType: string; ValueName: ""; ValueData: "maidens_project_file"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "Software\Classes\maidens_project_file"; ValueType: string; ValueName: ""; ValueData: "MAIDENS Project File"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Classes\maidens_project_file\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\assets\images\maidens-project-file-icon.ico,0"
Root: HKLM; Subkey: "Software\Classes\maidens_project_file\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""
Root: HKCR; Subkey: ".maid"; ValueType: string; ValueName: ""; ValueData: "maidens_project_file"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "maidens_project_file"; ValueType: string; ValueName: ""; ValueData: "MAIDENS Project File"; Flags: uninsdeletekey
Root: HKCR; Subkey: "maidens_project_file\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\assets\images\maidens-project-file-icon.ico,0"
Root: HKCR; Subkey: "maidens_project_file\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#SourcePath}\..\..\..\dist-interim\MAIDENS.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\..\..\..\dist-interim\MAIDENS.swf"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\..\..\..\dist-interim\mimetype"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\..\..\..\dist-interim\Adobe AIR\*"; DestDir: "{app}\Adobe AIR\"; Flags: ignoreversion recursesubdirs
Source: "{#SourcePath}\..\..\..\dist-interim\assets\*"; DestDir: "{app}\assets\"; Flags: ignoreversion recursesubdirs
Source: "{#SourcePath}\..\..\..\dist-interim\winnative\*"; DestDir: "{app}\winnative\"; Flags: ignoreversion recursesubdirs
Source: "{#SourcePath}\..\..\..\dist-interim\META-INF\*"; DestDir: "{app}\META-INF\"; Flags: ignoreversion recursesubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

