unit DRCliFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  CommunicationFramework,
  DoStatusIO, CoreClasses,
  CommunicationFramework_Client_CrossSocket,
  CommunicationFramework_Client_ICS, CommunicationFramework_Client_Indy,
  Cadencer, DataFrameEngine;

type
  TDRClientForm = class(TForm)
    Memo1: TMemo;
    ConnectButton: TButton;
    HostEdit: TLabeledEdit;
    Timer1: TTimer;
    DelayResponseBtn: TButton;
    procedure ConnectButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure DelayResponseBtnClick(Sender: TObject);
  private
    { Private declarations }
    procedure DoStatusNear(AText: string; const ID: Integer);
  public
    { Public declarations }
    client: TCommunicationFramework_Client_CrossSocket;
  end;

var
  DRClientForm: TDRClientForm;

implementation

{$R *.dfm}


procedure TDRClientForm.DoStatusNear(AText: string; const ID: Integer);
begin
  Memo1.Lines.Add(AText);
end;

procedure TDRClientForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(self, DoStatusNear);
  client := TCommunicationFramework_Client_CrossSocket.Create;
end;

procedure TDRClientForm.FormDestroy(Sender: TObject);
begin
  DisposeObject(client);
  DeleteDoStatusHook(self);
end;

procedure TDRClientForm.DelayResponseBtnClick(Sender: TObject);
var
  SendDe: TDataFrameEngine;
begin
  // �첽��ʽ���ͣ����ҽ���Streamָ�������proc�ص�����
  SendDe := TDataFrameEngine.Create;
  client.SendStreamCmd('DelayResponse', SendDe,
    procedure(Sender: TPeerClient; ResultData: TDataFrameEngine)
    begin
      while ResultData.Reader.NotEnd do
          DoStatus('server response:%s', [ResultData.Reader.ReadString]);
    end);
  DisposeObject([SendDe]);
end;

procedure TDRClientForm.Timer1Timer(Sender: TObject);
begin
  client.Progress;
end;

procedure TDRClientForm.ConnectButtonClick(Sender: TObject);
begin
  if client.Connect(HostEdit.Text, 9818) then
      DoStatus('connect success');
end;

end.
