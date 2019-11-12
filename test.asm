#if #z?
	cld
#else
	cli
#end

#while #s>=(eax,[SomeData])
	add eax,2
#end

#repeat
	mov eax,[edi]
	add edi,4
#until #=(byte[edi],0)
SomeData:
	db 0
