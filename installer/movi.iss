#define MyAppName "Movi"
#define MyAppPublisher "MVDH"
#define MyAppExeName "movi.exe"

#ifndef ReleaseDir
  #define ReleaseDir "../build/windows/x64/runner/Release"
#endif

#ifndef MyAppPublisherURL
  #define MyAppPublisherURL "https://movi.app"
#endif

#ifndef MyAppSupportURL
  #define MyAppSupportURL "https://movi.app/support"
#endif

#ifndef MyAppUpdatesURL
  #define MyAppUpdatesURL "https://movi.app/updates"
#endif

#ifndef MyAppVersion
  #error "MyAppVersion must be provided at build time (ISCC /DMyAppVersion=...)."
#endif

[Setup]
; Garde le même AppId pour toutes les futures mises à jour
AppId={{E7D0F0A4-7B7A-4D4E-9F53-2A4F6F7B1D11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppPublisherURL}
AppSupportURL={#MyAppSupportURL}
AppUpdatesURL={#MyAppUpdatesURL}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\build\inno
OutputBaseFilename=Movi-Setup-{#MyAppVersion}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "french"; MessagesFile: "compiler:Languages\French.isl"

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le Bureau"; GroupDescription: "Raccourcis :"

[Files]
Source: "{#ReleaseDir}/*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Critical files duplicated as dontcopy so InitializeSetup can verify setup integrity before install.
Source: "{#ReleaseDir}/{#MyAppExeName}"; Flags: dontcopy
Source: "{#ReleaseDir}/vcruntime140.dll"; Flags: dontcopy
Source: "{#ReleaseDir}/vcruntime140_1.dll"; Flags: dontcopy
Source: "{#ReleaseDir}/msvcp140.dll"; Flags: dontcopy

[Registry]
; URI protocol handlers for password-recovery deep links.
Root: HKCU; Subkey: "Software\Classes\movi"; ValueType: string; ValueData: "URL:Movi Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\movi"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\movi\DefaultIcon"; ValueType: string; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\movi\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

Root: HKCU; Subkey: "Software\Classes\movi-dev"; ValueType: string; ValueData: "URL:Movi Dev Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\movi-dev"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\movi-dev\DefaultIcon"; ValueType: string; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\movi-dev\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

Root: HKCU; Subkey: "Software\Classes\movi-staging"; ValueType: string; ValueData: "URL:Movi Staging Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\movi-staging"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\movi-staging\DefaultIcon"; ValueType: string; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\movi-staging\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Lancer {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
function EnsureBundledFile(const FileName: string; const UserLabel: string): Boolean;
begin
  Result := True;
  try
    ExtractTemporaryFile(FileName);
  except
    SuppressibleMsgBox(
      'Installation interrompue: composant manquant dans le setup (' + UserLabel + ').' + #13#10 +
      'Action: retelechargez l''installeur puis recommencez.',
      mbCriticalError,
      MB_OK,
      IDOK
    );
    Result := False;
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result :=
    EnsureBundledFile('{#MyAppExeName}', 'movi.exe') and
    EnsureBundledFile('vcruntime140.dll', 'vcruntime140.dll') and
    EnsureBundledFile('vcruntime140_1.dll', 'vcruntime140_1.dll') and
    EnsureBundledFile('msvcp140.dll', 'msvcp140.dll');
end;
