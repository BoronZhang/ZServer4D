program LargeScale_ZDB_DataBuild;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  SysUtils,
  Classes,
  CoreClasses,
  PascalStrings,
  UnicodeMixedLib,
  DoStatusIO,
  MemoryStream64,
  ListEngine,
  ZDBEngine,
  ZDBLocalManager;

function DestDBPath: SystemString;
begin
  Result := 'x:\';
end;

// ģ�⹹��.CSV��ʽ�ļ�
procedure BuildRandCSVData;
const
  c_MaxFileSize = Int64(128) * Int64(1024 * 1024); // ��Ҫ������csv�ļ��ߴ�
var
  ioHnd: TIOHnd;
  i: Integer;
  n: U_String;
  c: Int64;
  buff: TBytes;
begin
  DoStatus('��ʼ�������ģcsv');
  InitIOHnd(ioHnd);
  umlFileCreate(umlCombineFileName(DestDBPath, 'big.csv'), ioHnd);

  // prepare csv header
  n := '';
  for i := 0 to 5 do
      n.Append('%d,', [i]);
  n.DeleteLast;
  n.Append(#13#10);
  buff := n.PlatformBytes;
  umlBlockWrite(ioHnd, buff[0], length(buff));
  SetLength(buff, 0);
  n := '';

  // build csv body
  c := 0;
  while (ioHnd.Size < c_MaxFileSize) do
    begin
      n := '';
      for i := 0 to 5 do
          n.Append(TPascalString.RandomString(umlRandomRange(5, 20)) + ',');
      n.DeleteLast;
      n.Append(#13#10);
      buff := n.PlatformBytes;
      umlBlockWrite(ioHnd, buff[0], length(buff));
      SetLength(buff, 0);
      n := '';
      inc(c);

      if c mod 100000 = 0 then
          DoStatus('.CSV ������.. �Ѿ���� %s Ŀ�� %s', [umlSizeToStr(ioHnd.Size).Text, umlSizeToStr(c_MaxFileSize).Text]);
    end;

  umlFileClose(ioHnd);
end;

procedure BuildZDB;
var
  LM: TZDBLocalManager;
  db: TZDBStoreEngine;
  r: TStreamReader;
begin
  DoStatus('��ʼ�������ģZDB');
  LM := TZDBLocalManager.Create;
  LM.RootPath := DestDBPath;

  r := TStreamReader.Create(umlCombineFileName(DestDBPath, 'big.csv').Text, TEncoding.UTF8);
  db := LM.InitNewDB('big');

  CustomImportCSV_P(
    procedure(var L: TPascalString; var IsEnd: Boolean)
    begin
      IsEnd := r.EndOfStream;
      if not IsEnd then
          L := r.ReadLine;
    end,
    procedure(const sour: TPascalString; const king, Data: TArrayPascalString)
    var
      i: Integer;
      VT: THashStringList;
    begin
      VT := THashStringList.CustomCreate(16);
      for i := Low(king) to High(king) do
          VT[king[i]] := Data[i];
      db.AddData(VT);
      DisposeObject(VT);

      // ÿ����10000����¼���������ݵ�����Ӳ��
      if db.Count mod 10000 = 0 then
        begin
          DoStatus('����� %d ������, ���ݿ�ߴ� %s �ں�״̬ %s %s',
            [db.Count, umlSizeToStr(db.DBEngine.Size).Text,
            db.CacheAnnealingState, db.DBEngine.CacheStatus]);
        end;

      // �����ݵ�����Ҫ����cache̫��
      if db.Count mod 100000 = 0 then
        begin
          db.DBEngine.CleaupCache;
        end;
    end);

  DisposeObject(r);
  DisposeObject(LM);
end;

procedure QueryZDB;
var
  LM: TZDBLocalManager;
  db: TZDBStoreEngine;
  LVT: TDBListVT;
  i, j: Integer;
  tk: TTimeTick;
begin
  DoStatus('��ѯģ��');
  LM := TZDBLocalManager.Create;
  LM.RootPath := DestDBPath;
  db := LM.InitDB('big');

  // ����������������Ҫ�Ӵ��ں˵�hash��������
  db.DBEngine.SetPoolCache(100 * 10000);

  // �����ڴ淽ʽ��ѯ
  if False then
    begin
      DoStatus('���������ڴ�', []);
      LVT := TDBListVT.Create;
      // ȫ�������ڴ��ʱ���ܳ�
      LVT.LoadFromStoreEngine(db);
      // ������ɺ󣬲�ѯ��ǳ���
      tk := GetTimeTick;
      for j := 0 to 99 do
        for i := 0 to LVT.Count - 1 do
          begin
            CompareText(LVT[i]['1'], 'abc');
          end;
      DoStatus('�ڴ淽ʽƽ����ѯ��ʱ%dms', [(GetTimeTick - tk) div 100]);
      DisposeObject(LVT);
    end;

  // ������ʽ��ѯ
  // ���˻�����İ����£��������ѯ��ȵ��������

  // ģ��3��ͬʱ��ѯ������
  for i := 0 to 3 - 1 do
    begin
      LM.QueryDBP(False,          // ����ѯ���д�뵽һ����ʱ���ݿ�
      True,                       // ��ʱ���ݿ����ڴ�ģʽ
      Odd(MT19937Rand32(MaxInt)), // ������������ѯ
      db.Name,                    // Ŀ�����ݿ�
      '',                         // ��ʱ���ݿ����֣�������ָ��վ����������
      True,                       // ��ѯ����������ݿ���Զ����ͷ�
      0.0,                        // �ͷ���ʱ���ݿ���ӳ�ʱ��
      0,                          // ��Ƭ���ݷ���ʱ��
      0,                          // umlRandomRangeD(10, 60),    // ���Ʋ�ѯʱ�䣬���xx-xx��
      0,                          // ��������ѯ�ı�����¼
      0,                          // ��������ѯ�ķ��ؼ�¼
        procedure(dPipe: TZDBPipeline; var qState: TQueryState; var Allowed: Boolean)
        begin
          Allowed := True;
          if qState.IsVT then
              qState.dbEng.VT[qState.StorePos];
        end,
        procedure(dPipe: TZDBPipeline)
        begin
          DoStatus('%s ��%sʱ���� ��� %d ����¼��ѯ',
            [dPipe.PipelineName, umlTimeTickToStr(round(dPipe.QueryConsumTime * 1000)).Text, dPipe.QueryCounter]);
        end
        );
    end;

  // �ȴ���̨��ѯ�������
  tk := GetTimeTick;
  while db.QueryProcessing do
    begin
      LM.Progress;
      CheckThreadSynchronize(100);
      if GetTimeTick - tk > 1000 then
        begin
          DoStatus('�ں�״̬ %s %s', [db.CacheAnnealingState, db.DBEngine.CacheStatus]);
          tk := GetTimeTick;
        end;
    end;

  DoStatus('���в�ѯ���������.');
  DisposeObject(LM);
end;

begin
  BuildRandCSVData;
  BuildZDB;
  QueryZDB;
end.
