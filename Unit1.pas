unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, RunElevatedSupport, Winapi.ShellAPI,
  Vcl.Mask, Vcl.Grids, Vcl.ValEdit, IdIcmpClient, IdBaseComponent, IdComponent,
  IdRawBase, IdRawClient, Vcl.ExtCtrls, IdStack, KMSServers, Registry,
  Vcl.ComCtrls, Vcl.ButtonGroup;

type
  TForm1 = class(TForm)
    ltopIsElevated: TLabel;
    ltopIsAdmin: TLabel;
    bEzCMD: TButton;
    bNewHostname: TButton;
    eOSKey: TEdit;
    ltopPN: TLabel;
    vleOSKeys: TValueListEditor;
    bChooseKey: TButton;
    bSetGVLK: TButton;
    bAct: TButton;
    lOSChosen: TLabel;
    icmpC1: TIdIcmpClient;
    gbKMSServers: TGroupBox;
    lKMS01: TLabel;
    lKMS02: TLabel;
    shOnline1: TShape;
    shOnline2: TShape;
    bSetServer: TButton;
    eNewHostname: TEdit;
    gbActivator: TGroupBox;
    cbOpenActivator: TCheckBox;
    ltopEditionID: TLabel;
    bEzCMDAs: TButton;
    bEzPowershell: TButton;
    bEzControl: TButton;
    bEzMSConfig: TButton;
    bEzREG: TButton;
    pTop: TPanel;
    pEzButtons: TPanel;
    pcMain: TPageControl;
    pcEZB: TTabSheet;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure bNewHostnameClick(Sender: TObject);
    procedure emNewHostnameChange(Sender: TObject);
    procedure bChooseKeyClick(Sender: TObject);
    procedure bSetGVLKClick(Sender: TObject);
    procedure bSetServerClick(Sender: TObject);
    procedure bActClick(Sender: TObject);
    procedure cbOpenActivatorClick(Sender: TObject);
    procedure eNewHostnameChange(Sender: TObject);
    procedure bEzCMDAsClick(Sender: TObject);
    procedure bEzCMDClick(Sender: TObject);
    procedure bEzPowershellClick(Sender: TObject);
    procedure bEzControlClick(Sender: TObject);
    procedure bEzREGClick(Sender: TObject);
    procedure bEzMSConfigClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  HNDL: HWND;
  normalformW: Integer;
  normalformH: Integer;


implementation

{$R *.dfm}

//function RunAsAdmin(const Handle: Hwnd; const Path, Params: string): Boolean;
////var OK: Boolean;
//begin
//  ShellExecute(Handle, 'RunAs', PWideChar(Path), PWideChar(Params), nil, SW_SHOWNORMAL);
//  //if not OK then Result := False else Result := True;
//end;


function GetRegistryValue(KeyName: String; Value: String): String;
 var
   Registry: TRegistry;
 begin
   Registry := TRegistry.Create(KEY_READ);
   try
     Registry.RootKey := HKEY_LOCAL_MACHINE;

     // False because we do not want to create it if it doesn't exist
     Registry.OpenKeyReadOnly(KeyName);

     Result := Registry.ReadString(Value);
     Registry.CloseKey;
   finally
     Registry.Free;
   end;
 end;


procedure RunAsAdmin(const Path, Params: string);
//var OK: Boolean;
begin
  ShellExecute(HNDL, 'RunAs', PWideChar(Path), PWideChar(Params), nil, SW_HIDE);
  //if not OK then Result := False else Result := True;
end;

procedure RunAsAdminS(const Path, Params: string);
//var OK: Boolean;
begin
  ShellExecute(HNDL, 'RunAs', PWideChar(Path), PWideChar(Params), nil, SW_SHOW);
  //if not OK then Result := False else Result := True;
end;

function ExecuteProcess(const FileName, Params: string; Folder: string; WaitUntilTerminated, WaitUntilIdle, RunMinimized: boolean;
  var ErrorCode: integer): boolean;
var
  CmdLine: string;
  WorkingDirP: PChar;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  Result := true;
  CmdLine := '"' + FileName + '" ' + Params;
  if Folder = '' then Folder := ExcludeTrailingPathDelimiter(ExtractFilePath(FileName));
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  if RunMinimized then
    begin
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_SHOWMINIMIZED;
    end;
  if Folder <> '' then WorkingDirP := PChar(Folder)
  else WorkingDirP := nil;
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, false, 0, nil, WorkingDirP, StartupInfo, ProcessInfo) then
    begin
      Result := false;
      ErrorCode := GetLastError;
      exit;
    end;
  with ProcessInfo do
    begin
      CloseHandle(hThread);
      if WaitUntilIdle then WaitForInputIdle(hProcess, INFINITE);
      if WaitUntilTerminated then
        repeat
          Application.ProcessMessages;
        until MsgWaitForMultipleObjects(1, hProcess, false, INFINITE, QS_ALLINPUT) <> WAIT_OBJECT_0 + 1;
      CloseHandle(hProcess);
    end;
end;

function PSExecuteAs(Command: String): Integer;
begin
  RunAsAdmin('powershell', Command);
end;

function PSExecute(Command: String): Integer;
var
  Error: Integer;
  OK: Boolean;
begin
  OK := ExecuteProcess('Powershell.exe', Command, '', true, false, true, Error);
  if not OK then ShowMessage('Error: ' + IntToStr(Error));
end;

function PExecute(exe: String): Integer;
var
  Error: Integer;
  OK: Boolean;
begin
  OK := ExecuteProcess(exe, '', '', false, false, false, Error);
  if not OK then ShowMessage('Error: ' + IntToStr(Error));
end;

procedure InitKMS;
begin
  Form1.gbKMSServers.Visible := True;
  KMSServers.KMSServersListInit;
  KMSServers.CheckKMSIsOnline;
  Form1.lKMS01.Caption := KMSServers.kms_srv01;
  Form1.lKMS02.Caption := KMSServers.kms_srv02;
  if KMSServers.IsOnline01 = True then Form1.shOnline1.Brush.Color := clGreen else Form1.shOnline1.Brush.Color := clRed;
  if KMSServers.IsOnline02 = True then Form1.shOnline2.Brush.Color := clGreen else Form1.shOnline2.Brush.Color := clRed;
  if KMSServers.SelectedKMSServer = Form1.lKMS01.Caption then Form1.lKMS01.Font.Style := [fsBold] else Form1.lKMS01.Font.Style := [];
  if KMSServers.SelectedKMSServer = Form1.lKMS02.Caption then Form1.lKMS02.Font.Style := [fsBold] else Form1.lKMS02.Font.Style := [];
end;

function GetNetBIOSName: String;
var
  Length: DWord;
begin
  Length := 0;
  GetComputerName(nil, Length);
  SetLength(Result, Length - 1);
  GetComputerName(PChar(Result), Length);
end;

function doOpenActivator(): Boolean;
begin
  //Form1.Width := 590;
  //Form1.Height := normalformH + Form1.gbActivator.Height;
  Form1.gbActivator.Visible := True;
  Form1.gbActivator.Enabled := True;
  Result := True;
end;

function doCloseActivator(): Boolean;
begin
  //Form1.Width := normalformW;
  //Form1.Height := normalformH;
  Form1.gbActivator.Visible := False;
  Form1.gbActivator.Enabled := False;
  Result := False;
end;




procedure TForm1.bEzCMDAsClick(Sender: TObject);
begin
  RunAsAdminS('cmd', '');
end;

procedure TForm1.bEzCMDClick(Sender: TObject);
var
  Error: Integer;
begin
  ExecuteProcess('cmd', '', '', false, false, false, Error);
end;

procedure TForm1.bEzControlClick(Sender: TObject);
begin
  PExecute('control');
end;

procedure TForm1.bEzMSConfigClick(Sender: TObject);
begin
  //RunAsAdminS('C:\Windows\SysNative\msconfig.exe', '')
  RunAsAdminS('powershell', '-c "C:\Windows\SysNative\msconfig.exe"');
end;

procedure TForm1.bEzPowershellClick(Sender: TObject);
begin
  RunAsAdminS('powershell', '');
end;

procedure TForm1.bEzREGClick(Sender: TObject);
begin
  RunAsAdminS('regedit', '');
end;

procedure TForm1.cbOpenActivatorClick(Sender: TObject);
begin
  if not cbOpenActivator.Checked then doCloseActivator
  else doOpenActivator;
end;

procedure TForm1.bSetServerClick(Sender: TObject);
begin
  PSExecute('slmgr /skms ' + KMSServers.SelectedKMSServer);
  bAct.Enabled := True;
end;

procedure TForm1.bActClick(Sender: TObject);
begin
  PSExecute('slmgr /ato');
  bAct.Enabled := False;
end;

procedure TForm1.bChooseKeyClick(Sender: TObject);
var
  I : Integer;
begin
  I := vleOSKeys.Row;
  lOSChosen.Caption := '��: ' + vleOSKeys.Keys[I];
  eOSKey.Text:= vleOSKeys.Cells[1,I];
  InitKMS;

  if ((StringReplace(eOSKey.Text, ' ', '', [rfReplaceAll, rfIgnoreCase]) <> '')) then bSetGVLK.Enabled := True else bSetGVLK.Enabled := False;

end;

procedure TForm1.bSetGVLKClick(Sender: TObject);
begin
  PSExecute('slmgr /ipk ' + StringReplace(eOSKey.Text, ' ', '', [rfReplaceAll, rfIgnoreCase]) + '');
end;

procedure TForm1.bNewHostnameClick(Sender: TObject);
begin
  PSExecute('Rename-Computer -NewName "' + StringReplace(eNewHostname.Text, ' ', '', [rfReplaceAll, rfIgnoreCase]) + '"');
  bNewHostname.Enabled := False;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  //Form1.Height := Form1.Height - gbActivator.Height;
  //normalformW := Form1.Width;
  //normalformH := Form1.Height;
  HNDL := Application.ActiveFormHandle;
  eNewHostname.Text := GetNetBIOSName;

  //Init Top labels w/ info about sys

  ltopIsElevated.Caption := 'Is Elevated: ' + BoolToStr(IsElevated);
  ltopIsAdmin.Caption := 'Is Admin: ' + BoolToStr(IsAdministrator);
  //ltopUAC.Caption := 'UAC: ' + BoolToStr(IsUACEnabled);
  ltopPN.Caption := GetRegistryValue('SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'ProductName');
  ltopEditionID.Caption := GetRegistryValue('SOFTWARE\Microsoft\Windows NT\CurrentVersion', 'EditionID');


  // Init KMS servers status and publishing it to labels

end;

procedure TForm1.emNewHostnameChange(Sender: TObject);
begin
  TMaskEdit(Sender).Modified := False;
end;

procedure TForm1.eNewHostnameChange(Sender: TObject);
begin
  bNewHostname.Enabled := True;
end;

end.
