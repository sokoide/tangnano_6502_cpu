#!/bin/sh
# Report success only when the programmer exits successfully and reports Finished.
set -u
if [ "$#" -ne 3 ]; then
    echo "usage: program_fpga.sh PROGRAMMER DEVICE BITSTREAM" >&2
    exit 2
fi
programmer=$1
device=$2
bitstream=$3
log=$(mktemp "${TMPDIR:-/tmp}/tangnano-program.XXXXXX") || exit 1
trap 'rm -f "$log"' EXIT HUP INT TERM
"$programmer" --device "$device" --fsFile "$bitstream" --operation_index 2 >"$log" 2>&1
result=$?
cat "$log"
if [ "$result" -ne 0 ] || grep -qi 'error:' "$log" || ! grep -Eq '^[[:space:]]*Finished\.?[[:space:]]*$' "$log"; then
    echo "[ERROR] Programmer did not report a successful completion (exit=$result)" >&2
    exit 1
fi
