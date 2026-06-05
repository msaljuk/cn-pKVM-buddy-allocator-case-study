#!/bin/sh

CC=${CC:-clang}
CCFLAGS='-g -c -O2 -std=gnu11'
ITERS=10

# rm -rf build/
mkdir -p build

$CC -E -P -CC driver-uninstr.c > build/driver-uninstr.pp.c
echo "Compiling..."
$CC $CCFLAGS -c build/driver-uninstr.pp.c -o build/driver-uninstr.pp.o
echo "Linking..."
$CC build/driver-uninstr.pp.o -o build/driver-uninstr.exe

echo "Running..."

printf "Time:\n"
hyperfine --runs $ITERS -N --warmup 2 "./build/driver-uninstr.exe"

mem_sum=0
for ((i=1; i<=ITERS; i++)); do
    mem=$(gtime -f "%M" ./build/driver-uninstr.exe 2>&1 > /dev/null)
    ((mem_sum += mem))
done
avg=$(echo "scale=2; $mem_sum / $ITERS" | bc)
printf "Memory (kb): %.2f\n" "$avg"

echo "Done!"
