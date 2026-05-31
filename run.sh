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

echo "Running $MODE-instrumented file..."
total_time=0
total_mem=0
iterations=10

time_list=()
mem_list=()

echo "--------------------------------------"
echo "Individual Runs:"

for i in $(seq 1 $iterations); do
    stats=$( { gtime -f "%e %M" ./build/driver.exe > /dev/null; } 2>&1 )
    
    elapsed=$(echo "$stats" | awk '{print $1}')
    mem=$(echo "$stats" | awk '{print $2}')
    
    time_list+=("$elapsed")
    mem_list+=("$mem")
    
    echo "  Run #$i: Time: ${elapsed}s | Memory: (${mem} KB)"
    
    total_time=$(echo "$total_time + $elapsed" | bc)
    total_mem=$((total_mem + mem))
done

sorted_times=($(printf '%s\n' "${time_list[@]}" | sort -n))
sorted_mems=($(printf '%s\n' "${mem_list[@]}" | sort -n))

if (( iterations % 2 == 1 )); then
    mid=$(( iterations / 2 ))
    median_time="${sorted_times[$mid]}"
    median_mem="${sorted_mems[$mid]}"
else
    mid_high=$(( iterations / 2 ))
    mid_low=$(( mid_high - 1 ))
    median_time=$(echo "scale=4; (${sorted_times[$mid_low]} + ${sorted_times[$mid_high]}) / 2" | bc)
    median_mem=$(echo "(${sorted_mems[$mid_low]} + ${sorted_mems[$mid_high]}) / 2" | bc)
fi

avg_time=$(echo "scale=4; $total_time / $iterations" | bc)
avg_mem=$(echo "scale=2; $total_mem / $iterations" | bc)

echo "--------------------------------------"
echo "Performance Summary ($MODE mode, $iterations runs):"
echo "  Average Time:   $avg_time seconds"
echo "  Average Memory: ($avg_mem KB)"
echo "  Median Time:    $median_time seconds"
echo "  Median Memory:  ($median_mem KB)"
echo "--------------------------------------"

echo "Done!"
