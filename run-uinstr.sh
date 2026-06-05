#!/bin/sh

CC=${CC:-clang}

# rm -rf build/
mkdir -p build

$CC -E -P -CC driver-uninstr.c > build/driver-uninstr.pp.c
echo "Compiling..."
$CC $CCFLAGS -c build/driver-uninstr.pp.c -o build/driver-uninstr.pp.o
echo "Linking..."
$CC build/driver-uninstr.pp.o -o build/driver-uninstr.exe

echo "Running..."
for i in $(seq 1 10);
do
    gtime -f ~%e~%M ./build/driver-uninstr.exe
done
echo "Done!"
