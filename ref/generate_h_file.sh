#!/bin/bash
# AI USE DISCLOSURE: GEMINI AI WAS USED TO GENERATE THIS FIRMWARE -> TO -> .H CONVERTER

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

# 1. Extract non-comment hex tokens
HEX_TOKENS=($(sed 's/\/\/.*//g' "$INPUT_FILE" | tr -d '\r'))

# 2. Calculate word and byte counts
TOTAL_WORDS=${#HEX_TOKENS[@]}
TOTAL_BYTES=$((TOTAL_WORDS * 4))

# 3. Format words with 0x prefix, 4 words (128 bits) per line for clean readability
FORMATTED_WORDS=""
COUNT=0

for token in "${HEX_TOKENS[@]}"; do
    FORMATTED_WORDS+="0x${token}, "
    COUNT=$((COUNT + 1))
    if [ $((COUNT % 4)) -eq 0 ]; then
        FORMATTED_WORDS+=$'\n    '
    fi
done

# 4. Write to header file
cat << EOF > "$OUTPUT_FILE"
#ifndef FIRMWARE_H
#define FIRMWARE_H

#include <stdint.h>

// Total byte count & word count
const uint32_t firmware_bytes_len = ${TOTAL_BYTES};
const uint32_t firmware_words_len = ${TOTAL_WORDS};

const uint32_t inst_arr[] = {
    ${FORMATTED_WORDS}
};

#endif // FIRMWARE_H
EOF

echo "Successfully converted '$INPUT_FILE' -> '$OUTPUT_FILE'"
echo "Stats: $TOTAL_WORDS words ($TOTAL_BYTES bytes total)"