#ifndef AppVersion
  #define AppVersion "1.0.1"
#endif
#ifndef ProductName
  #define ProductName "Lotus ERP"
#endif
#ifndef ProductId
  #define ProductId "LotusERP.Desktop"
#endif
#ifndef ReleaseDir
  #define ReleaseDir "..\build\windows\x64\runner\Release"
#endif
#ifndef InstallerOutputDir
  #define InstallerOutputDir "..\dist"
#endif

[Setup]
AppId={#ProductId}
AppName={#ProductName}
AppVersion={#AppVersion}
AppVerName={#ProductName} {#AppVersion}
AppPublisher=Lotus ERP
DefaultDirName={localappdata}\Programs\{#ProductName}
DefaultGroupName={#ProductName}
UsePreviousAppDir=yes
DisableDirPage=auto
DisableWelcomePage=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
OutputDir={#InstallerOutputDir}
OutputBaseFilename=Lotus-ERP-Setup-{#AppVersion}-x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
UninstallDisplayIcon={app}\lotus_erp.exe
SetupIconFile=..\windows\runner\resources\app_icon.ico

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked

[Files]
Source: "{#ReleaseDir}\lotus_erp.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#ProductName}"; Filename: "{app}\lotus_erp.exe"
Name: "{autodesktop}\{#ProductName}"; Filename: "{app}\lotus_erp.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\lotus_erp.exe"; Description: "Launch Lotus ERP"; Flags: nowait postinstall skipifsilent

[Code]
#include "scripts\update_safety.iss"
