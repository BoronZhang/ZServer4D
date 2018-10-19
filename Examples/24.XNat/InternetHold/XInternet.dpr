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

    XServ.TunnelListenAddr := '0.0.0.0'; // ��������������ͨѶ������Э������󶨵�ַΪ����������ipv4�������ipv6��д'::'
    XServ.TunnelListenPort := '7890';    // ��������������ͨѶ������Э��˿�
    XServ.AuthToken := '123456';         // ��������������ͨѶ������Э����֤�ַ���(�ñ�ʶ��ʹ���˿���������ģ�ͣ���ؼ����������о�����)

    {
      ��������
    }
    XServ.AddMapping('0.0.0.0', '8000', 'web8000'); // �ڷ���������Ҫӳ��Ķ˿�8000���󶨵�ַΪ����������ipv4

    {
      ������������δ����,��ʱ����,δ����mapping "ftp8021"��8021�˿ڶ��Ƿ�����״̬��ֻ�е�����������ȫ����������,���8021�ŻῪʼ����
    }
    XServ.AddMapping('0.0.0.0', '8021', 'ftp8021'); // �ڷ���������Ҫӳ��Ķ˿�8021���󶨵�ַΪ����������ipv4
    XServ.OpenTunnel;

    while true do
      begin
        XServ.Progress;
        try
            CoreClasses.CheckThreadSynchronize;
        except
        end;
      end;

  except
    on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
  end;

end.
