{ ****************************************************************************** }
{ * DIOCP Support                                                              * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ ****************************************************************************** }
(*
  update history
*)
unit CommunicationFramework_Server_DIOCP;

{$I ..\zDefine.inc}

interface

uses SysUtils, Classes,
  PascalStrings,
  CommunicationFramework, CoreClasses, UnicodeMixedLib, MemoryStream64, DataFrameEngine,
  diocp_tcp_server;

type
  TPeerIOWithDIOCPServer = class;

  TIocpClientContextIntf_WithDServ = class(TIocpClientContext)
  private
    Link: TPeerIOWithDIOCPServer;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  TPeerIOWithDIOCPServer = class(TPeerIO)
  private
    Link             : TIocpClientContextIntf_WithDServ;
    lastSendBufferTag: Integer;
    WasSending       : Boolean;
    SendingStream    : TMemoryStream64;
  public
    procedure CreateAfter; override;
    destructor Destroy; override;

    function Connected: Boolean; override;
    procedure Disconnect; override;
    procedure SendByteBuffer(const buff: PByte; const Size: NativeInt); override;
    procedure WriteBufferOpen; override;
    procedure WriteBufferFlush; override;
    procedure WriteBufferClose; override;
    function GetPeerIP: SystemString; override;
    function WriteBufferEmpty: Boolean; override;
    procedure Progress; override;
  end;

  TCommunicationFramework_Server_DIOCP = class(TCommunicationFrameworkServer)
  private
  protected
    FDIOCPServer: TDiocpTcpServer;

    procedure DIOCP_IOConnected(pvClientContext: TIocpClientContext);
    procedure DIOCP_IODisconnect(pvClientContext: TIocpClientContext);
    procedure DIOCP_IOSend(pvContext: TIocpClientContext; pvRequest: TIocpSendRequest);
    procedure DIOCP_IOSendCompleted(pvContext: TIocpClientContext; pvBuff: Pointer; len: Cardinal; pvBufferTag: Integer; pvTagData: Pointer; pvErrorCode: Integer);
    procedure DIOCP_IOReceive(pvClientContext: TIocpClientContext; buf: Pointer; len: Cardinal; errCode: Integer);
  public
    constructor Create; override;
    destructor Destroy; override;

    function StartService(Host: SystemString; Port: Word): Boolean; override;
    procedure StopService; override;

    procedure TriggerQueueData(v: PQueueData); override;
    procedure ProgressBackground; override;

    function WaitSendConsoleCmd(Client: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut: TTimeTickValue): SystemString; override;
    procedure WaitSendStreamCmd(Client: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; TimeOut: TTimeTickValue); override;
  end;

implementation

constructor TIocpClientContextIntf_WithDServ.Create;
begin
  inherited Create;
  Link := nil;
end;

destructor TIocpClientContextIntf_WithDServ.Destroy;
var
  peerio: TPeerIOWithDIOCPServer;
begin
  if Link <> nil then
    begin
      peerio := Link;
      Link := nil;
      DisposeObject(peerio);
    end;
  inherited Destroy;
end;

procedure TPeerIOWithDIOCPServer.CreateAfter;
begin
  inherited CreateAfter;
  Link := nil;
  lastSendBufferTag := 0;
  WasSending := False;
  SendingStream := TMemoryStream64.Create;
end;

destructor TPeerIOWithDIOCPServer.Destroy;
begin
  if Link <> nil then
    begin
      // ϵͳ��ɫ���������ƻ�����ʱ������ֱ��close������postһ����Ϣ��ȥ
      // �����ᵼ�¶��߲���һ��С���ӳ٣����ﲻӰ������
      Link.PostWSACloseRequest;
      Link.Link := nil;
    end;

  DisposeObject(SendingStream);
  inherited Destroy;
end;

function TPeerIOWithDIOCPServer.Connected: Boolean;
begin
  Result := (Link <> nil);
end;

procedure TPeerIOWithDIOCPServer.Disconnect;
begin
  Link.PostWSACloseRequest;
end;

procedure TPeerIOWithDIOCPServer.SendByteBuffer(const buff: PByte; const Size: NativeInt);
begin
  if not Connected then
      exit;

  if Size > 0 then
      SendingStream.WritePtr(buff, Size);
end;

procedure TPeerIOWithDIOCPServer.WriteBufferOpen;
begin
  WriteBufferFlush;
end;

procedure TPeerIOWithDIOCPServer.WriteBufferFlush;
begin
  if SendingStream.Size > 0 then
    begin
      inc(lastSendBufferTag);
      WasSending := True;
      // ��ΪDIOCP�ķ����ǻ������ݶ��е�
      // �����е�Ԥ�������Զ��з�ʽfill���ٷ���
      // ��������flush��ʽ���û��������ݣ�����ÿ�η��ͳ�ȥ����һ���飬һ����˵�����ﱻzs����ʱ������һ��ip�����ҵĴ�С��������Ƭ
      Link.PostWSASendRequest(SendingStream.Memory, SendingStream.Size, True, lastSendBufferTag);
      SendingStream.Clear;
    end;
end;

procedure TPeerIOWithDIOCPServer.WriteBufferClose;
begin
  WriteBufferFlush;
end;

function TPeerIOWithDIOCPServer.GetPeerIP: SystemString;
begin
  if Connected then
      Result := Link.RemoteAddr + ' ' + IntToStr(Link.RemotePort)
  else
      Result := '';
end;

function TPeerIOWithDIOCPServer.WriteBufferEmpty: Boolean;
begin
  Result := not WasSending;
end;

procedure TPeerIOWithDIOCPServer.Progress;
begin
  inherited Progress;
  ProcessAllSendCmd(nil, False, False);
end;

procedure TCommunicationFramework_Server_DIOCP.DIOCP_IOConnected(pvClientContext: TIocpClientContext);
begin
  TIocpClientContextIntf_WithDServ(pvClientContext).Link := TPeerIOWithDIOCPServer.Create(Self, pvClientContext);
  TIocpClientContextIntf_WithDServ(pvClientContext).Link.Link := TIocpClientContextIntf_WithDServ(pvClientContext);
end;

procedure TCommunicationFramework_Server_DIOCP.DIOCP_IODisconnect(pvClientContext: TIocpClientContext);
var
  peerio: TPeerIOWithDIOCPServer;
begin
  if TIocpClientContextIntf_WithDServ(pvClientContext).Link = nil then
      exit;

  peerio := TIocpClientContextIntf_WithDServ(pvClientContext).Link;
  TIocpClientContextIntf_WithDServ(pvClientContext).Link := nil;
  DisposeObject(peerio);
end;

procedure TCommunicationFramework_Server_DIOCP.DIOCP_IOSend(pvContext: TIocpClientContext; pvRequest: TIocpSendRequest);
begin
end;

procedure TCommunicationFramework_Server_DIOCP.DIOCP_IOSendCompleted(pvContext: TIocpClientContext; pvBuff: Pointer; len: Cardinal; pvBufferTag: Integer; pvTagData: Pointer; pvErrorCode: Integer);
var
  peerio: TPeerIOWithDIOCPServer;
begin
  if TIocpClientContextIntf_WithDServ(pvContext).Link = nil then
      exit;
  peerio := TIocpClientContextIntf_WithDServ(pvContext).Link;
  if peerio.lastSendBufferTag = pvBufferTag then
      peerio.WasSending := False;
end;

procedure TCommunicationFramework_Server_DIOCP.DIOCP_IOReceive(pvClientContext: TIocpClientContext; buf: Pointer; len: Cardinal; errCode: Integer);
begin
  if TIocpClientContextIntf_WithDServ(pvClientContext).Link = nil then
      exit;

  // zs�ں����°汾�Ѿ���ȫ֧����100%���첽��������
  // �����򵥷���������¼������������ˣ��ƺ������е��ӳ�
  // ����������ȵ㲻̫���ң�diocp��ƿ����Ҫ�ǿ�����һ��
  TIocpClientContextIntf_WithDServ(pvClientContext).Link.SaveReceiveBuffer(buf, len);
  TIocpClientContextIntf_WithDServ(pvClientContext).Link.FillRecvBuffer(TThread.CurrentThread, True, True);
end;

constructor TCommunicationFramework_Server_DIOCP.Create;
begin
  inherited Create;
  FDIOCPServer := TDiocpTcpServer.Create(nil);

  FDIOCPServer.OnContextConnected := DIOCP_IOConnected;
  FDIOCPServer.OnContextDisconnected := DIOCP_IODisconnect;
  FDIOCPServer.OnSendRequestResponse := DIOCP_IOSend;
  FDIOCPServer.OnSendBufferCompleted := DIOCP_IOSendCompleted;
  FDIOCPServer.OnDataReceived := DIOCP_IOReceive;

  FDIOCPServer.WorkerCount := 4;
  FDIOCPServer.MaxSendingQueueSize := 20000;
  FDIOCPServer.NoDelayOption := True;
  FDIOCPServer.KeepAlive := True;
  FDIOCPServer.KeepAliveTime := 5000;
  FDIOCPServer.RegisterContextClass(TIocpClientContextIntf_WithDServ);
end;

destructor TCommunicationFramework_Server_DIOCP.Destroy;
begin
  StopService;
  DisposeObject(FDIOCPServer);
  inherited Destroy;
end;

function TCommunicationFramework_Server_DIOCP.StartService(Host: SystemString; Port: Word): Boolean;
begin
  FDIOCPServer.DefaultListenAddress := Host;
  FDIOCPServer.Port := Port;

  try
    FDIOCPServer.Active := True;
    Result := True;
  except
      Result := False;
  end;
end;

procedure TCommunicationFramework_Server_DIOCP.StopService;
begin
  FDIOCPServer.Active := False;
end;

procedure TCommunicationFramework_Server_DIOCP.TriggerQueueData(v: PQueueData);
begin
  if not Exists(v^.Client) then
    begin
      DisposeQueueData(v);
      exit;
    end;

  v^.Client.PostQueueData(v);
  v^.Client.ProcessAllSendCmd(nil, False, False);
end;

procedure TCommunicationFramework_Server_DIOCP.ProgressBackground;
begin
  inherited ProgressBackground;
  CheckSynchronize;
end;

function TCommunicationFramework_Server_DIOCP.WaitSendConsoleCmd(Client: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut: TTimeTickValue): SystemString;
begin
  Result := '';
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

procedure TCommunicationFramework_Server_DIOCP.WaitSendStreamCmd(Client: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; TimeOut: TTimeTickValue);
begin
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

initialization

finalization

end.
