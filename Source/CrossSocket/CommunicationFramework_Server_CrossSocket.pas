{ ****************************************************************************** }
{ * CrossSocket support                                                        * }
{ * written by QQ 600585@qq.com                                                * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ ****************************************************************************** }
(*
  update history
*)
unit CommunicationFramework_Server_CrossSocket;

{$INCLUDE ..\zDefine.inc}

interface

uses SysUtils, Classes,
  NET.CrossSocket, NET.SocketAPI, NET.CrossSocket.Base, NET.CrossServer,
  PascalStrings, DoStatusIO,
  CommunicationFramework, CoreClasses, UnicodeMixedLib, MemoryStream64,
  DataFrameEngine;

type
  TPeerIOWithCrossSocketServer = class(TPeerIO)
  public
    LastPeerIP: SystemString;
    LastActiveTime: TTimeTickValue;
    Sending: Boolean;
    SendBuffQueue: TCoreClassListForObj;
    CurrentBuff: TMemoryStream64;
    DelayBuffPool: TCoreClassListForObj;

    procedure CreateAfter; override;
    destructor Destroy; override;

    procedure FreeDelayBuffPool;
    function Context: TCrossConnection;
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

  // ��ΪcrossSocket�ڵײ���ⲿ֧�ֵĽӿ��е��٣���ĽӿڱȽ��鷳����ʱ����һ�£�����ʱ�����������
  TDriverEngine = TCrossSocket;

  TCommunicationFramework_Server_CrossSocket = class(TCommunicationFrameworkServer)
  private
    FDriver: TDriverEngine;
    FStartedService: Boolean;
    FBindHost: SystemString;
    FBindPort: Word;
  protected
    procedure DoConnected(Sender: TObject; AConnection: ICrossConnection);
    procedure DoDisconnect(Sender: TObject; AConnection: ICrossConnection);
    procedure DoReceived(Sender: TObject; AConnection: ICrossConnection; aBuf: Pointer; ALen: Integer);
    procedure DoSent(Sender: TObject; AConnection: ICrossConnection; aBuf: Pointer; ALen: Integer);
  public
    constructor Create; override;
    constructor CreateTh(maxThPool: Word);
    destructor Destroy; override;

    function StartService(Host: SystemString; Port: Word): Boolean; override;
    procedure StopService; override;

    procedure TriggerQueueData(v: PQueueData); override;
    procedure Progress; override;

    function WaitSendConsoleCmd(Client: TPeerIO; const Cmd, ConsoleData: SystemString; Timeout: TTimeTickValue): SystemString; override;
    procedure WaitSendStreamCmd(Client: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; Timeout: TTimeTickValue); override;

    property StartedService: Boolean read FStartedService;
    property driver: TDriverEngine read FDriver;
    property BindPort: Word read FBindPort;
    property BindHost: SystemString read FBindHost;
  end;

implementation

procedure TPeerIOWithCrossSocketServer.CreateAfter;
begin
  inherited CreateAfter;
  LastPeerIP := '';
  LastActiveTime := GetTimeTickCount;
  Sending := False;
  SendBuffQueue := TCoreClassListForObj.Create;
  CurrentBuff := TMemoryStream64.Create;
  DelayBuffPool := TCoreClassListForObj.Create;
end;

destructor TPeerIOWithCrossSocketServer.Destroy;
var
  i: Integer;
begin
  FreeDelayBuffPool;

  for i := 0 to SendBuffQueue.Count - 1 do
      DisposeObject(SendBuffQueue[i]);

  DisposeObject(SendBuffQueue);

  DisposeObject(CurrentBuff);
  DisposeObject(DelayBuffPool);
  inherited Destroy;
end;

procedure TPeerIOWithCrossSocketServer.FreeDelayBuffPool;
var
  i: Integer;
begin
  for i := 0 to DelayBuffPool.Count - 1 do
      DisposeObject(DelayBuffPool[i]);
  DelayBuffPool.Clear;
end;

function TPeerIOWithCrossSocketServer.Context: TCrossConnection;
begin
  Result := ClientIntf as TCrossConnection;
end;

function TPeerIOWithCrossSocketServer.Connected: Boolean;
begin
  Result := (ClientIntf <> nil) and
    (Context.ConnectStatus = TConnectStatus.csConnected);
end;

procedure TPeerIOWithCrossSocketServer.Disconnect;
begin
  if ClientIntf <> nil then
    begin
      try
          Context.Disconnect;
      except
      end;
    end;
end;

procedure TPeerIOWithCrossSocketServer.SendBuffResult(AConnection: ICrossConnection; ASuccess: Boolean);
begin
  LastActiveTime := GetTimeTickCount;

  // Ϊ����ʹ�÷�ҳ�潻���ڴ棬��io�ں˷��ͽ���ͬ�������߳�����
  TThread.Synchronize(nil,
    procedure
    var
      i: Integer;
      M: TMemoryStream64;
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
                M := TMemoryStream64(SendBuffQueue[0]);

                // WSASend���·���ʱ���Ḵ��һ�ݸ������������ڴ濽������������Ϊ32k�����ڵײ���������ƬԤ�ü�
                // ע�⣺�¼�ʽ�ص����͵�buff����������ݶ�ջ��С����
                // ��лak47 qq512757165 �Ĳ��Ա���
                Context.SendBuf(M.Memory, M.Size, SendBuffResult);

                // ����linux�µ�Send����copy������������������Ҫ�ӳ��ͷ��Լ��Ļ�����
                DelayBuffPool.Add(M);

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
                DisposeObject(SendBuffQueue[i]);
            SendBuffQueue.Clear;

            Sending := False;

            if isConn then
              begin
                Print('send failed!');
                Disconnect;
              end;
          end;
      except
        Print('send failed!');
        Disconnect;
      end;
    end);
end;

procedure TPeerIOWithCrossSocketServer.SendByteBuffer(const buff: PByte; const Size: NativeInt);
begin
  if not Connected then
      Exit;

  LastActiveTime := GetTimeTickCount;

  // �������������������ϵͳ��Դ��������Ҫ������Ƭ�ռ�
  // ��flush��ʵ�־�ȷ�첽���ͺ�У��
  if Size > 0 then
      CurrentBuff.write(Pointer(buff)^, Size);
end;

procedure TPeerIOWithCrossSocketServer.WriteBufferOpen;
begin
  if not Connected then
      Exit;
  LastActiveTime := GetTimeTickCount;
  CurrentBuff.Clear;
end;

procedure TPeerIOWithCrossSocketServer.WriteBufferFlush;
var
  ms: TMemoryStream64;
begin
  if not Connected then
      Exit;
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

procedure TPeerIOWithCrossSocketServer.WriteBufferClose;
begin
  if not Connected then
      Exit;
  CurrentBuff.Clear;
end;

function TPeerIOWithCrossSocketServer.GetPeerIP: SystemString;
begin
  if Connected then
    begin
      Result := Context.PeerAddr;
      LastPeerIP := Result;
    end
  else
      Result := LastPeerIP;
end;

function TPeerIOWithCrossSocketServer.WriteBufferEmpty: Boolean;
begin
  Result := not Sending;
end;

procedure TPeerIOWithCrossSocketServer.Progress;
var
  M: TMemoryStream64;
begin
  // ������
  if (OwnerFramework.IdleTimeout > 0) and (GetTimeTickCount - LastActiveTime > OwnerFramework.IdleTimeout) then
    begin
      Disconnect;
      Exit;
    end;

  inherited Progress;

  ProcessAllSendCmd(nil, False, False);

  // ��ubuntu 16.04 TLS�£������߳��ڳ�������ʱ�����ǵ��÷���api����ʱ��ȥ�����ݻ����
  // ���ǽ����Ƹ�Ϊ������,����Ƿ����ڽ����̹߳���:����˫����ʽ����
  if (not Sending) and (SendBuffQueue.Count > 0) then
    begin
      Sending := True;
      LastActiveTime := GetTimeTickCount;
      M := TMemoryStream64(SendBuffQueue[0]);
      // �ͷŶ���
      SendBuffQueue.Delete(0);

      // WSASend���·���ʱ���Ḵ��һ�ݸ������������ڴ濽������������Ϊ32k�����ڵײ���������ƬԤ�ü�
      // ע�⣺�¼�ʽ�ص����͵�buff����������ݶ�ջ��С����
      { Thank you for the test report of AK47 qq512757165 }
      Context.SendBuf(M.Memory, M.Size, SendBuffResult);

      // ����linux�µ�Send����copy������������������Ҫ�ӳ��ͷ��Լ��Ļ�����
      DelayBuffPool.Add(M);
    end;
end;

procedure TCommunicationFramework_Server_CrossSocket.DoConnected(Sender: TObject; AConnection: ICrossConnection);
var
  cli: TPeerIOWithCrossSocketServer;
begin
  cli := TPeerIOWithCrossSocketServer.Create(Self, AConnection.ConnectionIntf);
  cli.LastActiveTime := GetTimeTickCount;
  AConnection.UserObject := cli;
end;

procedure TCommunicationFramework_Server_CrossSocket.DoDisconnect(Sender: TObject; AConnection: ICrossConnection);
begin
  if AConnection.UserObject is TPeerIOWithCrossSocketServer then
      TThread.Synchronize(TThread.CurrentThread,
      procedure
      var
        cli: TPeerIOWithCrossSocketServer;
      begin
        cli := TPeerIOWithCrossSocketServer(AConnection.UserObject);
        try
          cli.ClientIntf := nil;
          AConnection.UserObject := nil;
          DisposeObject(cli);
        except
        end;
      end);
end;

procedure TCommunicationFramework_Server_CrossSocket.DoReceived(Sender: TObject; AConnection: ICrossConnection; aBuf: Pointer; ALen: Integer);
var
  cli: TPeerIOWithCrossSocketServer;
begin
  if ALen <= 0 then
      Exit;

  if AConnection.UserObject = nil then
      Exit;

  try
    cli := AConnection.UserObject as TPeerIOWithCrossSocketServer;
    if cli.ClientIntf = nil then
        Exit;

    cli.LastActiveTime := GetTimeTickCount;

    // zs�ں����°汾�Ѿ���ȫ֧����100%���첽��������
    // ��zs�ں˵��°汾�У�CrossSocket��100%���첽��ܣ������ǰ��첽������������
    // by 2018-1-29
    cli.SaveReceiveBuffer(aBuf, ALen);
    cli.FillRecvBuffer(TThread.CurrentThread, True, True);
  except
  end;
end;

procedure TCommunicationFramework_Server_CrossSocket.DoSent(Sender: TObject; AConnection: ICrossConnection; aBuf: Pointer; ALen: Integer);
var
  cli: TPeerIOWithCrossSocketServer;
begin
  if AConnection.UserObject = nil then
      Exit;

  cli := AConnection.UserObject as TPeerIOWithCrossSocketServer;
  if cli.ClientIntf = nil then
      Exit;
  cli.LastActiveTime := GetTimeTickCount;
end;

constructor TCommunicationFramework_Server_CrossSocket.Create;
begin
  CreateTh(4);
end;

constructor TCommunicationFramework_Server_CrossSocket.CreateTh(maxThPool: Word);
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
      DisposeObject(FDriver);
  except
  end;
  inherited Destroy;
end;

function TCommunicationFramework_Server_CrossSocket.StartService(Host: SystemString; Port: Word): Boolean;
var
  Completed, Successed: Boolean;
begin
  StopService;

  Completed := False;
  Successed := False;
  try
    ICrossSocket(FDriver).Listen(Host, Port,
      procedure(Listen: ICrossListen; ASuccess: Boolean)
      begin
        Completed := True;
        Successed := ASuccess;
      end);

    while not Completed do
        CheckThreadSynchronize(5);

    FBindPort := Port;
    FBindHost := Host;
    Result := Successed;
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
var
  c: TPeerIO;
begin
  (*
    TThread.Synchronize(nil,
    procedure
    begin
    end);
  *)
  c := ClientFromID[v^.ClientID];
  if c <> nil then
    begin
      c.PostQueueData(v);
      c.ProcessAllSendCmd(nil, False, False);
    end
  else
      DisposeQueueData(v);
end;

procedure TCommunicationFramework_Server_CrossSocket.Progress;
begin
  inherited Progress;
end;

function TCommunicationFramework_Server_CrossSocket.WaitSendConsoleCmd(Client: TPeerIO; const Cmd, ConsoleData: SystemString; Timeout: TTimeTickValue): SystemString;
begin
  Result := '';
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

procedure TCommunicationFramework_Server_CrossSocket.WaitSendStreamCmd(Client: TPeerIO; const Cmd: SystemString; StreamData, ResultData: TDataFrameEngine; Timeout: TTimeTickValue);
begin
  RaiseInfo('WaitSend no Suppport CrossSocket');
end;

initialization

finalization

end.
