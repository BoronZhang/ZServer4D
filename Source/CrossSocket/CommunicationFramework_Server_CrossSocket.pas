{ ****************************************************************************** }
{ * CrossSocket support                                                        * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
(* https://github.com/PassByYou888/ZServer4D *)
{ ****************************************************************************** }
(*
  update history
*)
unit CommunicationFramework_Server_CrossSocket;

{$I ..\zDefine.inc}

interface

uses SysUtils, Classes,
  Net.CrossSocket, Net.SocketAPI, Net.CrossSocket.Base, Net.CrossServer,
  PascalStrings,
  CommunicationFramework, CoreClasses, UnicodeMixedLib, MemoryStream64,
  DataFrameEngine;

type
  TContextIntfForServer = class(TPeerClient)
  public
    LastActiveTime: TTimeTickValue;
    Sending       : Boolean;
    SendBuffQueue : TCoreClassListForObj;
    CurrentBuff   : TMemoryStream64;

    constructor Create(AOwnerFramework: TCommunicationFramework; AClientIntf: TCoreClassObject); override;
    destructor Destroy; override;

    function Context: TCrossConnection;
    function Connected: Boolean; override;
    procedure Disconnect; override;
    procedure SendBuffResult(AConnection: ICrossConnection; ASuccess: Boolean);
    procedure SendByteBuffer(buff: PByte; size: Integer); override;
    procedure WriteBufferOpen; override;
    procedure WriteBufferFlush; override;
    procedure WriteBufferClose; override;
    function GetPeerIP: SystemString; override;
    function WriteBufferEmpty: Boolean; override;
  end;

  TDriverEngine = TCrossSocket;

  TCommunicationFramework_Server_CrossSocket = class(TCommunicationFrameworkServer)
  private
    FDriver        : TDriverEngine;
    FStartedService: Boolean;
    FBindHost      : SystemString;
    FBindPort      : Word;

    procedure DoConnected(Sender: TObject; AConnection: ICrossConnection); virtual;
    procedure DoDisconnect(Sender: TObject; AConnection: ICrossConnection); virtual;
    procedure DoReceived(Sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer); virtual;
    procedure DoSent(Sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer); virtual;
  public
    constructor Create; override;
    destructor Destroy; override;

    function StartService(Host: SystemString; Port: Word): Boolean; override;
    procedure StopService; override;

    procedure TriggerQueueData(v: PQueueData); override;
    procedure ProgressBackground; override;

    function WaitSendConsoleCmd(Client: TPeerClient; Cmd: SystemString; ConsoleData: SystemString; TimeOut: TTimeTickValue): SystemString; overload; override;
    procedure WaitSendStreamCmd(Client: TPeerClient; Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; TimeOut: TTimeTickValue); overload; override;

    property StartedService: Boolean read FStartedService;
    property Driver: TDriverEngine read FDriver;
    property BindPort: Word read FBindPort;
    property BindHost: SystemString read FBindHost;
  end;

implementation

constructor TContextIntfForServer.Create(AOwnerFramework: TCommunicationFramework; AClientIntf: TCoreClassObject);
begin
  inherited Create(AOwnerFramework, AClientIntf);
  LastActiveTime := GetTimeTickCount;
  Sending := False;
  SendBuffQueue := TCoreClassListForObj.Create;
  CurrentBuff := TMemoryStream64.Create;
end;

destructor TContextIntfForServer.Destroy;
var
  i: Integer;
begin
  for i := 0 to SendBuffQueue.Count - 1 do
      disposeObject(SendBuffQueue[i]);

  disposeObject(SendBuffQueue);

  disposeObject(CurrentBuff);
  inherited Destroy;
end;

function TContextIntfForServer.Context: TCrossConnection;
begin
  Result := ClientIntf as TCrossConnection;
end;

function TContextIntfForServer.Connected: Boolean;
begin
  Result := (ClientIntf <> nil) and
    (Context.ConnectStatus = TConnectStatus.csConnected);
end;

procedure TContextIntfForServer.Disconnect;
begin
  if not Connected then
      exit;
  Context.Disconnect;
end;

procedure TContextIntfForServer.SendBuffResult(AConnection: ICrossConnection; ASuccess: Boolean);
begin
  LastActiveTime := GetTimeTickCount;

  // Ϊ����ʹ�÷�ҳ�潻���ڴ棬��io�ں˷��ͽ���ͬ�������߳�����
  TThread.Synchronize(nil,
    procedure
    var
      i: Integer;
      m: TMemoryStream64;
      isConn: Boolean;
    begin
      isConn := False;
      try
        isConn := Connected;
        if (ASuccess and isConn) then
          begin
            if SendBuffQueue.Count > 0 then
              begin
                m := TMemoryStream64(SendBuffQueue[0]);

                // WSASend���·���ʱ���Ḵ��һ�ݸ������������ڴ濽������������Ϊ32k�����ڵײ���������ƬԤ�ü�
                // ע�⣺�¼�ʽ�ص����͵�buff����������ݶ�ջ��С����
                // ��лak47 qq512757165 �Ĳ��Ա���
                Context.SendBuf(m.Memory, m.size, SendBuffResult);

                // �ͷ��ڴ�
                disposeObject(m);
                // �ͷŶ���
                SendBuffQueue.Delete(0);
              end
            else
              begin
                Sending := False;
              end;
          end
        else
          begin
            // �ͷŶ��пռ�
            for i := 0 to SendBuffQueue.Count - 1 do
                disposeObject(SendBuffQueue[i]);
            SendBuffQueue.Clear;

            Sending := False;

            if isConn then
                Print('send failed!')
            else
                Print('invailed connected!,send failed!');
            Disconnect;
          end;
      except
        Print('send failed!');
        Disconnect;
      end;
    end);
end;

procedure TContextIntfForServer.SendByteBuffer(buff: PByte; size: Integer);
begin
  if not Connected then
      exit;

  LastActiveTime := GetTimeTickCount;

  // �������������������ϵͳ��Դ��������Ҫ������Ƭ�ռ�
  // ��flush��ʵ�־�ȷ�첽���ͺ�У��
  if size > 0 then
      CurrentBuff.Write(Pointer(buff)^, size);
end;

procedure TContextIntfForServer.WriteBufferOpen;
begin
  if not Connected then
      exit;
  LastActiveTime := GetTimeTickCount;
  CurrentBuff.Clear;
end;

procedure TContextIntfForServer.WriteBufferFlush;
var
  ms: TMemoryStream64;
begin
  if not Connected then
      exit;
  LastActiveTime := GetTimeTickCount;

  if Sending then
    begin
      if CurrentBuff.size > 0 then
        begin
          // ����Ż�
          ms := CurrentBuff;
          ms.Position := 0;
          SendBuffQueue.Add(ms);
          CurrentBuff := TMemoryStream64.Create;
        end;
    end
  else
    begin
      // WSASend���·���ʱ���Ḵ��һ�ݸ������������ڴ濽������������Ϊ32k�����ڵײ���������ƬԤ�ü�
      // ע�⣺�¼�ʽ�ص����͵�buff����������ݶ�ջ��С����
      // ��лak47 qq512757165 �Ĳ��Ա���
      Sending := True;
      Context.SendBuf(CurrentBuff.Memory, CurrentBuff.size, SendBuffResult);
      CurrentBuff.Clear;
    end;
end;

procedure TContextIntfForServer.WriteBufferClose;
begin
  if not Connected then
      exit;
  CurrentBuff.Clear;
end;

function TContextIntfForServer.GetPeerIP: SystemString;
begin
  if Connected then
      Result := Context.PeerAddr
  else
      Result := '';
end;

function TContextIntfForServer.WriteBufferEmpty: Boolean;
begin
  Result := not Sending;
end;

procedure TCommunicationFramework_Server_CrossSocket.DoConnected(Sender: TObject; AConnection: ICrossConnection);
var
  cli: TContextIntfForServer;
begin
  TThread.Synchronize(TThread.CurrentThread,
    procedure
    begin
      cli := TContextIntfForServer.Create(Self, AConnection.ConnectionIntf);
      cli.LastActiveTime := GetTimeTickCount;
      AConnection.UserObject := cli;
    end);
end;

procedure TCommunicationFramework_Server_CrossSocket.DoDisconnect(Sender: TObject; AConnection: ICrossConnection);
begin
  TThread.Synchronize(TThread.CurrentThread,
    procedure
    var
      cli: TContextIntfForServer;
    begin
      cli := AConnection.UserObject as TContextIntfForServer;
      if cli <> nil then
        begin
          try
            cli.ClientIntf := nil;
            AConnection.UserObject := nil;
            disposeObject(cli);
          except
          end;
        end;
    end);
end;

procedure TCommunicationFramework_Server_CrossSocket.DoReceived(Sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer);
begin
  if ALen <= 0 then
      exit;

  if AConnection.UserObject = nil then
      exit;

  TThread.Synchronize(TThread.CurrentThread,
    procedure
    var
      cli: TContextIntfForServer;
    begin
      try
        cli := AConnection.UserObject as TContextIntfForServer;
        if cli.ClientIntf = nil then
            exit;

        cli.LastActiveTime := GetTimeTickCount;
        cli.ReceivedBuffer.Position := cli.ReceivedBuffer.size;
        cli.ReceivedBuffer.Write(ABuf^, ALen);
        cli.FillRecvBuffer(nil, False, False);
      except
      end;
    end);
end;

procedure TCommunicationFramework_Server_CrossSocket.DoSent(Sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer);
var
  cli: TContextIntfForServer;
begin
  if AConnection.UserObject = nil then
      exit;

  cli := AConnection.UserObject as TContextIntfForServer;
  if cli.ClientIntf = nil then
      exit;
  cli.LastActiveTime := GetTimeTickCount;
end;

constructor TCommunicationFramework_Server_CrossSocket.Create;
var
  r: TCommandStreamMode;
begin
  inherited Create;
  FDriver := TDriverEngine.Create(4);
  FDriver.OnConnected := DoConnected;
  FDriver.OnDisconnected := DoDisconnect;
  FDriver.OnReceived := DoReceived;
  FDriver.OnSent := DoSent;
  FStartedService := False;
  FBindPort := 0;
  FBindHost := '';
end;

destructor TCommunicationFramework_Server_CrossSocket.Destroy;
begin
  StopService;
  try
      disposeObject(FDriver);
  except
  end;
  inherited Destroy;
end;

function TCommunicationFramework_Server_CrossSocket.StartService(Host: SystemString; Port: Word): Boolean;
var
  completed, successed: Boolean;
begin
  StopService;

  completed := False;
  successed := False;
  try
    ICrossSocket(FDriver).Listen(Host, Port,
      procedure(Listen: ICrossListen; ASuccess: Boolean)
      begin
        completed := True;
        successed := ASuccess;
      end);

    while not completed do
        CheckSynchronize(5);

    FBindPort := Port;
    FBindHost := Host;
    Result := successed;
    FStartedService := Result;
  except
      Result := False;
  end;
end;

procedure TCommunicationFramework_Server_CrossSocket.StopService;
begin
  try
    try
        ICrossSocket(FDriver).CloseAll;
    except
    end;
    FStartedService := False;
  except
  end;
end;

procedure TCommunicationFramework_Server_CrossSocket.TriggerQueueData(v: PQueueData);
begin
  (*
    TThread.Synchronize(nil,
    procedure
    begin
    end);
  *)
  if not Exists(v^.Client) then
    begin
      DisposeQueueData(v);
      exit;
    end;

  v^.Client.PostQueueData(v);
  v^.Client.ProcessAllSendCmd(nil, False, False);
end;

procedure TCommunicationFramework_Server_CrossSocket.ProgressBackground;
var
  IDPool: TClientIDPool;
  pid   : Cardinal;
  c     : TContextIntfForServer;
begin
  GetClientIDPool(IDPool);
  try
    for pid in IDPool do
      begin
        c := TContextIntfForServer(ClientFromID[pid]);
        if c <> nil then
          begin
            if (IdleTimeout > 0) and (GetTimeTickCount - c.LastActiveTime > IdleTimeout) then
                c.Disconnect
            else
              begin
                if c.Connected then
                    c.ProcessAllSendCmd(nil, False, False);
              end;
          end;
      end;
  except
  end;

  inherited ProgressBackground;

  CheckSynchronize;
end;

function TCommunicationFramework_Server_CrossSocket.WaitSendConsoleCmd(Client: TPeerClient; Cmd: SystemString; ConsoleData: SystemString; TimeOut: TTimeTickValue): SystemString;
begin
  Result := '';
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

procedure TCommunicationFramework_Server_CrossSocket.WaitSendStreamCmd(Client: TPeerClient; Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; TimeOut: TTimeTickValue);
begin
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

initialization

finalization

end.
