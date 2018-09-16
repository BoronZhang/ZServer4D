program XInternet;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  System.SysUtils,
  CoreClasses,
  PascalStrings,
  UnicodeMixedLib,
  CommunicationFramework,
  xNATService,
  DoStatusIO;

var
  XServ: TXNATService;

begin
  try
    XServ := TXNATService.Create;
    XServ.TunnelListenAddr := '0.0.0.0';            // Э������󶨵�ַΪ����������ipv4�������ipv6��д'::'
    XServ.TunnelListenPort := '7890';               // Э��˿�
    XServ.AuthToken := '123456';                    // Э����֤�ַ���
    XServ.AddMapping('0.0.0.0', '8000', 'web8000'); // �ڷ���������Ҫӳ��Ķ˿�8000���󶨵�ַΪ����������ipv4
    XServ.OpenTunnel;

    while true do
        XServ.Progress;

  except
    on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
  end;

end.
