#!/bin/bash
# AI USE DISCLOSURE: GEMINI AI WAS USED TO GENERATE THIS FIRMWARE -> TO -> .H CONVERTER
# Usage check
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_memory_dump.hex>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="firmware.h"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

# 1. Strip comments, clear empty lines, and read all hex tokens into a Bash array
HEX_TOKENS=($(sed 's/\/\/.*//g' "$INPUT_FILE" | tr -d '\r'))

# 2. Compute byte count
TOTAL_BYTES=${#HEX_TOKENS[@]}

# 3. Format the array items with 0x prefix, 16 per line
FORMATTED_BYTES=""
COUNT=0

for token in "${HEX_TOKENS[@]}"; do
    FORMATTED_BYTES+="0x${token}, "
    COUNT=$((COUNT + 1))
    if [ $((COUNT % 16)) -eq 0 ]; then
        FORMATTED_BYTES+=$'\n    '
    fi
done

# 4. Write to header file
cat << EOF > "$OUTPUT_FILE"
#ifndef FIRMWARE_H
#define FIRMWARE_H

#include <stdint.h>

// AI DISCLOSURE: AN AI GENERATED SCRIPT WAS USED TO GENERATE THIS PART OF THE CODE
// Total byte count
const uint32_t firmware_bytes_len = ${TOTAL_BYTES};

const uint8_t inst_arr[] = {
    ${FORMATTED_BYTES}
};

#endif // FIRMWARE_H
EOF

echo "Successfully converted '$INPUT_FILE' -> '$OUTPUT_FILE'"
echo "Stats: $TOTAL_BYTES bytes total"