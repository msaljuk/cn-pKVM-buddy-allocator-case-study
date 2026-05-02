CC = clang
CFLAGS = -g -O0 -std=gnu11

BUILD = build
INCLUDES = stddef.h posix_types.h getorder.h

CNFLAGS = --without-lemma-checks --without-loop-invariants --exec-c-locs-mode
CNLUAFLAGS = --experimental-lua-runtime 

CFLAGS += -I$(OPAM_SWITCH_PREFIX)/lib/cn/runtime/include
LIBS = -L$(OPAM_SWITCH_PREFIX)/lib/cn/runtime -lcn_exec
LUALIBS = -lcn_lua -lm


.PHONY: clean run

run: $(BUILD)/driver.exe
	$<

$(BUILD)/driver.pp.c: driver.c page_alloc.c $(INCLUDES)
	mkdir -p $(BUILD)
	$(CC) -E -P -CC $< > $@

$(BUILD)/driver.pp.exec.c: $(BUILD)/driver.pp.c
	cn instrument $< --output=driver.pp.exec.c --output-dir=$(BUILD) $(CNFLAGS)
	mv $@ $@~
	sed -e"/ cerb::hidden .*bswap64/d" < $@~ > $@

$(BUILD)/driver.pp.lua.c: $(BUILD)/driver.pp.c
	cn instrument $< --output=driver.pp.lua.c --output-dir=$(BUILD) $(CNFLAGS) $(CNLUAFLAGS)
	mv $@ $@~
	sed -e"/ cerb::hidden .*bswap64/d" < $@~ > $@

$(BUILD)/driver.pp.exec.o: $(BUILD)/driver.pp.exec.c
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD)/driver.pp.lua.o: $(BUILD)/driver.pp.lua.c
	$(CC) -c $(CFLAGS) $< -o $@

$(BUILD)/driver.pp.lua.o: $(BUILD)/driver.pp.lua.c
	$(CC) -g -c -O0 -std=gnu11 -I$(OPAM_SWITCH_PREFIX)/lib/cn/runtime/include -I$(OPAM_SWITCH_PREFIX)/lib/cn/runtime/include/cn-lua $< -o $@

$(BUILD)/driver.exe: $(BUILD)/driver.pp.exec.o
	$(CC) $< -o $@ $(LIBS)

$(BUILD)/driver.lua.exe: $(BUILD)/driver.pp.lua.o
	$(CC) $< -o $@ $(LIBS) $(LUALIBS)

clean:
	rm -rf $(BUILD)
