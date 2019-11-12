#The encoding of these files is UTF-8, if you can not read the words below, try select UTF-8 as the default encoding of your text reader.


PC := fpc
PFLAGS := -I out -o

prefix := $(HOME)


ifeq (Windows, $(OS))
  SEPARATOR := \ 
  TARGET := NasmPlus.exe 
  PFLAGS := -dWindows $(PFLAGS)
  CMD_CLEAN := del
  BREAK := &
else
  SEPARATOR := / 
  TARGET := NasmPlus
  PLAGS := $(PFLAGS)
  CMD_CLEAN := rm -f
  BREAK := ;
endif
SEPARATOR := $(strip $(SEPARATOR))
DELTARGET := out$(SEPARATOR)$(TARGET)
TARGET := out/$(TARGET)


.PHONY: clean

everything: $(TARGET)

clean:
	cd out$(BREAK)$(CMD_CLEAN) *.o *.ppu$(BREAK)
distclean: clean
	$(CMD_CLEAN) $(DELTARGET)$(BREAK)

all: distclean everything

PART := NasmPlus.pas out/pretreatment.o out/SubPnt.o out/expand.o out/order.o out/transform.o

install: everything
	mkdir -p $(prefix)/bin
	install $(target) $(prefix)/bin/

$(TARGET):$(PART)
	$(PC) $(PFLAGS)$@ $<

out/%.o:%.pas
	$(PC) $(PFLAGS)$@ $<

