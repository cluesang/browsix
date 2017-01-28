#!/bin/bash
set -e

FSROOT="./benchfs"
BIN="$FSROOT/usr/bin"
HBENCH="./bench/hbench-os"
SHROOT="./fs"
RESULTDIRB="results/browsix"

export CHROME_BIN='google-chrome-beta'

export EMCC_BROWSIX_ASYNC=1
export EMFLAGS='-Os'

#rm -rf "$HBENCH/bin/browsix-js"

(cd $HBENCH && emmake make PLATFORM=js-pc-browsix EXT=.js CC="emcc $EMFLAGS" CFLAGS="-static -DNO_PORTMAPPER")

# benchmarks to run
BENCHMARKS='lat_syscall lat_pipe lat_tcp lat_proc hello lat_fs lat_fslayer'

mkdir -p "$FSROOT/dev"
# fixme: this is a hack
touch "$FSROOT/dev/null"
mkdir -p "$BIN"

for b in $BENCHMARKS; do
	cp -a "$HBENCH/bin/browsix-js/$b.js" "$BIN/$b"
done

make bin

# copy in a few extra programs, mainly the shell
cp "$SHROOT/usr/bin/sh" "$BIN"

mkdir -p results

RESULTDIR="$RESULTDIRB.1"
while [ -d $RESULTDIR ]; do
    EXT=`expr $EXT + 1`
    RESULTDIR=$RESULTDIRB.$EXT
done

mkdir -p "$RESULTDIR"

node_modules/.bin/gulp bench >"$RESULTDIR/raw"

(cd "$HBENCH" && rm -rf Results/linux* && make && make run)

mv "$HBENCH/Results/linux-x86_64" "$RESULTDIR"

./analyze.sh "$RESULTDIR"
