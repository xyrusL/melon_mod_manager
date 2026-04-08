; Melon Mod Manager installer/uninstaller (Inno Setup template)
; Build app first, then point Source to your release output folder.

#ifndef MyAppVersion
  #define MyAppVersion "1.7.0-2026.03.30"
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
; Keep upgrades clean across app upgrades:
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

procedure ShowUninstallThankYouDialog();
var
  ThankYouForm: TSetupForm;
  AccentBand: TPanel;
  CardPanel: TPanel;
  TitleLabel: TNewStaticText;
  MessageLabel: TNewStaticText;
  FooterLabel: TNewStaticText;
  CloseButton: TNewButton;
begin
  ThankYouForm := CreateCustomForm;
  try
    ThankYouForm.Caption := 'Thanks for using Melon Mod Manager';
    ThankYouForm.ClientWidth := ScaleX(500);
    ThankYouForm.ClientHeight := ScaleY(250);
    ThankYouForm.Color := $0011161D;
    ThankYouForm.BorderStyle := bsDialog;
    ThankYouForm.Position := poScreenCenter;

    AccentBand := TPanel.Create(ThankYouForm);
    AccentBand.Parent := ThankYouForm;
    AccentBand.Left := 0;
    AccentBand.Top := 0;
    AccentBand.Width := ThankYouForm.ClientWidth;
    AccentBand.Height := ScaleY(10);
    AccentBand.BevelOuter := bvNone;
    AccentBand.Color := $0057F1B4;

    CardPanel := TPanel.Create(ThankYouForm);
    CardPanel.Parent := ThankYouForm;
    CardPanel.Left := ScaleX(24);
    CardPanel.Top := ScaleY(28);
    CardPanel.Width := ThankYouForm.ClientWidth - ScaleX(48);
    CardPanel.Height := ScaleY(150);
    CardPanel.BevelOuter := bvNone;
    CardPanel.Color := $001A232E;

    TitleLabel := TNewStaticText.Create(ThankYouForm);
    TitleLabel.Parent := CardPanel;
    TitleLabel.Left := ScaleX(20);
    TitleLabel.Top := ScaleY(18);
    TitleLabel.Width := CardPanel.Width - ScaleX(40);
    TitleLabel.Height := ScaleY(28);
    TitleLabel.AutoSize := False;
    TitleLabel.Transparent := True;
    TitleLabel.Font.Name := 'Segoe UI';
    TitleLabel.Font.Size := 14;
    TitleLabel.Font.Style := [fsBold];
    TitleLabel.Font.Color := clWhite;
    TitleLabel.Caption := 'Thanks for trying Melon Mod Manager';

    MessageLabel := TNewStaticText.Create(ThankYouForm);
    MessageLabel.Parent := CardPanel;
    MessageLabel.Left := ScaleX(20);
    MessageLabel.Top := ScaleY(56);
    MessageLabel.Width := CardPanel.Width - ScaleX(40);
    MessageLabel.Height := ScaleY(58);
    MessageLabel.AutoSize := False;
    MessageLabel.Transparent := True;
    MessageLabel.WordWrap := True;
    MessageLabel.Font.Name := 'Segoe UI';
    MessageLabel.Font.Size := 10;
    MessageLabel.Font.Color := clWhite;
    MessageLabel.Caption :=
      'Your copy of Melon has been removed.'#13#10 +
      'Thanks for using the app, and you are always welcome back any time.';

    FooterLabel := TNewStaticText.Create(ThankYouForm);
    FooterLabel.Parent := CardPanel;
    FooterLabel.Left := ScaleX(20);
    FooterLabel.Top := ScaleY(122);
    FooterLabel.Width := CardPanel.Width - ScaleX(40);
    FooterLabel.Height := ScaleY(22);
    FooterLabel.AutoSize := False;
    FooterLabel.Transparent := True;
    FooterLabel.Font.Name := 'Segoe UI';
    FooterLabel.Font.Size := 9;
    FooterLabel.Font.Color := $00A7C2D9;
    FooterLabel.Caption := 'Thank you for being part of the Minecraft community.';

    CloseButton := TNewButton.Create(ThankYouForm);
    CloseButton.Parent := ThankYouForm;
    CloseButton.Caption := 'Close';
    CloseButton.Width := ScaleX(112);
    CloseButton.Height := ScaleY(34);
    CloseButton.Left := ThankYouForm.ClientWidth - CloseButton.Width - ScaleX(24);
    CloseButton.Top := ThankYouForm.ClientHeight - CloseButton.Height - ScaleY(22);
    CloseButton.ModalResult := mrOk;
    CloseButton.Default := True;

    ThankYouForm.ActiveControl := CloseButton;
    ThankYouForm.ShowModal;
  finally
    ThankYouForm.Free;
  end;
end;

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
    ShowUninstallThankYouDialog();
  end;
end;
