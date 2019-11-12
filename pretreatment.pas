{The encoding of these files is UTF-8, if you can not read the words below, try select UTF-8 as the default encoding of your text reader.}

unit pretreatment;

interface
uses SubPnt,order,expand,transform;


const
  temp_file:string='nasmplustemp.txt';

procedure InitPretreatment(FNameIn:string);	//一些初始化
function DoPretreatment:boolean;		//进行预处理，返回结果的值若为true，则预处理成功；若为false，则预处理失败。需检查词法、语法错误。
procedure CreateTempFile;			//备份文件，将处理后的源码写入源文件。
procedure CleanPretreatment;			//进行一些善后工作

implementation


var
  PhraseHead,PhraseTemp,PhraseTail:PntPhrase;
  Fin,Fout:text;
  SFSource:string;



//一下是供主程序调用的过程及函数，在接口部分有定义

procedure InitPretreatment(FNameIn:string);
begin
  //一些初始化操作
  SFSource:=FNameIn;
end;



procedure CleanPretreatment;
  //善后清理工作
begin
  assign(Fout,SFSource);
  erase(Fout);
  assign(Fout,temp_file);
  rename(Fout,SFSource)
end;


{
procedure CreateTempFile;
begin
  assign(Fout,SFSource);
  rewrite(Fout);
  PhraseTemp:=PhraseHead;
  while PhraseTemp<>nil do
  begin
    writeln(PhraseTemp^.phrase);
    PhraseTemp:=PhraseTemp^.next;
  end;
  close(Fout);
end;
}
procedure CreateTempFile;
var
  str:AnsiString;
begin
  assign(Fin,SFSource);
  assign(Fout,temp_file);
  reset(Fin);rewrite(Fout);
  while not eof(Fin) do
  begin
    readln(Fin,str);
    writeln(Fout,str);
  end;
  close(Fin);close(Fout);

  assign(Fout,SFSource);
  rewrite(Fout);
  PhraseTemp:=PhraseHead;
  while PhraseTemp<>nil do
  begin
    writeln(Fout,PhraseTemp^.phrase);
    PhraseTemp:=PhraseTemp^.next;
  end;
  close(Fout);
end;




function DoPretreatment:boolean;
  //好吧，现在我们开始真正的预处理阶段
var
  linenum:tu32;

  function IfPhraseValid(str:AnsiString):boolean;
    //判断一个句子是否是无用的。例如：整行的注释就是无效的句子。
  var
    Counter0,Counter1:ts32;
    find,AllSpace:boolean;    
  begin
    IfPhraseValid:=false;
    if str<>'' then
    begin      
      find:=false;
      AllSpace:=true;
      Counter0:=1;
      while (Counter0<=length(str)) and AllSpace do
      begin
        AllSpace:=(str[Counter0]=ConstChar_SpaceBar)or(str[Counter0]=ConstChar_KeyTab);
        Counter0:=Counter0+1;
      end;
      IfPhraseValid:=not AllSpace;
      if IfPhraseValid then
      begin
        Counter0:=length(str);
        Counter1:=1;
        while (Counter1<=Counter0)and not find do
        begin
          find:=(str[Counter1]<>ConstChar_Spacebar)and(str[Counter1]<>ConstChar_KeyTab);
          Counter1:=Counter1+1;
        end;
        IfPhraseValid:=str[Counter1-1]<>';';
      end;
    end;
  end;

begin
  DoPretreatment:=false;
  assign(Fin,SFSource);
  reset(Fin);

  linenum:=0;

  new(PhraseHead);
  PntPhraseClean(PhraseHead);

  new(PhraseTail);
  PntPhraseClean(PhraseTail);
  PhraseTail^.prev:=PhraseHead;
  PhraseHead^.next:=PhraseTail;
  if not eof(Fin) then
  begin
    linenum:=linenum+1;
    readln(Fin,PhraseTail^.phrase);
    while (not IfPhraseValid(PhraseTail^.phrase)) and (not eof(Fin)) do
    begin
      linenum:=linenum+1;
      readln(Fin,PhraseTail^.phrase);
    end;
    PhraseTail^.number:=linenum;
  end;
  while not eof(Fin) do
  begin
    new(PhraseTemp);
    PntPhraseClean(PhraseTemp);
    linenum:=linenum+1;
    readln(Fin,PhraseTemp^.phrase);
    while (not IfPhraseValid(PhraseTemp^.phrase)) and (not eof(Fin)) do
    begin
      linenum:=linenum+1;
      readln(Fin,PhraseTemp^.phrase);
    end;
    PhraseTemp^.number:=linenum;
    if IfPhraseValid(PhraseTemp^.phrase) then
    begin
      PhraseTail^.next:=PhraseTemp;
      PhraseTemp^.prev:=PhraseTail;
      PhraseTail:=PhraseTemp;
    end;
  end;

  close(Fin);

  //在语句列表末尾加上一行空行，作用么，就是方便行末语句的插入
  new(PhraseTemp);
  PntPhraseclean(PhraseTemp);
  PhraseTemp^.prev:=PhraseTail;
  PhraseTail^.next:=PhraseTemp;
  PhraseTail:=PhraseTemp;

  DoOrder(PhraseHead);		//使整齐并转换格式
  DoTransform(PhraseHead);	//转换语句链

  //清除开头和末尾的空行
  PhraseHead:=PhraseHead^.next;
  PntPhraseClean(PhraseHead^.prev);
  PhraseHead^.prev:=nil;
  PhraseTail:=PhraseTail^.prev;
  PntPhraseClean(PhraseTail^.next);
  PhraseTail^.next:=nil;

  DoPretreatment:=true;
end;



end.

