#!/bin/sh

CC=${CC:-clang}
CCFLAGS='-g -c -O0 -std=gnu11'
MODE=${MODE:-c}
RUNTIME_PREFIX=$OPAM_SWITCH_PREFIX/lib/cn/runtime
[[ $MODE == lua ]] && LUA=1

mkdir -p build

echo "--- Mode: $MODE ---"

$CC -E -P -CC driver.c > driver.pp.c

LUACNFLAGS='--experimental-lua-runtime'
cn instrument ./driver.pp.c \
    --output=driver.pp.exec.c \
    --output-dir=build \
    --without-lemma-checks \
    --without-loop-invariants \
    --exec-c-locs-mode \
    ${LUA:+$LUACNFLAGS}

echo "Compiling ($MODE)..."
$CC $CCFLAGS -I$RUNTIME_PREFIX/include build/driver.pp.exec.c -o build/driver.pp.exec.o

echo "Linking ($MODE)..."
LUALIBS='-lcn_lua -lm'
$CC build/driver.pp.exec.o -L$RUNTIME_PREFIX -lcn_exec ${LUA:+$LUALIBS} -o build/driver.exe

echo "Running $MODE-instrumented driver..."
for i in $(seq 1 10); do
    gtime -f "~%e~%M" ./build/driver.exe
done

echo "Done!"
