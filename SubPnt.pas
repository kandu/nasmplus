{The encoding of these files is UTF-8, if you can not read the words below, try select UTF-8 as the default encoding of your text reader.}

unit SubPnt;


interface

const
  ConstChar_Spacebar:char=' ';		//┓
  ConstChar_KeyTab:char='	';	//┻如果在源程序里直接写，非常容易搞混

const
  Num_LogicWord=47;
  Num_LogicWordTidy=(16+16+1)-1;
  KeyWord:array[1..14]of string=('#end ','#repeat ','#until ','#if ','#while ','#else ','#until	','#if	','#while	','#else	','#until(','#if(','#while(','#else(');
  KeyWordTidy:array[1..6]of string=('#end ','#repeat ','#until ','#if ','#while ','#else ');

  LogicWord:array[1..Num_LogicWord]of string=
    ('#z?','#e?','#nz?','#ne?','#s?',{下标6}'#ns?','#o?','#no?','#p?','#pe?',{下标11}'#np?','#po?','#b?','#nae?','#c?','#nb?'
    ,'#ae?','#nc?','#be?','#na?',{下标21}'#nbe?','#a?','#l?','#nge?','#nl?',{下标26}'#ge?','#le?','#ng?','#nle?','#g?','#cxz?'
    {下标32},'#and(','#or(','#not(','#be','#>(','#<=(','#s>(','#s<=(','#>=(','#<(','#s>=(','#s<(','#=(','#<>(','#t(','#nt(');

  LogicWordTidy:array[0..Num_LogicWordTidy]of string=
    {标号0留给未知指令，以使得NASM+发出通知，报错或升级至最新版本}
    ('#0','#z?','#nz?','#s?','#ns?','#o?','#no?','#p?','#np?','#b?','#nb?','#a?','#na?','#l?','#nl?','#g?','#ng?'
    ,'#>(','#<=(','#s>(','#s<=(','#>=(','#<(','#s>=(','#s<(','#=(','#<>(','#t(','#nt(','#and(','#or(','#be(','#not(');

type
  {透明的，简单的，就是下面的这些类型定义啦：}
  ts8 = ShortInt;
  ts16 = SmallInt;
  ts32 = LongInt;
  ts64 = Int64;
  tu8 = Byte;
  tu16 = Word;
  tu32 = LongWord;
  tu64 = QWord;

  ps8 = ^ShortInt;
  ps16 = ^SmallInt;
  ps32 = ^LongInt;
  ps64 = ^Int64;
  pu8 = ^Byte;
  pu16 = ^Word;
  pu32 = ^LongWord;
  pu64 = ^QWord;

  pint64 = ^int64;

  psingle = ^single;
  pdouble = ^double;
  pextended = ^extended;

  pchar = ^char;
  PWideChar = ^WideChar;
  pShortString = ^ShortString;
  pAnsiString = ^AnsiString;
  pWideString = ^WideString;

  PntLogic=^RecLogic;		//┓
  RecLogic=record		//┃
    logic:string;		//┃
    first,second:PntLogic;	//┃
  end;				//┻这个结构用以形成一个逻辑表达式的分解二叉树

  PntPhrase=^RecPhrase;		//┓
  RecPhrase=record		//┃
    phrase:AnsiString;		//┃
    number:tu32;		//┃
    LogicPhrase:PntLogic;	//┃
    prev,next:PntPhrase;	//┃
  end;				//┻这个结构用以形成一个源程序的语句链表



//一些处理PntPhrase指针的子程序
procedure PntPhraseInsertHead(var P,Pin:PntPhrase);//已经过测试
procedure PntPhraseInsertTail(var P,Pin:PntPhrase);//已经过测试
procedure PntPhraseDel(var Pin:PntPhrase);//
function PntPhraseCopy(Pin:PntPhrase):PntPhrase;//已经过测试

//一些处理PntPhrase链表的子程序
function PntPhraseChainCopy(Pin:PntPhrase;Number:ts32):PntPhrase;//已经过测试
procedure PntPhraseChainDel(var Pin:PntPhrase;Number:ts32);//
function PntPhraseChainCut(Pin:PntPhrase;Number:ts32):PntPhrase;//已经过测试
procedure PntPhraseChainInsertTail(var P,Pin:PntPhrase);//已经过测试
procedure PntPhraseChainCombine(P,Pin:PntPhrase);

//一些处理PntLogic指针的子程序
procedure PntLogicChainDel(Pin:PntLogic);

procedure PntPhraseClean(var Pin:PntPhrase);

//一些杂七杂八的子程序
function FileExist(FileName:string):boolean;
procedure ErrorHalt(ErrorNum:byte;ErrorMsg:string);

implementation




//一些处理PntPhrase指针的子程序

procedure PntPhraseInsertHead(var P,Pin:PntPhrase);//已经过测试
  //将Pin插入到链表中，并在P之前(如果Pin处在一个链表中，则会破坏Pin所在链表的结构，此时可配合PntPhraseCopy使用)
begin
  Pin^.prev:=P^.prev;
  Pin^.next:=P;
  if P^.prev<>nil then P^.prev^.next:=Pin;
  P^.prev:=Pin;
end;

procedure PntPhraseInsertTail(var P,Pin:PntPhrase);//已经过测试
  //将Pin插入到链表中，并在P之后(如果Pin处在一个链表中，则会破坏Pin所在链表的结构，此时可配合PntPhraseCopy使用)
begin
  Pin^.next:=P^.next;
  Pin^.prev:=P;
  if P^.next<>nil then P^.next^.prev:=Pin;
  P^.next:=Pin;
end;

procedure PntPhraseDel(var Pin:PntPhrase);//已经过测试
  //从链表中去除一个指针及其数据，并连接断裂处
begin
  if Pin<>nil then
  begin
    if Pin^.prev<>nil then Pin^.prev^.next:=Pin^.next;
    if Pin^.next<>nil then Pin^.next^.prev:=Pin^.prev;
    PntLogicChainDel(Pin^.LogicPhrase);
    dispose(Pin);
  end;
end;

function PntPhraseCopy(Pin:PntPhrase):PntPhrase;//已经过测试
  //复制一个指针及其指向的数据到新生成的指针
begin
  new(PntPhraseCopy);
  PntPhraseCopy^:=Pin^;
end;



//一些处理PntPhrase链表的子程序

function PntPhraseChainCopy(Pin:PntPhrase;Number:ts32):PntPhrase;//已经过测试
  //从Pin起始的链表冲复制出Number个指针形成一段以PntPhraseChainCopy开头的子链表。
var
  PntPhraseTemp,PntPhraseTail:PntPhrase;
begin
  PntPhraseChainCopy:=nil;
  if (Pin<>nil) and (Number>0) then
  begin
    new(PntPhraseChainCopy);
    PntPhraseChainCopy^.phrase:=Pin^.phrase;
    PntPhraseChainCopy^.prev:=nil;
    PntPhraseChainCopy^.next:=nil;
    Number:=Number-1;
    Pin:=Pin^.next;
  end;
  if (Pin<>nil) and (Number>0) then
  begin
    new(PntPhraseTail);
    PntPhraseTail^.phrase:=Pin^.phrase;
    PntPhraseTail^.prev:=PntPhraseChainCopy;
    PntPhraseTail^.next:=nil;
    PntPhraseChainCopy^.next:=PntPhraseTail;
    Number:=Number-1;
    Pin:=Pin^.next;
  end;
  while (Pin<>nil) and (Number>0) do
  begin
    new(PntPhraseTemp);
    PntPhraseTemp^.phrase:=Pin^.phrase;
    PntPhraseTemp^.prev:=PntPhraseTail;
    PntPhraseTemp^.next:=nil;
    PntPhraseTail^.next:=PntPhraseTemp;
    PntPhraseTail:=PntPhraseTemp;
    Number:=Number-1;
    Pin:=Pin^.next;
  end;
end;

procedure PntPhraseChainDel(var Pin:PntPhrase;Number:ts32);//已经过重写比较测试
  //删除链表中的一段子链表，并连接断裂处
var
  PntPhraseHead,PntPhraseTail,PntPhraseTemp:PntPhrase;
begin
  if (Pin<>nil) and (Number>0) then
  begin
    PntPhraseHead:=Pin^.prev;
    PntPhraseTemp:=Pin;
    while (Number>0) and (PntPhraseTemp<>nil) do
    begin
      PntPhraseTail:=PntPhraseTemp^.next;      
      PntLogicChainDel(PntPhraseTemp^.LogicPhrase);
      dispose(PntPhraseTemp);
      PntPhraseTemp:=PntPhraseTemp^.next;
      Number:=Number-1;
    end;
    if PntPhraseHead<>nil then PntPhraseHead^.next:=PntPhraseTail;
    if PntPhraseTail<>nil then PntPhraseTail^.prev:=PntPhraseHead
    else
      PntPhraseHead^.next:=nil;
  end;
end;

function PntPhraseChainCut(Pin:PntPhrase;Number:ts32):PntPhrase;//已经过测试
  //剪切链表的一段子链表，并连接断裂处
  {
     虽然剪切这个操作可以简单地调用PntPhraseCopy复制一段子链表，然后调用PntPhraseDel删除原先的子链表做到，
     但这样会花更多的时间(有许多的new操作和dispose操作)，而且，也容易造成堆的空洞。虽然OS可以利用CPU的页
     式内存管理，但对于一个运行于OS下的普通程序来说，页式管理是不能的。堆的空洞自然不能通过页的切换来消除
     只能通过编译器附加到本程序中的堆管理器管理回收，为了减小内存占用及减小运行时间，特添加这一函数
  }
var
  PntPhraseHead,PntPhraseTail,PntPhraseHeadNew,PntPhraseTailNew:PntPhrase;
begin
  PntPhraseChainCut:=nil;
  PntPhraseHead:=nil;
  PntPhraseTail:=nil;
  PntPhraseHeadNew:=nil;
  PntPhraseTailNew:=nil;
  if (Pin<>nil)and (Number>0) then
  begin
    PntPhraseChainCut:=Pin;
    PntPhraseHeadNew:=Pin;
    while (Pin<>nil)and (Number>0) do
    begin
      PntPhraseTailNew:=Pin;
      Pin:=Pin^.next;
      Number:=Number-1;
    end;
    PntPhraseHead:=PntPhraseHeadNew^.prev;
    PntPhraseTail:=PntPhraseTailNew^.next;
    PntPhraseChainCut^.prev:=nil;
    PntPhraseTailNew^.next:=nil;
    if PntPhraseHead<>nil then PntPhraseHead^.next:=PntPhraseTail;
    if PntPhraseTail<>nil then PntPhraseTail^.prev:=PntPhraseHead;
  end;
end;

procedure PntPhraseChainInsertTail(var P,Pin:PntPhrase);//已经过测试
  //将链表Pin插入到目标链表的P指针后
  //若P指针是Nil指针，则什么事都不干，一切照旧
var
  PntPhraseTail:PntPhrase;
begin
  if (P<>nil) and (Pin<>nil) then
  begin
    PntPhraseTail:=Pin;
    while PntPhraseTail^.next<>nil do PntPhraseTail:=PntPhraseTail^.next;
    Pin^.prev:=P;
    PntPhraseTail^.next:=P^.next;
    if P^.next<>nil then P^.next^.prev:=PntPhraseTail;
    P^.next:=Pin;
  end;
end;


procedure PntPhraseChainCombine(P,Pin:PntPhrase);
begin
  if (P<>nil) and (Pin<>nil) then
  begin
    while P^.next<>nil do P:=P^.next;
    P^.next:=Pin;
    Pin^.prev:=P;
  end;
end;



//一些处理PntLogic指针的程序
procedure PntLogicChainDel(Pin:PntLogic);

begin
  if Pin<>nil then
  begin
    PntLogicChainDel(Pin^.first);
    PntLogicChainDel(Pin^.second);
    dispose(Pin);
  end;  
end;


procedure PntPhraseClean(var Pin:PntPhrase);
begin
  with Pin^ do
  begin
    phrase:='';
    number:=0;
    LogicPhrase:=nil;
    prev:=nil;
    next:=nil;
  end;
end;



//一些杂七杂八的子程序
function FileExist(FileName:string):boolean;
var
  f:file;
begin
  FileExist:=true;
  assign(f,FileName);
  {$I-}
  reset(f);
  {$I+}
  if IOResult<>0 then
    FileExist:=false
  else
    close(f);
end;



procedure ErrorHalt(ErrorNum:byte;ErrorMsg:string);
begin
  writeln(ErrorMsg);
  halt(ErrorNum);
end;




end.

