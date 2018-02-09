{ * �ⲿapi֧�֣��ٶȷ������Ŀͻ��˽ӿ���ʾ                                  * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ ****************************************************************************** }
unit ZSClientFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  CoreClasses,
  PascalStrings, DoStatusIO, DataFrameEngine, NotifyObjectBase,
  CommunicationFramework,
  CommunicationFramework_Client_Indy;

type
  TZSClientForm = class(TForm)
    HostEdit: TLabeledEdit;
    SourMemo: TMemo;
    Label1: TLabel;
    DestMemo: TMemo;
    Label2: TLabel;
    SourComboBox: TComboBox;
    DestComboBox: TComboBox;
    TransButton: TButton;
    LogMemo: TMemo;
    ProgressTimer: TTimer;
    procedure TransButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ProgressTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    cli: TCommunicationFramework_Client_Indy;
    procedure DoStatusMethod(AText: SystemString; const ID: Integer);
  end;

var
  ZSClientForm: TZSClientForm;

implementation

{$R *.dfm}


procedure HookProgressBackgroundProc;
begin
  Application.ProcessMessages;
end;

procedure TZSClientForm.DoStatusMethod(AText: SystemString; const ID: Integer);
begin
  LogMemo.Lines.Add(AText);
end;

procedure TZSClientForm.FormCreate(Sender: TObject);
begin
  AddDoStatusHook(Self, DoStatusMethod);
  cli := TCommunicationFramework_Client_Indy.Create;
  ProgressBackgroundProc := HookProgressBackgroundProc;
end;

procedure TZSClientForm.ProgressTimerTimer(Sender: TObject);
begin
  cli.ProgressBackground;
end;

procedure TZSClientForm.TransButtonClick(Sender: TObject);
begin
  cli.AsyncConnect(HostEdit.Text, 59813,
    procedure(const cState: Boolean)
    var
      de: TDataFrameEngine;
    begin
      if cState then
        begin
          de := TDataFrameEngine.Create;
          de.WriteByte(SourComboBox.ItemIndex);
          de.WriteByte(DestComboBox.ItemIndex);
          de.WriteString(SourMemo.Text);
          cli.SendStreamCmd('BaiduTranslate', de, procedure(Sender: TPeerIO; ResultData: TDataFrameEngine)
            begin
              if ResultData.Reader.ReadBool then
                  DestMemo.Text := ResultData.Reader.ReadString
              else
                  DestMemo.Text := '!�������!';

              // ������ɺ�Ͽ�����
              // ����ʹ���ӳ��¼����津����0���ʾ�ڸ��¼����������һ����ѭ����Ͽ�
              // ��Ϊ���������Զ���5�����ߣ����ҷ��������߻��и�Ӱ����������ǿ����յ����ߣ�������������飬�������ǿ��Բ���������ֱ�Ӷ���
              (*
                cli.ProgressPost.PostExecute(0,
                procedure(Sender: TNPostExecute)
                begin
                cli.Disconnect;
                end);
              *)
            end);
          DisposeObject(de);
        end;
    end);
end;

end.
