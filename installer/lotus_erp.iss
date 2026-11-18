#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId=LotusERP.Desktop
AppName=Lotus ERP
AppVersion={#AppVersion}
AppVerName=Lotus ERP {#AppVersion}
AppPublisher=Lotus ERP
DefaultDirName={localappdata}\Programs\Lotus ERP
DefaultGroupName=Lotus ERP
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
OutputDir=..\dist
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
Name: "{group}\Lotus ERP"; Filename: "{app}\lotus_erp.exe"
Name: "{autodesktop}\Lotus ERP"; Filename: "{app}\lotus_erp.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\lotus_erp.exe"; Description: "Launch Lotus ERP"; Flags: nowait postinstall skipifsilent
