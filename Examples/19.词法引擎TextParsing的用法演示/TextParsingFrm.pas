unit TextParsingFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  PascalStrings, TextParsing, CoreClasses, UnicodeMixedLib, zExpression, opCode, MemoryStream64,
  TypInfo,
  Vcl.ComCtrls, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Memo1: TMemo;
    Button1: TButton;
    Memo2: TMemo;
    Button2: TButton;
    TabSheet2: TTabSheet;
    Memo3: TMemo;
    Button3: TButton;
    Memo4: TMemo;
    TabSheet3: TTabSheet;
    Memo5: TMemo;
    Panel1: TPanel;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}


procedure TForm1.Button1Click(Sender: TObject);
var
  t : TTextParsing;
  i : Integer;
  pt: PTokenData;
begin
  t := TTextParsing.Create(Memo1.Text, TTextStyle.tsPascal);

  Memo2.Clear;

  for i := 0 to t.ParsingData.Cache.TokenDataList.Count - 1 do
    begin
      pt := t.ParsingData.Cache.TokenDataList[i];
      if pt^.tokenType <> TTokenType.ttUnknow then
          Memo2.Lines.Add(Format('���� %d ����:%s ֵ %s', [i, GetEnumName(TypeInfo(TTokenType), Ord(pt^.tokenType)), pt^.Text.Text]));
    end;

  DisposeObject(t);
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  t : TTextParsing;
  i : Integer;
  pt: PTokenData;
begin
  t := TTextParsing.Create(Memo1.Text, TTextStyle.tsC);

  Memo2.Clear;

  for i := 0 to t.ParsingData.Cache.TokenDataList.Count - 1 do
    begin
      pt := t.ParsingData.Cache.TokenDataList[i];
      if pt^.tokenType <> TTokenType.ttUnknow then
          Memo2.Lines.Add(Format('���� %d ����:%s ֵ %s', [i, GetEnumName(TypeInfo(TTokenType), Ord(pt^.tokenType)), pt^.Text.Text]));
    end;

  DisposeObject(t);
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  t : TTextParsing;
  i : Integer;
  pt: PTokenData;

  PrepareProc: Boolean;
begin
  t := TTextParsing.Create(Memo3.Text, TTextStyle.tsPascal);

  Memo2.Clear;
  PrepareProc := False;

  for i := 0 to t.ParsingData.Cache.TokenDataList.Count - 1 do
    begin
      pt := t.ParsingData.Cache.TokenDataList[i];

      if PrepareProc then
        begin
          if (pt^.tokenType = TTokenType.ttSymbol) then
              PrepareProc := False
          else if (pt^.tokenType = TTokenType.ttAscii) then
              Memo4.Lines.Add(Format('���� %d ����:%s ֵ %s', [i, GetEnumName(TypeInfo(TTokenType), Ord(pt^.tokenType)), pt^.Text.Text]));
        end
      else
          PrepareProc := (pt^.tokenType = TTokenType.ttAscii) and (pt^.Text.Same('function') or pt^.Text.Same('procedure'));
    end;

  DisposeObject(t);
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  rt: TOpCustomRunTime;
  v : Variant;
begin
  Memo5.Lines.Add('����ʹ��demo');
  // rtΪze�����к���֧�ֿ�
  rt := TOpCustomRunTime.Create;
  rt.RegOp('myAddFunction', function(var Param: TOpParam): Variant
    // (a+b)*0.5
    begin
      Result := (Param[0] + Param[1]) * 0.5;
    end);
  rt.RegOp('myStringFunction', function(var Param: TOpParam): Variant
    begin
      Result := Format('�ַ�������Ϊ:%d', [Length(VarToStr(Param[0]) + VarToStr(Param[1]))]);
    end);

  // ����ѧ���ʽ
  v := EvaluateExpressionValue(False, '1000+{ �����Ǳ�ע ze����ʶ��pascal��c�ı�ע�Լ��ַ���д�� } myAddFunction(1+1/2*3/3.14*9999, 599+2+2*100 shl 3)', rt);
  Memo5.Lines.Add(VarToStr(v));

  // ���ַ������ʽ��ze��Ĭ���ı������ʽΪPascal
  v := EvaluateExpressionValue(False, 'myStringFunction('#39'abc'#39', '#39'123'#39')', rt);
  Memo5.Lines.Add(VarToStr(v));

  // ���ַ������ʽ������ʹ��c���ı���ʽ
  v := EvaluateExpressionValue(tsC, 'myStringFunction("abc", "123")', rt);
  Memo5.Lines.Add(VarToStr(v));

  DisposeObject(rt);
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  tmpSym: TSymbolExpression;
  op    : TOpCode;
  rt    : TOpCustomRunTime;
  m64   : TMemoryStream64;
begin
  Memo5.Lines.Add('����������ִ��demo');
  // rtΪze�����к���֧�ֿ�
  rt := TOpCustomRunTime.Create;
  rt.RegOp('myAddFunction', function(var Param: TOpParam): Variant
    // (a+b)*0.5
    begin
      Result := (Param[0] + Param[1]) * 0.5;
    end);
  rt.RegOp('myStringFunction', function(var Param: TOpParam): Variant
    begin
      Result := Format('�ַ�������Ϊ:%d', [Length(VarToStr(Param[0]) + VarToStr(Param[1]))]);
    end);

  // ʹ��ParseTextExpressionAsSymbol�����������ʽ����ɴʷ���
  tmpSym := ParseTextExpressionAsSymbol(TTextParsing, '', '1000+myAddFunction(1+1/2*3/3.14*9999, 599+2+2*100 shl 3)', nil, rt);
  // BuildAsOpCode�Ὣ�ʷ����ٴη�����﷨����Ȼ���ٻ����﷨������op����
  op := BuildAsOpCode(tmpSym);
  DisposeObject(tmpSym);
  // ����ִ��һ��op
  Memo5.Lines.Add(Format('op���з���ֵ(��ȷֵΪ4489.2962): %s', [VarToStr(op.Execute(rt))]));

  m64 := TMemoryStream64.Create;
  op.SaveToStream(m64);

  // �����Ѿ��ͷ���op
  DisposeObject(op);

  // ��stream���ٶ�ȡop�������������
  m64.Position := 0;
  if LoadOpFromStream(True, m64, op) then
    begin
      Memo5.Lines.Add(Format('op���з���ֵ(��ȷֵΪ4489.2962): %s', [VarToStr(op.Execute(rt))]));
    end;

  DisposeObject([op, rt, m64]);

  Memo5.Lines.Add('����������ִ��demo���������');
end;

procedure TForm1.Button6Click(Sender: TObject);
type
  TState = (sUnknow, sIF, sTrue, sFalse); // �����õļ�״̬��
label gFillStruct;
var
  t                                      : TTextParsing;     // �ʷ���������
  cp, ep                                 : Integer;          // ������
  wasNumber, wasText, wasAscii, wasSymbol: Boolean;          // �����ı�״̬��
  state                                  : TState;           // �����ṹ״̬��
  decl                                   : TPascalString;    // ��ǰ�����ʷ��壬����
  ifMatchBody                            : TPascalString;    // ���������ж�������
  ifTrueBody                             : TPascalString;    // ��������������
  ifFalseBody                            : TPascalString;    // ����������������
  rt                                     : TOpCustomRunTime; // ���к�����֧��
begin
  // ����pascal���ַ�����������д�ڳ����У���������c����ַ���
  t := TTextParsing.Create('if 1+1=/* comment */2 then writeln/* comment */("if was true") else writeln/* comment */("if was false");', tsC);
  cp := 1;
  ep := 1;
  state := sUnknow;
  ifMatchBody := '';
  ifTrueBody := '';
  ifFalseBody := '';

  // ������ѭ��
  while cp < t.Len do
    begin
      // ����Ǵ��뱸ע������ȥ
      if t.IsComment(cp) then
        begin
          ep := t.GetCommentEndPos(cp);
          cp := ep;
          continue;
        end;

      // �ʷ����̷�ʽ�����״˷�ʽ���Գ���ʷ�����Ϊ����û�п������ܣ������Ҫ�������нű����뿼�Ǳ�������ݽṹ�洢���Ը��ٷ�ʽ��������
      wasNumber := t.IsNumber(cp);
      wasText := t.IsTextDecl(cp);
      wasAscii := t.IsAscii(cp);
      wasSymbol := t.IsSymbol(cp);

      if wasNumber then
        begin
          ep := t.GetNumberEndPos(cp);
          decl := t.GetStr(cp, ep);
          cp := ep;
          goto gFillStruct;
        end;

      if wasText then
        begin
          ep := t.GetTextDeclEndPos(cp);
          decl := t.GetStr(cp, ep);
          cp := ep;
          goto gFillStruct;
        end;

      if wasAscii then
        begin
          ep := t.GetAsciiEndPos(cp);
          decl := t.GetStr(cp, ep);
          cp := ep;
          goto gFillStruct;
        end;

      if wasSymbol then
        begin
          decl := t.ParsingData.Text[cp];
          inc(cp);
          ep := cp;
          goto gFillStruct;
        end;

      inc(cp);
      continue;
      // �ʷ����̷�ʽ�����������������ṹ���ж�

    gFillStruct:

      if wasAscii then
        begin
          // �ʷ��ṹ
          if decl.Same('if') then
            begin
              if state <> sUnknow then
                begin
                  Memo5.Lines.Add('if ��ʽ��������');
                  break;
                end;
              state := sIF;
              continue;
            end;

          if decl.Same('then') then
            begin
              if state <> sIF then
                begin
                  Memo5.Lines.Add('then ��ʽ��������');
                  break;
                end;
              state := sTrue;
              continue;
            end;

          if decl.Same('else') then
            begin
              if state <> sTrue then
                begin
                  Memo5.Lines.Add('else ��д��ʽ��������');
                  break;
                end;
              state := sFalse;
              continue;
            end;
        end;

      case state of
        sIF: ifMatchBody.Append(decl);    // ��TPascalString�У�ʹ��Append������Ҫ��string:=string+stringЧ�ʸ���
        sTrue: ifTrueBody.Append(decl);   // ��TPascalString�У�ʹ��Append������Ҫ��string:=string+stringЧ�ʸ���
        sFalse: ifFalseBody.Append(decl); // ��TPascalString�У�ʹ��Append������Ҫ��string:=string+stringЧ�ʸ���
      end;
    end;

  // ����һ��������if�ṹ����Ѿ������ɹ��ˣ�����ֱ�����г��򼴿�
  if state = sFalse then
    begin
      rt := TOpCustomRunTime.Create;
      rt.RegOp('writeln', function(var Param: TOpParam): Variant
        begin
          Memo5.Lines.Add(VarToStr(Param[0]));
          Result := 0;
        end);
      // �����Ҫ���ܣ�����Ľṹ������Կ��������ݽṹ���洢��ʵ�ֿ��ٽű�
      // opCache.Clear;
      if EvaluateExpressionValue(tsC, ifMatchBody, rt) = True then
          EvaluateExpressionValue(tsC, ifTrueBody, rt)
      else
          EvaluateExpressionValue(tsC, ifFalseBody, rt);
      DisposeObject(rt);
    end;

  DisposeObject(t);
end;

procedure TForm1.Button7Click(Sender: TObject);

  function Macro(var AText: string; const HeadToken, TailToken: string; const rt: TOpCustomRunTime): TPascalString; inline;
  var
    sour      : TPascalString;
    ht, tt    : TPascalString;
    bPos, ePos: Integer;
    KeyText   : SystemString;
    i         : Integer;
    tmpSym    : TSymbolExpression;
    op        : TOpCode;
  begin
    Result := '';
    sour.Text := AText;
    ht.Text := HeadToken;
    tt.Text := TailToken;

    i := 1;

    while i <= sour.Len do
      begin
        if sour.ComparePos(i, @ht) then
          begin
            bPos := i;
            ePos := sour.GetPos(@tt, i + ht.Len);
            if ePos > 0 then
              begin
                KeyText := sour.copy(bPos + ht.Len, ePos - (bPos + ht.Len)).Text;

                // ��TPascalString�У�ʹ��Append������Ҫ��string:=string+stringЧ�ʸ���
                Result.Append(VarToStr(EvaluateExpressionValue(KeyText, rt)));
                i := ePos + tt.Len;
                continue;
              end;
          end;

        // ��TPascalString�У�ʹ��Append������Ҫ��string:=string+stringЧ�ʸ���
        Result.Append(sour[i]);
        inc(i);
      end;
  end;

var
  n : string;
  i : Integer;
  t : TTimeTick;
  rt: TOpCustomRunTime;
begin
  Memo5.Lines.Add('����ʾ�ýű�����װzExpression');
  // rtΪze�����к���֧�ֿ�
  rt := TOpCustomRunTime.Create;
  rt.RegOp('OverFunction', function(var Param: TOpParam): Variant
    begin
      Result := 'лл';
    end);

  // ��������ʹ�ú괦��1+1�Ա��ʽ������
  n := '����1+1=<begin>1+1<end>������һ��UInt48λ����:<begin>1<<48<end>������ <begin>OverFunction<end>';

  Memo5.Lines.Add('ԭ��:' + n);
  Memo5.Lines.Add('������' + Macro(n, '<begin>', '<end>', rt).Text);

  Memo5.Lines.Add('zExpression���ڲ������ܣ�������ԭ����10��δ���');

  t := GetTimeTick;

  // �ظ���1��ξ䷨���ʽ�����ʹ���
  for i := 1 to 10 * 10000 do
      Macro(n, '<begin>', '<end>', rt);

  Memo5.Lines.Add(Format('zExpression���ܲ�����ɣ���ʱ:%dms', [GetTimeTick - t]));

  DisposeObject([rt]);
end;

end.
