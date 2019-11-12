{The encoding of these files is UTF-8, if you can not read the words below, try select UTF-8 as the default encoding of your text reader.}

unit expand;

interface
uses SubPnt;
function DoExpand(var StrTemp:AnsiString;TempUseless:tu32):PntLogic;

implementation
var
  StrLogic:AnsiString;

procedure CreateLogicTree(LogicItem:PntLogic;start:tu32);
var
  Counter0:tu32;
  Counter1:tu32;
  LocationComma:tu32;
  LocationBracket0:tu32;
  //LocationBracket1:tu32;
  BNotFind:boolean;
begin
  Counter0:=0;
  Counter1:=0;
  LocationComma:=0;
  LocationBracket0:=0;
  //LocationBracket1:=0;
  BNotFind:=false;

  Counter0:=start;
  while (StrLogic[Counter0]<>',')and(StrLogic[Counter0]<>'(')and(StrLogic[Counter0]<>')')and(Counter0<=length(StrLogic))do
  begin
    if Counter0=length(StrLogic) then
    begin
      BNotFind:=true;
    end;
    Counter0:=Counter0+1;
  end;
  if BNotFind then
    LogicItem^.logic:=copy(StrLogic,start,Counter0+1-start)
  else
    LogicItem^.logic:=copy(StrLogic,start,Counter0-start);

  if StrLogic[Counter0]='(' then//若有下级，则找出两括号及逗号的位置
  begin
    LocationBracket0:=Counter0;
    Counter1:=1;
    while Counter1<>0 do
    begin
      Counter0:=Counter0+1;
      if StrLogic[Counter0]='(' then Counter1:=Counter1+1;
      if StrLogic[Counter0]=')' then Counter1:=Counter1-1;
      if (StrLogic[Counter0]=',')and(Counter1=1)then LocationComma:=Counter0;
    end;
    //LocationBracket1:=Counter0;	//至此，两括号和逗号的位置全部找出


    new(LogicItem^.first);
    LogicItem^.first^.logic:='#0';
    LogicItem^.first^.first:=nil;
    LogicItem^.first^.second:=nil;
    CreateLogicTree(LogicItem^.first,LocationBracket0+1);

    if LocationComma<>0 then
    begin
      new(LogicItem^.second);
      LogicItem^.second^.logic:='#0';
      LogicItem^.second^.first:=nil;
      LogicItem^.second^.second:=nil;
      CreateLogicTree(LogicItem^.second,LocationComma+1);
    end;

  end;
end;



procedure ExpandNot(var PLogicItem:PntLogic);
var
  temp_PntPhrase:PntLogic;
  temp_str0:string;
  temp_num0:tu32;
begin
  if PLogicItem<>nil then
  begin 
    while (PLogicItem^.logic='#31') or (PLogicItem^.logic='#32') do
    begin
      while (PLogicItem^.logic='#31') do
      begin
        PlogicItem^:=PlogicItem^.first^;
      end;

      //若当前项是#not就开始转换逻辑语句
      if PLogicItem^.logic='#32' then
      begin
        val(copy(PLogicItem^.first^.logic,2,length(PLogicItem^.first^.logic)-1),temp_num0);
        if temp_num0 mod 2=0 then
        begin
          str(temp_num0-1,temp_str0);
        end else
        begin
          str(temp_num0+1,temp_str0);
        end;

        PLogicItem^.first^.logic:='#'+temp_str0;
	temp_PntPhrase:=PLogicItem^.first;
        PLogicItem^:=PLogicItem^.first^;
	dispose(temp_PntPhrase);

        if (PLogicItem^.logic='#29')or(PLogicItem^.logic='#30') then
        begin
          new(temp_PntPhrase);
          temp_PntPhrase^.logic:='#32';
          temp_PntPhrase^.first:=PlogicItem^.first;
          temp_PntPhrase^.second:=nil;
          PlogicItem^.first:=temp_PntPhrase;
          new(temp_PntPhrase);
          temp_PntPhrase^.logic:='#32';
          temp_PntPhrase^.first:=PlogicItem^.second;
          temp_PntPhrase^.second:=nil;
          PlogicItem^.second:=temp_PntPhrase;
        end;
      end;

      //展开其第一，第二子树
      ExpandNot(PLogicItem^.first);
      ExpandNot(PLogicItem^.second);//展开完毕

    end;
  end;
end;



function DoExpand(var StrTemp:AnsiString;TempUseless:tu32):PntLogic;
  //用于展开“#not()”语句，利用一些逻辑运算，转换条件语句，最终在条件语句中去除“#not”形式的表达式，这非常有用，大大简化了接下来的语句生成
begin
  new(DoExpand);
  DoExpand^.logic:='#0';
  DoExpand^.first:=nil;
  DoExpand^.second:=nil;
  StrLogic:=StrTemp;
  CreateLogicTree(DoExpand,TempUseless);
  ExpandNot(DoExpand);
end;



end.

