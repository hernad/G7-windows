#define MyAppName "G7_greenbox"
#define MyAppExe "G7-windows-i386"
#define MyAppPublisher "bring.out"
#define MyAppURL "https://www.bring.out.ba"
#define MyAppContact "https://www.bring.out.ba"

;#define greenboxIsoPath "..\bundle\greenbox.iso"
#define dockerCli "..\bundle\docker.exe"
#define dockerMachineCli "..\bundle\docker-machine.exe"
;#define dockerComposeCli "..\bundle\docker-compose.exe"
;#define kitematic "..\bundle\kitematic"
#define git "..\bundle\Git.exe"
#define virtualBoxCommon "..\bundle\common.cab"
#define virtualBoxMsi "..\bundle\VirtualBox.msi"
;#define vs2013_vcredist_x86 "..\bundle\vs2013_vcredist_x86.exe"

[Setup]
AppCopyright={#MyAppPublisher}
AppId={{BB4417F0-D7F3-48DC-BCE1-F5ED5BAFFD00}
AppContact={#MyAppContact}
AppComments={#MyAppURL}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
;ArchitecturesAllowed=x64
;ArchitecturesInstallIn64BitMode=x64
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName=Greenbox
DisableProgramGroupPage=yes
DisableWelcomePage=no
OutputBaseFilename={#MyAppExe}
Compression=lzma
SolidCompression=yes
WizardImageFile=windows-installer-side.bmp
WizardSmallImageFile=windows-installer-logo.bmp
WizardImageStretch=yes
UninstallDisplayIcon={app}\unins000.exe
SetupIconFile=toolbox.ico
ChangesEnvironment=true

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Run]
Filename: "{win}\explorer.exe"; Parameters: "{userprograms}\Docker\"; Flags: postinstall skipifsilent; Description: "View Shortcuts in File Explorer"

[Tasks]
Name: desktopicon; Description: "{cm:CreateDesktopIcon}"
Name: modifypath; Description: "Add docker binaries to &PATH"
Name: upgradevm; Description: "Upgrade greenbox VM"
Name: vbox_ndis5; Description: "Install VirtualBox with NDIS5 driver[default NDIS6]"; Components: VirtualBox; Flags: unchecked

[Components]
Name: "Docker"; Description: "Docker Client for Windows" ; Types: full custom; Flags: fixed
Name: "DockerMachine"; Description: "Docker Machine for Windows" ; Types: full custom; Flags: fixed
;Name: "DockerCompose"; Description: "Docker Compose for Windows" ; Types: full custom
Name: "VirtualBox"; Description: "VirtualBox"; Types: full custom; Flags: disablenouninstallwarning
;Name: "Kitematic"; Description: "Kitematic for Windows (Alpha)" ; Types: full custom
Name: "Git"; Description: "Git for Windows"; Types: full custom; Flags: disablenouninstallwarning
;Name: "VCRedist2013"; Description: "VC Redistribution package VS2013"; Types: full custom; Flags: fixed

[Files]
Source: ".\docker-quickstart-terminal.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#dockerCli}"; DestDir: "{app}"; Flags: ignoreversion; Components: "Docker"
Source: ".\start.sh"; DestDir: "{app}"; Flags: ignoreversion; Components: "Docker"

Source: ".\sshd_service.sh"; DestDir: "{app}"; Flags: ignoreversion; Components: "Git"
Source: ".\cygrunsrv.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: "Git"
Source: ".\editrights.exe"; DestDir: "{app}"; Flags: ignoreversion; Components: "Git"

Source: "{#dockerMachineCli}"; DestDir: "{app}"; Flags: ignoreversion; Components: "DockerMachine"
;Source: "{#dockerComposeCli}"; DestDir: "{app}"; Flags: ignoreversion; Components: "DockerCompose"
;Source: "{#kitematic}\*"; DestDir: "{app}\kitematic"; Flags: ignoreversion recursesubdirs; Components: "Kitematic"
;Source: "{#greenboxIsoPath}"; DestDir: "{app}"; Flags: ignoreversion; Components: "DockerMachine"; AfterInstall: CopyGreenboxISO()
Source: "{#git}"; DestDir: "{app}\installers\git"; DestName: "git.exe"; AfterInstall: RunInstallGit();  Components: "Git"
Source: "{#virtualBoxCommon}"; DestDir: "{app}\installers\virtualbox"; Components: "VirtualBox"
Source: "{#virtualBoxMsi}"; DestDir: "{app}\installers\virtualbox"; DestName: "virtualbox.msi"; AfterInstall: RunInstallVirtualBox(); Components: "VirtualBox"
;Source: "{#vs2013_vcredist_x86}";  DestDir: "{app}\installers\vs2013_vcredist_x86"; DestName: "vcredist_x86.exe"; AfterInstall: RunInstallVCRedistX86(); Components: "VCRedist2013"


[Icons]
;Name: "{userprograms}\Docker\Kitematic (Alpha)"; WorkingDir: "{app}"; Filename: "{app}\kitematic\Kitematic.exe"; Components: "Kitematic"
;Name: "{commondesktop}\Kitematic (Alpha)"; WorkingDir: "{app}"; Filename: "{app}\kitematic\Kitematic.exe"; Tasks: desktopicon; Components: "Kitematic"
Name: "{userprograms}\Docker\GreenBox Quickstart Terminal"; WorkingDir: "{app}"; Filename: "{pf}\Git\bin\bash.exe"; Parameters: "--login -i ""{app}\start.sh"""; IconFilename: "{app}/docker-quickstart-terminal.ico"; Components: "Docker"
Name: "{userprograms}\Docker\GreenBox Create Tasks RunAsAdmin"; WorkingDir: "{app}"; Filename: "{pf}\Git\bin\bash.exe"; Parameters: "--login -i ""{app}\create_tasks.sh"""; IconFilename: "{app}/docker-quickstart-terminal.ico"; Components: "Git"

Name: "{commondesktop}\GreenBox Quickstart Terminal"; WorkingDir: "{app}"; Filename: "{pf}\Git\bin\bash.exe"; Parameters: "--login -i ""{app}\start.sh"""; IconFilename: "{app}/docker-quickstart-terminal.ico"; Tasks: desktopicon; Components: "Docker"
Name: "{commondesktop}\GreenBox git bash"; WorkingDir: "{app}"; Filename: "{pf}\Git\git-bash.exe"; Parameters: ""; IconFilename: "{app}/toolbox.ico"; Tasks: desktopicon; Components: "Docker"

[UninstallRun]
Filename: "{app}\docker-machine.exe"; Parameters: "rm -f default"

[UninstallDelete]
;Type: filesandordirs; Name: "{localappdata}\..\Roaming\Kitematic"

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName:"DOCKER_TOOLBOX_INSTALL_PATH"; ValueData:"{app}" ; Flags: preservestringtype uninsdeletevalue;

[Code]
#include "base64.iss"
#include "guid.iss"


function uuid(): String;
var
  dirpath: String;
  filepath: String;
  ansiresult: AnsiString;
begin
  dirpath := ExpandConstant('{userappdata}\DockerToolbox');
  filepath := dirpath + '\id.txt';
  ForceDirectories(dirpath);

  Result := '';
  if FileExists(filepath) then
    LoadStringFromFile(filepath, ansiresult);
    Result := String(ansiresult)

  if Length(Result) = 0 then
    Result := GetGuid('');
    StringChangeEx(Result, '{', '', True);
    StringChangeEx(Result, '}', '', True);
    SaveStringToFile(filepath, AnsiString(Result), False);
end;

function WindowsVersionString(): String;
var
  ResultCode: Integer;
  lines : TArrayOfString;
begin
  if not Exec(ExpandConstant('{cmd}'), ExpandConstant('/c wmic os get caption | more +1 > C:\windows-version.txt'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then begin
    Result := 'N/A';
    exit;
  end;

  if LoadStringsFromFile(ExpandConstant('C:\windows-version.txt'), lines) then begin
    Result := lines[0];
  end else begin
    Result := 'N/A'
  end;
end;




function NeedToInstallVirtualBox(): Boolean;
begin
  // TODO: Also compare versions
  Result := (
    (GetEnv('VBOX_INSTALL_PATH') = '')
    and
    (GetEnv('VBOX_MSI_INSTALL_PATH') = '')
  );
end;

function VBoxPath(): String;
begin
  if GetEnv('VBOX_INSTALL_PATH') <> '' then
    Result := GetEnv('VBOX_INSTALL_PATH')
  else
    Result := GetEnv('VBOX_MSI_INSTALL_PATH')
end;

function NeedToInstallGit(): Boolean;
begin
  // TODO: Find a better way to see if Git is installed
  Result := not DirExists('C:\Program Files\Git') or not FileExists('C:\Program Files\Git\git-bash.exe')
end;

procedure InitializeWizard;
var
  WelcomePage: TWizardPage;
begin

  WelcomePage := PageFromID(wpWelcome)

  WizardForm.WelcomeLabel2.AutoSize := True;

    //0 Name: "Docker";
    //1 Name: "DockerMachine";
    //2 Name: "VirtualBox";
    //3 Name: "Git";


    // Don't do this until we can compare versions
    // Wizardform.ComponentsList.Checked[2] := NeedToInstallVirtualBox();
    Wizardform.ComponentsList.ItemEnabled[2] := not NeedToInstallVirtualBox();
    Wizardform.ComponentsList.Checked[3] := NeedToInstallGit();
end;

function InitializeSetup(): boolean;
begin
  Result := True;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  if CurPageID = wpWelcome then begin
      CreateDir(ExpandConstant('{userappdata}\..\.docker\machine'));
      SaveStringToFile(ExpandConstant('{userappdata}\..\.docker\machine\no-error-report'), '', False);
  end;
  Result := True
end;

procedure RunInstallVirtualBox();
var
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing VirtualBox'
  if IsTaskSelected('vbox_ndis5') then begin
    if not Exec(ExpandConstant('msiexec'), ExpandConstant('/qn /i "{app}\installers\virtualbox\virtualbox.msi" NETWORKTYPE=NDIS5 /norestart'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      MsgBox('virtualbox install failure', mbInformation, MB_OK);
  end else begin
    if not Exec(ExpandConstant('msiexec'), ExpandConstant('/qn /i "{app}\installers\virtualbox\virtualbox.msi" /norestart'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      MsgBox('virtualbox install failure', mbInformation, MB_OK);
	end;
end;

procedure RunInstallGit();
var
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing Git for Windows'
  if Exec(ExpandConstant('{app}\installers\git\git.exe'), '/sp- /verysilent /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    // handle success if necessary; ResultCode contains the exit code
    //MsgBox('git installed OK', mbInformation, MB_OK);
  end
  else begin
    // handle failure if necessary; ResultCode contains the error code
    MsgBox('git install failure', mbInformation, MB_OK);
  end;
end;

(*
procedure RunInstallVCRedistX86();
var
  ResultCode: Integer;
begin
  WizardForm.FilenameLabel.Caption := 'installing VS2013 VC redist x86 package'
  if Exec(ExpandConstant('{app}\installers\vs2013_vcredist_x86\\vcredist_x86.exe'), '/sp- /verysilent /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    // handle success if necessary; ResultCode contains the exit code
    //MsgBox('vcredist OK', mbInformation, MB_OK);
  end
  else begin
    // handle failure if necessary; ResultCode contains the error code
    MsgBox('VC MS2013 x86 install failure', mbInformation, MB_OK);
  end;
end;
*)

procedure CopyGreenboxISO();
begin
  WizardForm.FilenameLabel.Caption := 'copying greenbox iso'
  if not ForceDirectories(ExpandConstant('{userappdata}\..\.docker\machine\cache')) then
      MsgBox('Failed to create docker machine cache dir', mbError, MB_OK);
  if not FileCopy(ExpandConstant('{app}\greenbox.iso'), ExpandConstant('{userappdata}\..\.docker\machine\cache\greenbox.iso'), false) then
      MsgBox('File moving failed!', mbError, MB_OK);
end;

function CanUpgradeVM(): Boolean;
var
  ResultCode: Integer;
begin
  if NeedToInstallVirtualBox() or not FileExists(ExpandConstant('{app}\docker-machine.exe')) then begin
    Result := false
    exit
  end;

  ExecAsOriginalUser(VBoxPath() + 'VBoxManage.exe', 'showvminfo default', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  if ResultCode <> 0 then begin
    Result := false
    exit
  end;

  if not DirExists(ExpandConstant('{userappdata}\..\.docker\machine\machines\default')) then begin
    Result := false
    exit
  end;

  Result := true
end;

function UpgradeVM() : Boolean;
var
  ResultCode: Integer;
begin
  WizardForm.StatusLabel.Caption := 'Upgrading G7_greenbox VM...'
  ExecAsOriginalUser(ExpandConstant('{app}\docker-machine.exe'), 'stop default', '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
  if (ResultCode = 0) or (ResultCode = 1) then
  begin
    FileCopy(ExpandConstant('{userappdata}\..\.docker\machine\cache\greenbox.iso'), ExpandConstant('{userappdata}\..\.docker\machine\machines\default\greenbox.iso'), false)
  end
  else begin
    MsgBox('VM Upgrade Failed because the VirtualBox VM could not be stopped.', mbCriticalError, MB_OK);
    Result := false
    WizardForm.Close;
    exit;
  end;
  Result := true
end;

const
  ModPathName = 'modifypath';
  ModPathType = 'user';

function ModPathDir(): TArrayOfString;
begin
  setArrayLength(Result, 1);
  Result[0] := ExpandConstant('{app}');
end;
#include "modpath.iss"

procedure CurStepChanged(CurStep: TSetupStep);
var
  Success: Boolean;
begin
  Success := True;
  if CurStep = ssPostInstall then
  begin
    if IsTaskSelected(ModPathName) then
      ModPath();
    if not WizardSilent() then
    begin
      if IsTaskSelected('upgradevm') then
      begin
        if CanUpgradeVM() then begin
          Success := UpgradeVM();
        end;
      end;
    end;

  end;
end;
