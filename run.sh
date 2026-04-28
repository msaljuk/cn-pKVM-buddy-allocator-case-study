CC=${CC:-clang}
MODE=${MODE:-c}
RUNTIME_PREFIX=$OPAM_SWITCH_PREFIX/lib/cn/runtime

mkdir -p build

echo "--- Mode: $MODE ---"

$CC -E -P -CC driver.c > driver.pp.c

LUA_FLAG=""

if [ "$MODE" = "lua" ]; then
    LUA_FLAG="--experimental-lua-runtime"

    echo "Building Lua source: make -C $RUNTIME_PREFIX/lua/src liblua.a"
    make -C "$RUNTIME_PREFIX/lua/src" liblua.a || { echo "Failed to build Lua source"; exit 1; }

    echo "Building Lua cn wrappers: make -C $RUNTIME_PREFIX/lua/cn lua_wrappers.a"
    make -C "$RUNTIME_PREFIX/lua/cn" lua_wrappers.a || { echo "Failed to build Lua cn wrappers"; exit 1; }
fi

cn instrument ./driver.pp.c \
    --output=driver.pp.exec.c \
    --output-dir=build \
    --without-lemma-checks \
    --without-loop-invariants \
    --exec-c-locs-mode \
    $LUA_FLAG

echo "Compiling ($MODE)..."
INC="-I$RUNTIME_PREFIX/include"
if [ "$MODE" = "lua" ]; then
    INC="$INC -I$RUNTIME_PREFIX/lua/src -I$RUNTIME_PREFIX/lua/cn"
fi

$CC -g -c -O0 -std=gnu11 $INC build/driver.pp.exec.c -o build/driver.pp.exec.o

echo "Linking ($MODE)..."
if [ "$MODE" = "lua" ]; then
    LUA_LIBS="$RUNTIME_PREFIX/lua/src/liblua.a $RUNTIME_PREFIX/lua/cn/lua_wrappers.a"
    $CC build/driver.pp.exec.o \
        $RUNTIME_PREFIX/libcn_exec.a \
        $LUA_LIBS \
        -ldl -lm \
        -o build/driver.exe
else
    $CC build/driver.pp.exec.o \
        $RUNTIME_PREFIX/libcn_exec.a \
        -L $RUNTIME_PREFIX -lcn_exec \
        -o build/driver.exe
fi

echo "Running $MODE-instrumented driver..."
for i in $(seq 1 10);
do
    gtime -f "~%e~%M" ./build/driver.exe
done

echo "Done!"