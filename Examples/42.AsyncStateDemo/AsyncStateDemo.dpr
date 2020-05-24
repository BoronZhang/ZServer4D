program AsyncStateDemo;

{$APPTYPE CONSOLE}

{$R *.res}


uses
  Variants,
  CoreClasses,
  DoStatusIO;

// ����ʾ���߳���ʹ�ð�ȫ״̬��
procedure StateDemo();
var
  State: TAtomBool;
begin
  // �̰߳�ȫ:״̬����
  State := TAtomBool.Create(False);
  // �����߳�
  TCompute.RunP_NP(procedure
    var
      i: Cardinal;
    begin
      for i := 0 to $FFFFFFFF do
          nop;
      DoStatus('���һ������');
      // �ı�״̬����
      State.V := True;
    end);
  DoStatus('�ȴ�ѭ���������.');
  while not State.V do
    begin
      DoStatus();
      TCompute.Sleep(1);
    end;
  DisposeObject(State);
end;

// ����ʾ���߳���ʹ��Post����
// post��ͬ�ڰѴ��뷢�͸�һ�����ǹ�����Ŀ���߳���ִ��,post��������������,���������߳�/���߳�,�κ��̶߳���ʹ��
procedure PostDemo();
var
  P: TThreadProgressPost; // TThreadProgressPost,Post����֧��
  doneState: TAtomBool;   // �̰߳�ȫ:״̬����
begin
  // �̰߳�ȫ:״̬����
  doneState := TAtomBool.Create(False);
  P := TThreadProgressPost.Create(0);
  // �����߳�
  TCompute.RunP_NP(procedure
    begin
      P.ThreadID := TCompute.CurrentThread.ThreadID;
      while not doneState.V do
        begin
          P.Progress(); // post��ѭ��
          TCompute.Sleep(1);
        end;
      DisposeObjectAndNil(P);
    end);
  // �������̷߳�����
  // ��Щ������ϸ�����˳��ִ��
  P.PostP1(procedure
    begin
      DoStatus(1);
    end);
  P.PostP1(procedure
    begin
      DoStatus(2);
    end);
  TCompute.RunP_NP(procedure
    var
      i: Integer;
    begin
      for i := 3 to 10 do
        begin
          P.PostP3(nil, nil, i, procedure(Data1: Pointer; Data2: TCoreClassObject; Data3: Variant)
            begin
              DoStatus(VarToStr(Data3));
            end);
        end;
      // �����߳̽���
      P.PostP1(procedure
        begin
          doneState.V := True;
        end);
    end);
  // ��ִ����
  while not doneState.V do
    begin
      DoStatus();
      TCompute.Sleep(1);
    end;
  DisposeObject(doneState);
end;

begin
  stateDemo();
  PostDemo();
  DoStatus('�س�����������.');
  readln;

end.
