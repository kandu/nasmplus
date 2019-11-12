{The encoding of these files is UTF-8, if you can not read the words below, try select UTF-8 as the default encoding of your text reader.}

{*************************************************}
{*	NasmPlus——NASM预处理器 (c)张道远(Kandu)	**}
{*				2008-12-28	**}
{*************************************************}

//一些闲话：把你的编辑器或文本阅读器的Tab的宽度设为8，字体设置成等宽字体，这将使你得到最佳的阅读体验 :)

{
  这个小工具以后可能会继续发展(可能性非常大)，但绝不会添加太多所谓的新特性，不会对NASM语义做任何修改，不会增加太多伪指令。
  因为简单明了是美丽的，就像Pascal，NASM一样。而臃肿混乱是丑陋的，就像C，MASM一样。
}



program NasmPlus;
{$IFDEF Windows}
  uses dos,pretreatment,SubPnt;
{$ELSE}
  uses unix,pretreatment,SubPnt;
{$ENDIF}

var
  Counter0:ts32;
  f:file;
  MainDir,NasmCmd:string;
  BIgnore:boolean=false;

begin
  NasmCmd:='';
  MainDir:=ParamStr(0);		//┓
  Counter0:=length(MainDir);	//┃
  repeat			//┃
    Counter0:=Counter0-1;	//┃
  {$IFDEF Windows}		//┃
    until MainDir[Counter0]='\';//┃
  {$ELSE}			//┃
    until MainDir[Counter0]='/';//┃
  {$ENDIF}			//┃
  byte(MainDir[0]):=Counter0;	//┻得到程序自身所在目录

  if ParamCount=0 then
  begin
    NasmCmd:='-h';
    BIgnore:=true
  end else
  begin
    Counter0:=1;
    while (Counter0<=ParamCount)and not BIgnore do
    begin
      NasmCmd:=NasmCmd+' '+ParamStr(Counter0);				//获得命令行参数
      if (ParamStr(Counter0)='-v')or(ParamStr(Counter0)='-h') then
      begin
        BIgnore:=true;
      end;
      Counter0:=Counter0+1;
    end;
  end;

  if BIgnore then
  begin
    if (ParamStr(Counter0-1)='-v') or (NasmCmd='-v') then
      writeln('NasmPlus v0.01 by Kandu')
    else if (ParamStr(Counter0-1)='-h') or (NasmCmd='-h') then
      {$IFDEF Windows}
        exec('cmd','/c type '+MainDir+'help\nasmplushelp.txt');
      {$ELSE}
        fpSystem('cat '+MainDir+'help/nasmplushelp.txt');
      {$ENDIF}
    {$IFDEF Windows}
      exec('cmd','/c nasm '+ParamStr(Counter0-1));
    {$ELSE}
      fpSystem('nasm '+ParamStr(Counter0-1));
    {$ENDIF}
  end else
  begin
    //现在开始真正的预处理阶段……
    //writeln('pretreating');

    if FileExist(ParamStr(1)) then
    begin
      InitPretreatment(ParamStr(1));	//初始化预处理环境
      if DoPretreatment then		//预处理并返回结果
      begin
        writeln('OK :) , assembling...');        
        CreateTempFile;
        {$IFDEF Windows}		//若预处理成功则调用NASM汇编预处理后的文件
          exec('cmd','/c nasm '+NasmCmd);
        {$ELSE}
          fpSystem('nasm '+NasmCmd);
        {$ENDIF}
      end else
      begin
        writeln('Failed :( , check your source code');
      end;
      CleanPretreatment;		//完成一些善后工作
    end else
    begin
      writeln('File dose not exist');
    end;
  end;
end.

