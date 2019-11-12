{The encoding of these files is UTF-8, if you can not read the words below, try select UTF-8 as the default encoding of your text reader.}

unit order;

interface
uses SubPnt,Expand;
procedure DoOrder(var PhraseHead:PntPhrase);

implementation

procedure DoOrder(var PhraseHead:PntPhrase);
  //顾名思义，此过程的作用就是使得整个源码链的每行语句更加整齐(利于分析)
var
  Counter0:ts32=1;
  Counter1:ts32=0;
  Counter2:tu32=0;
  Counter3:tu32=0;
  NKeyWord:tu32=0;
  LocationBracket0:tu32=0;
  StrTemp:AnsiString;
  PhraseTemp,PhraseInvalid:PntPhrase;
  BCutPostil:boolean=false;
  temp_str:String;
  BFindLogicWord:boolean=false;	//记录在一次搜索中，有无搜到LogicWord
begin
  PhraseTemp:=PhraseHead;
  while PhraseTemp<>nil do
  begin
    StrTemp:=PhraseTemp^.phrase;
    if length(StrTemp)>0 then
      if StrTemp[1] in [ConstChar_Spacebar,ConstChar_KeyTab] then
        while (length(StrTemp)>0)and((StrTemp[1]=ConstChar_Spacebar) or (StrTemp[1]=ConstChar_KeyTab)) do
          delete(StrTemp,1,1);	//先清除掉每行源码最开头的空格和Tab符

    while (Counter0<=length(StrTemp)) and (not BCutPostil) do						//然后再去掉语句尾部注释
    begin
      if StrTemp[Counter0]=';' then
      begin
        StrTemp:=copy(StrTemp,1,Counter0-1);
	BCutPostil:=true;
      end else
        Counter0:=Counter0+1;
    end;

    //然后去掉尾部空格
    BCutPostil:=false;
    while (length(StrTemp)>0) and not BCutPostil do
    begin 
      if (StrTemp[length(StrTemp)]=ConstChar_Spacebar) or (StrTemp[length(StrTemp)]=ConstChar_KeyTab) then
        delete(StrTemp,length(StrTemp),1)
      else
        BCutPostil:=true;
    end;

    begin
      if StrTemp='#end' then
        StrTemp:=StrTemp+' ';
      if StrTemp='#repeat' then
        StrTemp:=StrTemp+' ';
      if StrTemp='#else' then
        StrTemp:=StrTemp+' ';

      NkeyWord:=0;
      Counter0:=1;
      while (NkeyWord=0)and (Counter0<=length(KeyWord)) do	//然后分析此语句是否是新添加的分支伪指令
      begin
        if copy(StrTemp,1,length(KeyWord[Counter0]))=KeyWord[Counter0] then NKeyWord:=length(KeyWord[Counter0]);
        Counter0:=Counter0+1;
      end;
      if (NKeyWord<>0)and((Counter0-1)>=11) then
        insert(' ',StrTemp,NkeyWord);

      //如果此伪指令非“#end”就进行进一步整理
      if (NKeyWord<>0)and((Counter0-1) in [3,4,5,7,8,9,11,12,13]) then
      begin
        StrTemp[NKeyWord]:=ConstChar_Spacebar;

        Counter0:=NKeyWord+1;
        while Counter0<=length(StrTemp) do							//┳清除条件
        begin											//┃表达式中
          if ((StrTemp[Counter0]=ConstChar_Spacebar)or(StrTemp[Counter0]=ConstChar_KeyTab)) then//┃所有的空
	    delete(StrTemp,Counter0,1)								//┃格和Tab
          else											//┃符
	    Counter0:=Counter0+1;								//┃
        end;											//┛

        //开始将不同名但同机器指令的指令统一
	Counter0:=NkeyWord+1;
        while Counter0<=length(StrTemp) do
        begin
	  Counter1:=1;
	  BFindLogicWord:=false;
	  while (Counter1<=31) and (not BFindLogicWord) do
	  begin
	    if copy(StrTemp,Counter0,length(LogicWord[Counter1]))=LogicWord[Counter1] then
	    begin
	      BFindLogicWord:=true;
	      case Counter1 of
                2:StrTemp[Counter0+1]:='z';
	        4:StrTemp[Counter0+2]:='z';
                10:delete(StrTemp,Counter0+2,1);
                12:begin StrTemp[Counter1+0]:='n';StrTemp[Counter0+2]:='p';end;
                14:begin delete(StrTemp,Counter0+1,2);StrTemp[Counter0+1]:='b';end;
                15:StrTemp[Counter0+1]:='b';
                17,18:begin StrTemp[Counter0+1]:='n';StrTemp[Counter0+2]:='b';end;
                19:begin StrTemp[Counter0+1]:='n';StrTemp[Counter0+2]:='a';end;
                21:begin delete(StrTemp,Counter0+1,2);StrTemp[Counter0+1]:='a';end;
                24:begin delete(StrTemp,Counter0+1,2);StrTemp[Counter0+1]:='l';end;
                26:begin StrTemp[Counter0+1]:='n';StrTemp[Counter0+2]:='l';end;
                27:begin StrTemp[Counter0+1]:='n';StrTemp[Counter0+2]:='g';end;
                29:begin delete(StrTemp,Counter0+1,2);StrTemp[Counter0+1]:='g';end;
	      end;
	    end;
	    Counter1:=Counter1+1;
	  end;
	  Counter0:=Counter0+1;
	end;//统一完成

	//将'#z?'的字符串，转换成'#1'，(#加上标号)，其他类似。以方便处理
	Counter0:=NkeyWord+1;
        while Counter0<=length(StrTemp) do
        begin
	  Counter1:=1;
	  BFindLogicWord:=false;
	  while (Counter1<=16) and (not BFindLogicWord) do
	  begin
	    if copy(StrTemp,Counter0,length(LogicWordTidy[Counter1]))=LogicWordTidy[Counter1] then
	    begin
	      BFindLogicWord:=true;
	      delete(StrTemp,Counter0+1,length(LogicWordTidy[Counter1])-1);
	      str(Counter1,temp_str);
	      insert(temp_str,StrTemp,Counter0+1);
	      Counter0:=Counter0+2;
	    end;
	    Counter1:=Counter1+1;
	  end;
	  while (Counter1<=Num_LogicWordTidy) and (not BFindLogicWord) do
	  begin
	    if copy(StrTemp,Counter0,length(LogicWordTidy[Counter1])) = LogicWordTidy[Counter1] then
	    begin
	      BFindLogicWord:=true;
	      delete(StrTemp,Counter0+1,length(LogicWordTidy[Counter1])-2);
	      str(Counter1,temp_str);
	      insert(temp_str,StrTemp,Counter0+1);
	      Counter0:=Counter0+3;
	    end;
	    Counter1:=Counter1+1;
	  end;
	  if not BFindLogicWord then Counter0:=Counter0+1;
        end;
        //转换完毕

	//开始去除多余的括号
	while pos('((',StrTemp)<>0 do
	begin
	  Counter2:=pos('((',StrTemp)+1;
          LocationBracket0:=Counter2;
          Counter3:=1;
          while Counter3<>0 do
          begin
            Counter2:=Counter2+1;
            if StrTemp[Counter2]='(' then Counter3:=Counter3+1;
            if StrTemp[Counter2]=')' then Counter3:=Counter3-1;
          end;
          delete(StrTemp,Counter2,1);
	  delete(StrTemp,LocationBracket0,1);
	end;

        while StrTemp[NKeyWord+1]='(' do			//┳最后清除
        begin							//┃最外围的
          delete(StrTemp,length(StrTemp),1);			//┃无用的括
          delete(StrTemp,NkeyWord+1,1);				//┃号
        end;							//┛
	//去除完毕

        PhraseTemp^.LogicPhrase:=DoExpand(StrTemp,NkeyWord+1);	//展开并转换#not()条件语句

      end;
    end;

    PhraseTemp^.phrase:=StrTemp;
    PhraseTemp:=PhraseTemp^.next;
    NKeyWord:=0;
    Counter0:=1;
    BCutPostil:=false;
  end;
end;



end.

