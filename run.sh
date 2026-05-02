#!/bin/sh

CC=${CC:-clang}
MODE=${MODE:-c}
RUNTIME_PREFIX=$OPAM_SWITCH_PREFIX/lib/cn/runtime

mkdir -p build

echo "--- Mode: $MODE ---"

$CC -E -P -CC driver.c > driver.pp.c

LUA_FLAG=""

[[ "$MODE" = "lua" ]] && LUA_FLAG="--experimental-lua-runtime"

cn instrument ./driver.pp.c \
    --output=driver.pp.exec.c \
    --output-dir=build \
    --without-lemma-checks \
    --without-loop-invariants \
    --exec-c-locs-mode \
    $LUA_FLAG

echo "Compiling ($MODE)..."

INC="-I$RUNTIME_PREFIX/include"
[[ "$MODE" = "lua" ]] && INC="$INC -I$RUNTIME_PREFIX/include/cn-lua"

$CC -g -c -O0 -std=gnu11 $INC $FLAGS build/driver.pp.exec.c -o build/driver.pp.exec.o

echo "Linking ($MODE)..."
if [ "$MODE" = "lua" ]; then
    $CC build/driver.pp.exec.o \
        -L $RUNTIME_PREFIX -lcn_exec -lcn_lua -ldl -lm \
        -o build/driver.exe
else
    $CC build/driver.pp.exec.o \
        $RUNTIME_PREFIX/libcn_exec.a \
        -L $RUNTIME_PREFIX -lcn_exec \
        -o build/driver.exe
fi

echo "Running $MODE-instrumented driver..."
for i in $(seq 1 10); do
    gtime -f "~%e~%M" ./build/driver.exe
done

echo "Done!"
