; Melon Mod Manager installer/uninstaller (Inno Setup template)
; Build app first, then point Source to your release output folder.

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0-beta.4"
#endif

#ifndef MyOutputBaseFilename
  #define MyOutputBaseFilename "MelonModManager-Win64-Setup-" + MyAppVersion
#endif

#ifndef MyVersionInfoVersion
  #define MyVersionInfoVersion "1.0.0.0"
#endif

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
; Keep upgrades clean across beta jumps:
; remove old app payload files/folders before copying the new build.
Type: filesandordirs; Name: "{app}\*"

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
  Result :=
    MsgBox(
      'Do you really want to uninstall Melon Mod Manager?',
      mbConfirmation,
      MB_YESNO
    ) = IDYES;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usDone then
  begin
    MsgBox(
      'Thanks for using Melon Mod Manager. ' +
      'If you want to install it again, you are always welcome.',
      mbInformation,
      MB_OK
    );
  end;
end;
