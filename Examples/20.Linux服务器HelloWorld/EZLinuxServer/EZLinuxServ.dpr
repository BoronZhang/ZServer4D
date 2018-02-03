program EZLinuxServ;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  System.Classes,
  CommunicationFramework,
  CommunicationFramework_Server_Indy,
  CommunicationFramework_Server_CrossSocket,
  DoStatusIO, CoreClasses,
  DataFrameEngine, UnicodeMixedLib, MemoryStream64;

(*
  Windows��һ������
  ����Delphiû��֧��linux->atomic��api��Indy��Linux��Ҫ��zDefine.inc->CriticalSimulateAtomic���û�����ģ��ԭ������ԭ���ڴ�����(�ܲ������ܻή��)

  Linux��CrossSocket�޷��������ݽ��գ��޷�ͨ��Debug������linux��gdb���Է����е�����

  �����汾������ʱ���ͻ�����linux�µĸ߲�������
*)

type
  // TPeerClientUserSpecial�ǻ���ÿ�û����Ӻ��Զ�������ʵ��
  // ʹ��ʱ����ע���ͷ��ڴ�
  // TPeerClientUserDefine����Auth,DB�ȵȷ���
  // TPeerClientUserSpecial����������߼������Auth,DB������ͻʱ���Կ������ṩ����ʵ��
  TMySpecialDefine = class(TPeerClientUserSpecial)
  public
    tempStream: TMemoryStream64;
    constructor Create(AOwner: TPeerClient); override;
    destructor Destroy; override;
  end;

  // ���ڿ���̨�Ĳ��Է�������ܣ����������ǿ�����indy
  // �������� �����ȶ�
  TMyServer = class(TCommunicationFramework_Server_Indy)
  private
    procedure cmd_helloWorld_Console(Sender: TPeerClient; InData: string);
    procedure cmd_helloWorld_Stream(Sender: TPeerClient; InData: TDataFrameEngine);
    procedure cmd_helloWorld_Stream_Result(Sender: TPeerClient; InData, OutData: TDataFrameEngine);

    procedure cmd_TestMiniStream(Sender: TPeerClient; InData: TDataFrameEngine);

    procedure cmd_Test128MBigStream(Sender: TPeerClient; InData: TCoreClassStream; BigStreamTotal, BigStreamCompleteSize: Int64);

    procedure cmd_TestCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
  public
  end;

constructor TMySpecialDefine.Create(AOwner: TPeerClient);
begin
  inherited Create(AOwner);
  tempStream := TMemoryStream64.Create;
  DoStatus('%s connected', [Owner.PeerIP]);
end;

destructor TMySpecialDefine.Destroy;
begin
  DoStatus('%s disconnect', [Owner.PeerIP]);
  DisposeObject(tempStream);
  inherited Destroy;
end;

procedure TMyServer.cmd_helloWorld_Console(Sender: TPeerClient; InData: string);
begin
  DoStatus('client: %s', [InData]);
end;

procedure TMyServer.cmd_helloWorld_Stream(Sender: TPeerClient; InData: TDataFrameEngine);
begin
  DoStatus('client: %s', [InData.Reader.ReadString]);
end;

procedure TMyServer.cmd_helloWorld_Stream_Result(Sender: TPeerClient; InData, OutData: TDataFrameEngine);
begin
  OutData.WriteString('result 654321');
end;

procedure TMyServer.cmd_TestMiniStream(Sender: TPeerClient; InData: TDataFrameEngine);
var
  ms: TMemoryStream;
begin
  ms := TMemoryStream.Create;
  InData.Reader.ReadStream(ms);

  DoStatus(umlMD5Char(ms.Memory, ms.Size).Text);

  DisposeObject(ms);
end;

procedure TMyServer.cmd_Test128MBigStream(Sender: TPeerClient; InData: TCoreClassStream; BigStreamTotal, BigStreamCompleteSize: Int64);
var
  tempStream: TMemoryStream64;
begin
  tempStream := TMySpecialDefine(Sender.UserSpecial).tempStream;
  tempStream.CopyFrom(InData, InData.Size);

  // bigstream complete
  if tempStream.Size = BigStreamTotal then
    begin
      Sender.Print('bigsteram finish');
      Sender.Print('bigsteram md5:' + umlMD5Char(tempStream.Memory, tempStream.Size).Text);
      tempStream.Clear;
    end;
end;

procedure TMyServer.cmd_TestCompleteBuffer(Sender: TPeerIO; InData: PByte; DataSize: NativeInt);
begin
  Sender.Print('Complete buffer md5: %s', [umlMD5String(InData, DataSize).Text]);
end;

// ��ѭ��
procedure MainLook;
var
  server: TMyServer;
begin
  server := TMyServer.Create;
  server.PeerClientUserSpecialClass := TMySpecialDefine;

  // �������completeBuffer������ֻ���ڲ��ԣ��������з�����������һ���4M�Ϳ�����
  server.MaxCompleteBufferSize := 128 * 1024 * 1024;

  server.RegisterDirectConsole('helloWorld_Console').OnExecute := server.cmd_helloWorld_Console;
  server.RegisterDirectStream('helloWorld_Stream').OnExecute := server.cmd_helloWorld_Stream;
  server.RegisterStream('helloWorld_Stream_Result').OnExecute := server.cmd_helloWorld_Stream_Result;
  server.RegisterDirectStream('TestMiniStream').OnExecute := server.cmd_TestMiniStream;
  server.RegisterBigStream('Test128MBigStream').OnExecute := server.cmd_Test128MBigStream;
  // ע��Completebufferָ��
  server.RegisterCompleteBuffer('TestCompleteBuffer').OnExecute := server.cmd_TestCompleteBuffer;

  // ����CrosssSocket�ٷ��ĵ������ַ������Ϊ�գ���IPV6+IPV4
  if server.StartService('', 9818) then
      DoStatus('start service success')
  else
      DoStatus('start service failed!');

  // ������ѭ��
  while true do
      server.ProgressBackground;
end;

begin
  MainLook;

end.
