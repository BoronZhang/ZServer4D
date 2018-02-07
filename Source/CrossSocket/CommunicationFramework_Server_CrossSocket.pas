{ ****************************************************************************** }
{ * CrossSocket support                                                        * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ ****************************************************************************** }
(*
  update history
*)
unit CommunicationFramework_Server_CrossSocket;

{$I ..\zDefine.inc}

interface

uses SysUtils, Classes,
  Net.CrossSocket, Net.SocketAPI, Net.CrossSocket.Base, Net.CrossServer,
  PascalStrings, DoStatusIO,
  CommunicationFramework, CoreClasses, UnicodeMixedLib, MemoryStream64,
  DataFrameEngine;

type
  TContextIntfForServer = class(TPeerIO)
  public
    LastActiveTime: TTimeTickValue;
    Sending       : Boolean;
    SendBuffQueue : TCoreClassListForObj;
    CurrentBuff   : TMemoryStream64;
    DelayBuffPool : TCoreClassListForObj;

    procedure CreateAfter; override;
    destructor Destroy; override;

    procedure FreeDelayBuffPool; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    function Context: TCrossConnection; {$IFDEF INLINE_ASM} inline; {$ENDIF}
    //
    function Connected: Boolean; override;
    procedure Disconnect; override;
    procedure SendBuffResult(AConnection: ICrossConnection; ASuccess: Boolean);
    procedure SendByteBuffer(const buff: PByte; const Size: NativeInt); override;
    procedure WriteBufferOpen; override;
    procedure WriteBufferFlush; override;
    procedure WriteBufferClose; override;
    function GetPeerIP: SystemString; override;
    function WriteBufferEmpty: Boolean; override;
    procedure Progress; override;
  end;

  TDriverEngine = TCrossSocket;

  TCommunicationFramework_Server_CrossSocket = class(TCommunicationFrameworkServer)
  private
    FDriver        : TDriverEngine;
    FStartedService: Boolean;
    FBindHost      : SystemString;
    FBindPort      : Word;
  protected
    procedure DoConnected(Sender: TObject; AConnection: ICrossConnection);
    procedure DoDisconnect(Sender: TObject; AConnection: ICrossConnection);
    procedure DoReceived(Sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer);
    procedure DoSent(Sender: TObject; AConnection: ICrossConnection; ABuf: Pointer; ALen: Integer);
  public
    constructor Create; overload; override;
    constructor Create(maxThPool: Word); overload;
    destructor Destroy; override;

    function StartService(Host: SystemString; Port: Word): Boolean; override;
    procedure StopService; override;

    procedure TriggerQueueData(v: PQueueData); override;
    procedure ProgressBackground; override;

    function WaitSendConsoleCmd(Client: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut: TTimeTickValue): SystemString; override;
    procedure WaitSendStreamCmd(Client: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; TimeOut: TTimeTickValue); override;

    property StartedService: Boolean read FStartedService;
    property Driver: TDriverEngine read FDriver;
    property BindPort: Word read FBindPort;
    property BindHost: SystemString read FBindHost;
  end;

implementation

procedure TContextIntfForServer.CreateAfter;
begin
  inherited CreateAfter;
  LastActiveTime := GetTimeTickCount;
  Sending := False;
  SendBuffQueue := TCoreClassListForObj.Create;
  CurrentBuff := TMemoryStream64.Create;
  DelayBuffPool := TCoreClassListForObj.Create;
end;

destructor TContextIntfForServer.Destroy;
var
  i: Integer;
begin
  FreeDelayBuffPool;

  for i := 0 to SendBuffQueue.Count - 1 do
      disposeObject(SendBuffQueue[i]);

  disposeObject(SendBuffQueue);

  disposeObject(CurrentBuff);
  disposeObject(DelayBuffPool);
  inherited Destroy;
end;

procedure TContextIntfForServer.FreeDelayBuffPool;
var
  i: Integer;
begin
  for i := 0 to DelayBuffPool.Count - 1 do
      disposeObject(DelayBuffPool[i]);
  DelayBuffPool.Clear;
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
  Context.Close;
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
      // ����linux�µ�Send����copy������������������Ҫ�ӳ��ͷ��Լ��Ļ�����
      // �������״̬����ʱ�������ͷ�������ʱ������
      FreeDelayBuffPool;

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
                Context.SendBuf(m.Memory, m.Size, SendBuffResult);

                // ����linux�µ�Send����copy������������������Ҫ�ӳ��ͷ��Լ��Ļ�����
                DelayBuffPool.Add(m);

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

procedure TContextIntfForServer.SendByteBuffer(const buff: PByte; const Size: NativeInt);
begin
  if not Connected then
      exit;

  LastActiveTime := GetTimeTickCount;

  // �������������������ϵͳ��Դ��������Ҫ������Ƭ�ռ�
  // ��flush��ʵ�־�ȷ�첽���ͺ�У��
  if Size > 0 then
      CurrentBuff.Write(Pointer(buff)^, Size);
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

  // ��ubuntu 16.04 TLS�£������߳��ڳ�������ʱ�����ǵ��÷���api����ʱ��ȥ�����ݻ����
  // ���ǽ����Ƹ�Ϊ������,����Ƿ����ڽ����̹߳���:����˫����ʽ����
  if Sending or ReceiveProcessing then
    begin
      if CurrentBuff.Size > 0 then
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
      Context.SendBuf(CurrentBuff.Memory, CurrentBuff.Size, SendBuffResult);

      // ����linux�µ�Send����copy������������������Ҫ�ӳ��ͷ��Լ��Ļ�����
      DelayBuffPool.Add(CurrentBuff);
      CurrentBuff := TMemoryStream64.Create;
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

procedure TContextIntfForServer.Progress;
var
  m: TMemoryStream64;
begin
  inherited Progress;
  ProcessAllSendCmd(nil, False, False);

  // ��ubuntu 16.04 TLS�£������߳��ڳ�������ʱ�����ǵ��÷���api����ʱ��ȥ�����ݻ����
  // ���ǽ����Ƹ�Ϊ������,����Ƿ����ڽ����̹߳���:����˫����ʽ����
  if (not Sending) and (SendBuffQueue.Count > 0) then
    begin
      Sending := True;
      LastActiveTime := GetTimeTickCount;
      m := TMemoryStream64(SendBuffQueue[0]);
      // �ͷŶ���
      SendBuffQueue.Delete(0);

      // WSASend���·���ʱ���Ḵ��һ�ݸ������������ڴ濽������������Ϊ32k�����ڵײ���������ƬԤ�ü�
      // ע�⣺�¼�ʽ�ص����͵�buff����������ݶ�ջ��С����
      // ��лak47 qq512757165 �Ĳ��Ա���
      Context.SendBuf(m.Memory, m.Size, SendBuffResult);

      // ����linux�µ�Send����copy������������������Ҫ�ӳ��ͷ��Լ��Ļ�����
      DelayBuffPool.Add(m);
    end;
end;

procedure TCommunicationFramework_Server_CrossSocket.DoConnected(Sender: TObject; AConnection: ICrossConnection);
var
  cli: TContextIntfForServer;
begin
  cli := TContextIntfForServer.Create(Self, AConnection.ConnectionIntf);
  cli.LastActiveTime := GetTimeTickCount;
  AConnection.UserObject := cli;
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
var
  cli: TContextIntfForServer;
begin
  if ALen <= 0 then
      exit;

  if AConnection.UserObject = nil then
      exit;

  try
    cli := AConnection.UserObject as TContextIntfForServer;
    if cli.ClientIntf = nil then
        exit;

    cli.LastActiveTime := GetTimeTickCount;

    // zs�ں����°汾�Ѿ���ȫ֧����100%���첽��������
    // ��zs�ں˵��°汾�У�CrossSocket��100%���첽��ܣ������ǰ��첽������������
    // by 2018-1-29
    cli.SaveReceiveBuffer(ABuf, ALen);
    cli.FillRecvBuffer(TThread.CurrentThread, True, True);
  except
  end;
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

constructor TCommunicationFramework_Server_CrossSocket.Create(maxThPool: Word);
begin
  inherited Create;
  FDriver := TDriverEngine.Create(maxThPool);
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
          end;
      end;
  except
  end;

  inherited ProgressBackground;

  CheckSynchronize;
end;

function TCommunicationFramework_Server_CrossSocket.WaitSendConsoleCmd(Client: TPeerIO; const Cmd, ConsoleData: SystemString; TimeOut: TTimeTickValue): SystemString;
begin
  Result := '';
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

procedure TCommunicationFramework_Server_CrossSocket.WaitSendStreamCmd(Client: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; TimeOut: TTimeTickValue);
begin
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

initialization

finalization

end.
