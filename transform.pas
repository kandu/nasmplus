{The encoding of these files is UTF-8, if you can not read the words below, try select UTF-8 as the default encoding of your text reader.}

unit transform;

interface
uses SubPnt;
procedure DoTransform(PhraseHead:PntPhrase);

implementation

procedure DoTransform(PhraseHead:PntPhrase);
var
  BFind,BFindInstr,BFindElse:boolean;
  Counter0:ts32=0;
  Counter1:ts32=0;
  Counter_pair:ts32=0;				//为了查找成对的逻辑判断语句和end语句而设
  Counter_lable:tu32=0;
  PhraseTemp,PhraseTail,PhraseBegin,PhraseEnd:PntPhrase;
  PhraseSearch_head,PhraseSearch_middle,PhraseSearch_tail,PhraseSearch_temp:PntPhrase;
  PhraseLogicJudge:PntPhrase;
  temp_str0:AnsiString;
  temp_str1:string;
  BranchType:ts32;				//分支类型，也就是if,while,repeat之类的
  str_label_true,str_label_false:string;	//true出口label和false出口label
  Phrase_Logic_judge:PntPhrase;			//用于存放待插入的逻辑判断汇编语句
  Temp_Phrase0:PntPhrase;


  //用于生成标号
  function ProduceLabel:string;
  const
    LabelByAP:string='labelbyap_';
    LabelOfAP:tu32=0;
  var
    temp_str:string;
  begin
    LabelOfAP:=LabelOfAP+1;
    str(LabelOfAP,temp_str);
    ProduceLabel:=LabelByAP+temp_str;
  end;



  //重头戏开始，
  function ProduceLogicJudge(Plogic:PntLogic;LineNum:tu32;StrFalse:string):PntPhrase;


    function DoProduceLogicJudge(Plogic:PntLogic;StrFalse:string):PntPhrase;
    var
      temp_code:word;
      temp_str:string;
      temp_str1,temp_str2:string;
      temp_PntPhrase:PntPhrase;
      temp_PntPhrase1,temp_PntPhrase2,temp_PntPhrase3:PntPhrase;
      LogicNum:tu32;
    begin
      if Plogic<>nil then
      begin
        val(copy(Plogic^.logic,2,length(Plogic^.logic)-1),LogicNum,temp_code);
        case LogicNum of
          1..16:
            begin
              new(DoProduceLogicJudge);
              PntPhraseClean(DoProduceLogicJudge);
              if LogicNum mod 2 = 0 then
              begin
                temp_str:=LogicWordTidy[LogicNum-1];
              end else
              begin
                temp_str:=LogicWordTidy[LogicNum+1];
              end;
              temp_str[1]:='j';temp_str[length(temp_str)]:=ConstChar_Spacebar;
              DoProduceLogicJudge^.phrase:=temp_str+StrFalse;
            end;
          17..26:
            begin
              new(DoProduceLogicJudge);
              PntPhraseClean(DoProduceLogicJudge);
              DoProduceLogicJudge^.phrase:='cmp '+Plogic^.first^.logic+', '+Plogic^.second^.logic;
              new(temp_PntPhrase);PntPhraseClean(temp_PntPhrase);
              case LogicNum of
                17:temp_PntPhrase^.phrase:='jbe '+StrFalse;
                18:temp_PntPhrase^.phrase:='ja '+StrFalse;
                19:temp_PntPhrase^.phrase:='jle '+StrFalse;
                20:temp_PntPhrase^.phrase:='jg '+StrFalse;
                21:temp_PntPhrase^.phrase:='jb '+StrFalse;
                22:temp_PntPhrase^.phrase:='jae '+StrFalse;
                23:temp_PntPhrase^.phrase:='jl '+StrFalse;
                24:temp_PntPhrase^.phrase:='jge '+StrFalse;
                25:temp_PntPhrase^.phrase:='jnz '+StrFalse;
                26:temp_PntPhrase^.phrase:='jz '+StrFalse;
              end;
              DoProduceLogicJudge^.next:=temp_PntPhrase;
              temp_PntPhrase^.prev:=DoProduceLogicJudge;
              temp_PntPhrase:=nil;
            end;
          27:
            begin
              //sorry, i foget why i set the #t instruction
            end;
          28:
            begin
              //the same reason
            end;
          29:
            begin
              temp_PntPhrase:=DoProduceLogicJudge(Plogic^.first,StrFalse);
              PntPhraseChainCombine(temp_PntPhrase,DoProduceLogicJudge(Plogic^.second,StrFalse));
              DoProduceLogicJudge:=temp_PntPhrase;
              temp_PntPhrase:=nil;
            end;
          30:
            begin
              temp_str1:=ProduceLabel;
              temp_PntPhrase:=DoProduceLogicJudge(Plogic^.first,temp_str1);
              
              new(temp_PntPhrase1);
              PntPhraseClean(temp_PntPhrase1);
              temp_str2:=ProduceLabel;
              temp_PntPhrase1^.Phrase:='jmp '+temp_str2;
              new(temp_PntPhrase2);
              PntPhraseClean(temp_PntPhrase2);
              temp_PntPhrase2^.Phrase:=temp_str1+':';
              PntPhraseChainCombine(temp_PntPhrase1,temp_PntPhrase2);
              PntPhraseChainCombine(temp_PntPhrase,temp_PntPhrase1);
              PntPhraseChainCombine(temp_PntPhrase,DoProduceLogicJudge(Plogic^.second,StrFalse));
              new(temp_PntPhrase3);
              PntPhraseClean(temp_PntPhrase3);
              temp_PntPhrase3^.Phrase:=temp_str2+':';
              PntPhraseChainCombine(temp_PntPhrase,temp_PntPhrase3);
              DoProduceLogicJudge:=temp_PntPhrase;              
            end;
          31:
            begin
              //it had done
            end;
          32:
            begin
              //it had done
            end;
        end;
      end;
    end;


  begin
    ProduceLogicJudge:=DoProduceLogicJudge(Plogic,StrFalse);
  end;



begin
  PhraseTemp:=PhraseHead;
  while PhraseTemp<>nil do
  begin
    BFind:=false;
    PhraseSearch_middle:=nil;
    PhraseSearch_temp:=PhraseTemp;
    PhraseTemp:=PhraseTemp^.next;

    BranchType:=0;
    Counter0:=1;
    BFindInstr:=false;
    while (BranchType=0)and(Counter0<=length(KeyWordTidy))and not BFindInstr do		//寻找条件伪指令
    begin
      if length(PhraseSearch_Temp^.phrase)>=length(KeyWordTidy[Counter0]) then
        if copy(PhraseSearch_Temp^.phrase,1,length(KeyWordTidy[Counter0])) = KeyWordTidy[Counter0] then
        begin
          BranchType:=Counter0;
          BFindInstr:=true;
        end;
      Counter0:=Counter0+1;
    end;

    if BranchType=1 then
      ErrorHalt(1,'no condition word pair #end')		//如果一开始就找到一个#end，那么，你的源码写错了。	//此行需更改，以后得统一错误码
    else if BranchType=2 then
    begin		//若找到#repeat
      Counter_pair:=1;
      PhraseSearch_head:=PhraseSearch_temp;
      PhraseSearch_temp:=PhraseSearch_head^.next;

      while (Counter_pair<>0)and(PhraseSearch_temp<>nil) do	//开始找对应的#end;
      begin
        Counter0:=0;
        Counter1:=1;
        while (Counter0=0)and(Counter1<=length(KeyWordTidy)) do
        begin
          if copy(PhraseSearch_temp^.phrase,1,length(KeyWordTidy[Counter1])) = KeyWordTidy[Counter1] then
          begin
            Counter0:=Counter1;
          end;
          Counter1:=Counter1+1;
        end;
        if (Counter0=2)and(Counter0<=length(KeyWordTidy)) then
          Counter_pair:=Counter_pair+1
        else if Counter0=3 then
          Counter_pair:=Counter_pair-1;

        PhraseSearch_temp:=PhraseSearch_temp^.next;
      end;

      if Counter_pair<>0 then ErrorHalt(1,'no #until paired #repeat');	//未找到对应#until;

      PhraseSearch_tail:=PhraseSearch_temp^.prev;	//至此已找到对应#until;
      BFind:=true;

      str_label_false:=ProduceLabel;
      new(Temp_Phrase0);
      PntPhraseClean(Temp_Phrase0);
      Temp_Phrase0^.phrase:=str_label_false+':';
      PntPhraseInsertHead(PhraseSearch_head,Temp_Phrase0);
      Phrase_Logic_judge:=ProduceLogicJudge(PhraseSearch_Tail^.LogicPhrase,PhraseSearch_head^.number,str_label_false);
      PntPhraseChainInsertTail(PhraseSearch_Tail,Phrase_Logic_judge);
    end
    else if BranchType=3 then
    begin
      ErrorHalt(1,'no #repeat pair #until');
    end
    else if BranchType in[4,5] then
    begin		//若找到一个普通的条件语句
      BFindElse:=false;
      Counter_pair:=1;
      PhraseSearch_head:=PhraseSearch_temp;
      PhraseSearch_temp:=PhraseSearch_head^.next;

      while (Counter_pair<>0)and(PhraseSearch_temp<>nil) do	//开始找对应的#end;
      begin
        Counter0:=0;
        Counter1:=1;
        while (Counter0=0)and(Counter1<=length(KeyWordTidy)) do
        begin
          if copy(PhraseSearch_temp^.phrase,1,length(KeyWordTidy[Counter1])) = KeyWordTidy[Counter1] then
          begin
            Counter0:=Counter1;
          end;
          Counter1:=Counter1+1;
        end;
        if Counter0 in [4,5] then
          Counter_pair:=Counter_pair+1
        else if Counter0=1 then
          Counter_pair:=Counter_pair-1
        else if (Counter0=6) and (Counter_pair=1) then
        begin
          BFindElse:=true;
          PhraseSearch_middle:=PhraseSearch_temp;
        end;

        PhraseSearch_temp:=PhraseSearch_temp^.next;
      end;

      if Counter_pair<>0 then ErrorHalt(1,'no condition word pair #end');	//未找到对应#end;

      PhraseSearch_tail:=PhraseSearch_temp^.prev;	//至此已找到对应#end;
      BFind:=true;

      if BranchType=4 then
      begin
        if BFindElse then
        begin
          temp_str1:=ProduceLabel;
          new(Temp_Phrase0);
          PntPhraseClean(Temp_Phrase0);
          Temp_Phrase0^.phrase:=temp_str1+':';
          PntPhraseInsertTail(PhraseSearch_tail,Temp_Phrase0);
          Temp_phrase0:=nil;

          new(Temp_Phrase0);
          PntPhraseClean(Temp_Phrase0);
          Temp_Phrase0^.phrase:='jmp '+temp_str1;
          PntPhraseInsertHead(PhraseSearch_middle,Temp_Phrase0);
          Temp_phrase0:=nil; 

          str_label_false:=ProduceLabel;
          new(Temp_Phrase0);
          PntPhraseClean(Temp_Phrase0);
          Temp_Phrase0^.phrase:=str_label_false+':';
          PntPhraseInsertHead(PhraseSearch_middle,Temp_Phrase0);
          Temp_phrase0:=nil;
        end else
        begin
          str_label_false:=ProduceLabel;
          new(Temp_Phrase0);
          PntPhraseClean(Temp_Phrase0);
          Temp_Phrase0^.phrase:=str_label_false+':';
          PntPhraseInsertTail(PhraseSearch_tail,Temp_Phrase0);
          Temp_phrase0:=nil;
        end;
      end;

      if BranchType=5 then
      begin
        str_label_false:=ProduceLabel;
        new(Temp_Phrase0);
        PntPhraseClean(Temp_Phrase0);
        Temp_Phrase0^.phrase:=str_label_false+':';
        PntPhraseInsertTail(PhraseSearch_tail,Temp_Phrase0);
        Temp_phrase0:=nil;

        temp_str1:=ProduceLabel;
        new(Temp_Phrase0);
        PntPhraseClean(Temp_Phrase0);
        Temp_Phrase0^.phrase:=temp_str1+':';
        PntPhraseInsertHead(PhraseSearch_head,Temp_Phrase0);
        new(Temp_Phrase0);
        PntPhraseClean(Temp_Phrase0);
        Temp_Phrase0^.phrase:='jmp '+temp_str1;
        PntPhraseInsertTail(PhraseSearch_tail,Temp_Phrase0);
        Temp_phrase0:=nil;  
      end;

      Phrase_Logic_judge:=ProduceLogicJudge(PhraseSearch_head^.LogicPhrase,PhraseSearch_head^.number,str_label_false);
      PntPhraseChainInsertTail(PhraseSearch_head,Phrase_Logic_judge);
    end else
    if BranchType=6 then
    begin
      //developing
    end;

    if BFind then
    begin
      PntPhraseDel(PhraseSearch_head);
      PntPhraseDel(PhraseSearch_middle);
      PntPhraseDel(PhraseSearch_tail);
    end;

  end;
end;



end.

