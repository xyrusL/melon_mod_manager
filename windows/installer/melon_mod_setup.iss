; Melon Mod Manager installer/uninstaller (Inno Setup template)
; Build app first, then point Source to your release output folder.

#ifndef MyAppVersion
  #define MyAppVersion "1.7.10"
#endif

#ifndef MyOutputBaseFilename
  #define MyOutputBaseFilename "MelonModManager-Win64-Setup-" + MyAppVersion
#endif

#ifndef MyVersionInfoVersion
  #define MyVersionInfoVersion "1.0.0.0"
#endif

#ifndef MySiteUrl
  #define MySiteUrl "http://localhost:3000"
#endif

#define MyRoamingDataDir "{userappdata}\Melon Mod Manager\Melon Mod Manager"
#define MyLocalDataDir "{localappdata}\Melon Mod Manager\Melon Mod Manager"
#define MyHiveBoxBase "{userdocs}\modrinth_mappings"
#define MyThankYouUrl MySiteUrl + "/thank-you-message"

[Setup]
AppId={{6A8C18A3-8D5A-4E8D-9D2D-2B4E8D8F0B11}
AppName=Melon Mod Manager
AppVersion={#MyAppVersion}
AppPublisher=Melon Mod Manager
DefaultDirName={autopf}\Melon Mod Manager
DefaultGroupName=Melon Mod Manager
OutputDir=.
OutputBaseFilename={#MyOutputBaseFilename}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayName=Melon Mod Manager
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\melon_mod_manager.exe
ArchitecturesInstallIn64BitMode=x64compatible
VersionInfoVersion={#MyVersionInfoVersion}
VersionInfoCompany=Melon Mod Manager
VersionInfoDescription=Melon Mod Manager Setup
VersionInfoTextVersion={#MyAppVersion}
VersionInfoProductName=Melon Mod Manager
VersionInfoProductVersion={#MyVersionInfoVersion}
VersionInfoCopyright=Copyright (C) 2026 Melon Mod Manager. Licensed under MIT.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"

[InstallDelete]
; Keep upgrades clean across app upgrades:
; remove old app payload files/folders before copying the new build.
Type: filesandordirs; Name: "{app}\*"

[UninstallDelete]
; Remove app-owned Flutter settings and support data only.
; Do not delete the user's Minecraft mods/resource packs/shader packs.
Type: filesandordirs; Name: "{#MyRoamingDataDir}"
Type: dirifempty; Name: "{userappdata}\Melon Mod Manager"
Type: filesandordirs; Name: "{#MyLocalDataDir}"
Type: dirifempty; Name: "{localappdata}\Melon Mod Manager"
Type: files; Name: "{#MyHiveBoxBase}.hive"
Type: files; Name: "{#MyHiveBoxBase}.hivec"
Type: files; Name: "{#MyHiveBoxBase}.lock"

[Files]
; Update these paths to your real Windows release output.
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Melon Mod Manager"; Filename: "{app}\melon_mod_manager.exe"
Name: "{autodesktop}\Melon Mod Manager"; Filename: "{app}\melon_mod_manager.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\melon_mod_manager.exe"; Description: "Launch Melon Mod Manager"; Flags: nowait postinstall skipifsilent

[Messages]
WelcomeLabel1=Welcome to Melon Mod Manager Setup
WelcomeLabel2=This setup will install Melon Mod Manager on your computer.
FinishedLabel=Melon Mod Manager was installed successfully.
FinishedHeadingLabel=Setup Complete

[Code]
var
  InstallStageLabel: TNewStaticText;
  InstallPercentLabel: TNewStaticText;
  ThankYouPageOpened: Boolean;

procedure InitializeWizard();
begin
  WizardForm.WelcomeLabel2.Caption :=
    'This setup will install Melon Mod Manager.'#13#10 +
    'Click Next to continue.';

  InstallStageLabel := TNewStaticText.Create(WizardForm);
  InstallStageLabel.Parent := WizardForm.InstallingPage;
  InstallStageLabel.Left := WizardForm.ProgressGauge.Left;
  InstallStageLabel.Top := WizardForm.ProgressGauge.Top - ScaleY(28);
  InstallStageLabel.Width := WizardForm.ProgressGauge.Width - ScaleX(70);
  InstallStageLabel.Caption := 'Preparing installation...';

  InstallPercentLabel := TNewStaticText.Create(WizardForm);
  InstallPercentLabel.Parent := WizardForm.InstallingPage;
  InstallPercentLabel.Width := ScaleX(60);
  InstallPercentLabel.Height := ScaleY(18);
  InstallPercentLabel.Left :=
    WizardForm.ProgressGauge.Left + WizardForm.ProgressGauge.Width - InstallPercentLabel.Width;
  InstallPercentLabel.Top := InstallStageLabel.Top;
  InstallPercentLabel.Caption := '0%';
end;

procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
var
  Percent: Integer;
begin
  if MaxProgress > 0 then
    Percent := MulDiv(CurProgress, 100, MaxProgress)
  else
    Percent := 0;

  InstallPercentLabel.Caption := IntToStr(Percent) + '%';
  InstallStageLabel.Caption := WizardForm.StatusLabel.Caption;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    InstallStageLabel.Caption := 'Installing Melon Mod Manager...';

  if CurStep = ssPostInstall then
    InstallStageLabel.Caption := 'Finalizing installation...';
end;

function InitializeUninstall(): Boolean;
begin
  ThankYouPageOpened := False;
  Result :=
    MsgBox(
      'Do you really want to uninstall Melon Mod Manager?',
      mbConfirmation,
      MB_YESNO
    ) = IDYES;
end;

procedure CleanupAppTempData();
var
  TempRoot: String;
  AppTempDir: String;
begin
  TempRoot := GetEnv('TEMP');
  if TempRoot = '' then
    exit;

  AppTempDir := AddBackslash(TempRoot) + 'melon_mod';
  if DirExists(AppTempDir) then
    if not DelTree(AppTempDir, True, True, True) then
      Log(Format('Could not remove app temp directory "%s".', [AppTempDir]));
end;

procedure OpenThankYouPageAfterUninstall();
var
  ErrorCode: Integer;
begin
  if ThankYouPageOpened or UninstallSilent then
    exit;

  if not ShellExec(
    '',
    '{#MyThankYouUrl}',
    '',
    '',
    SW_SHOWNORMAL,
    ewNoWait,
    ErrorCode
  ) then
  begin
    Log('Could not open uninstall thank-you page. Error code: ' +
      IntToStr(ErrorCode));
    Log('Thank-you URL: {#MyThankYouUrl}');
  end
  else
    ThankYouPageOpened := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    CleanupAppTempData();

  if CurUninstallStep = usDone then
    OpenThankYouPageAfterUninstall();
end;
