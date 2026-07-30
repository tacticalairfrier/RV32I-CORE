# AI Disclosure

This repo uses AI tools for specific, limited purposes. This document states exactly where and how, so it doesn't need to be guessed at from commit history.

## What AI was used for

| Artifact | AI tool | What it did |
|---|---|---|
| `generate_h_file.sh` | Gemini | Wrote the script. Converts a memory-dump hex file into a C header (`firmware.h`) with word/byte counts and the instruction array. See the disclosure comment at the top of the script itself. |
| `firmware.h` | Gemini (indirect) | Generated output of `generate_h_file.sh`, not hand-written. |
| `README.md` | Claude | Co-authored. Drafting, structure, and wording passes were done with AI help; the underlying facts (architecture decisions, bug fixes, verification methodology, etc.) come from the author and were reviewed/corrected by the author before being committed. |

AI tools were also used for ordinary conceptual/toolchain Q&A during development (e.g General syntactical doubts and conceptual/toolchain doubts), in the way any reference material would be; this didn't produce any code or content in the repo.

## What AI was *not* used for

- **RTL** (`src/core.v`, `src/alu.v`, `src/memory.v`) — hand-written, no AI-generated code.
- **Testbenches** (`test/test_core_basic.v`, `test/alu_test.v`, `test/test_mem.v`) — hand-written, no AI-generated code.
- **The C reference model** (`ref/rv32i_ref.c`) — hand-written, no AI-generated code.
