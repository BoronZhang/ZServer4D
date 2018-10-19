program XLan;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  CoreClasses,
  PascalStrings,
  UnicodeMixedLib,
  CommunicationFramework,
  xNATClient,
  DoStatusIO;

var
  XCli: TXNATClient;

begin
  {
    TXNatClient�ܹ����������̣���ֻռ��������10%���µ�cpuʹ��
    �����ж��������������Ҫ��͸���������TXNATClient����
  }
  try
    XCli := TXNATClient.Create;
    XCli.RemoteTunnelAddr := '127.0.0.1'; // ������������IP
    XCli.RemoteTunnelPort := '7890';      // �����������Ķ˿ں�
    XCli.AuthToken := '123456';           // Э����֤�ַ���

    // 127.0.0.1��������������IP
    XCli.AddMapping('127.0.0.1', '80', 'web8000'); // ��������������8000�˿ڷ����������80�˿�

    XCli.OpenTunnel; // ����������͸

    while True do
      begin
        XCli.Progress;
        try
            CoreClasses.CheckThreadSynchronize(1);
        except
        end;
      end;
  except
    on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
  end;

end.
