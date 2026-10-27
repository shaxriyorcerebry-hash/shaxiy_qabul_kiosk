; installer/setup.iss - Inno Setup 6.3+ (ADR-037)
; Fayl ASCII bo'lsin (BOM'siz fayl ANSI deb o'qiladi). #define qatorlarida izoh yozmang.
; Yig'ish: scripts/release-windows.ps1 (versiya pubspec.yaml dan).
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#ifndef MyOutputDir
  #define MyOutputDir "..\dist"
#endif
#define MyAppName "ShaxsiyQabul"
#define MyAppTitle "Shaxsiy qabul"
#define MyAppExeName "shaxiy_qabul_kiosk.exe"

[Setup]
; AppId HECH QACHON o'zgarmaydi - o'zgarsa Installed Apps'da ikkinchi yozuv paydo bo'ladi
AppId={{F3026874-2AFB-470A-B1F9-C260E08AE3B8}
AppName={#MyAppTitle}
AppVersion={#MyAppVersion}
AppVerName={#MyAppTitle} {#MyAppVersion}
AppPublisher=Xalq qabulxonasi
VersionInfoVersion={#MyAppVersion}
DefaultDirName=C:\Kiosk\{#MyAppName}
DisableDirPage=yes
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
PrivilegesRequired=lowest
OutputDir={#MyOutputDir}
OutputBaseFilename={#MyAppName}_Setup_v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppTitle}
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=force
; KioskLauncher.exe ro'yxatda yo'q - Restart Manager uni yopmasin (u shell)
CloseApplicationsFilter=*.dll,*.chm,{#MyAppExeName}
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; config.json / secrets.json build'ga kirmaydi va HECH QACHON ustiga yozilmaydi
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "\*.json,\*.log,\*.flag,*.pdb"; Flags: ignoreversion recursesubdirs createallsubdirs
; Shell Launcher qobig'i - ishlab turgan bo'ladi, shuning uchun faqat birinchi o'rnatishda
Source: "..\build\launcher\KioskLauncher.exe"; DestDir: "{app}"; Flags: onlyifdoesntexist
[Icons]
Name: "{autoprograms}\{#MyAppTitle}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppTitle}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppTitle}}"; Flags: nowait postinstall skipifsilent
; Jim yangilanishdan keyin ilovani qayta ochish (launcher ishlatilsa /NORELAUNCH - uni launcher ochadi)
Filename: "{app}\{#MyAppExeName}"; Flags: nowait; Check: WizardSilent and not NoRelaunch

[UninstallDelete]
Type: files; Name: "{app}\updating.flag"
Type: files; Name: "{app}\exit.flag"

[Code]
function NoRelaunch: Boolean;
begin
  Result := Pos('/NORELAUNCH', Uppercase(GetCmdTail)) > 0;
end;
