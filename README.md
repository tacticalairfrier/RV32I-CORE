# RV32I-CORE

A multicycle RV32I RISC-V CPU core written in Verilog, built from scratch as a hands-on exercise in computer architecture and RTL design — golden-model-first, with a hand-written C reference model used for differential checking against the RTL.

> **Status: early bring-up, not verified for general use.** A subset of the instruction set has been exercised against the reference model and confirmed working. The rest of the RV32I opcode map is decoded and implemented in RTL but has not yet been run through a compliance suite or formal tool. See [Verification status](#verification-status) below before relying on this core for anything beyond experimentation.

## Architecture

- **Multicycle FSM core.** Every instruction moves through some subset of six states: `RESET → FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK → FETCH`. Simpler instructions (e.g. register-immediate ALU ops) skip `MEMORY`; loads, stores, and branches route through it.
- **Harvard memory layout.** Separate instruction and data memories, each 4 KB (`ins_mem` / `dat_mem` in `memory.v`), byte-addressed and stitched into 32-bit words on access.
- **Little-endian** byte ordering for both instruction fetch and load/store.
- **31-entry register file** (`registerfile[0:31]`), with `x0` forced to zero on every write.
- Program firmware is loaded into instruction memory via `$readmemh` from `firmware.hex` at elaboration time (simulation-only path).

### Modules

| File | Purpose |
|---|---|
| `src/core.v` | Top-level multicycle FSM: fetch, decode, execute, memory, writeback |
| `src/alu.v` | Combinational ALU — add/sub, shifts (logical + arithmetic), compare (signed/unsigned), bitwise ops |
| `src/memory.v` | Instruction + data memory, byte-addressed with 4-byte little-endian reassembly |

## Instruction support

The decoder recognizes the full base opcode map (`LUI`, `AUIPC`, `JAL`, `JALR`, `BRANCH`, `LOAD`, `STORE`, register-immediate and register-register ALU ops, `FENCE`, `ECALL`). `FENCE` and `ECALL` currently decode as no-ops rather than doing anything functional.

`ref/verified_instructions.txt` lists an initial verified set (`lui`, `addi`, `add`, `xor`, `sub`, `and`, `or`, `sw`, `sb`, `sh`, `xori`), but that file hasn't been touched since the first commit — later work (branch conditions, `jalr`) has been tested since without the file being kept in sync, so treat it as a historical snapshot, not the current verified set.

There is currently no single up-to-date source of truth for "what's actually verified." That list either needs to be maintained going forward or replaced by a proper regression suite (arch-test / coverage-driven random testing, see below) that doesn't depend on remembering to hand-edit a text file every time something new gets tested.

**Not implemented:** M extension (mul/div), compressed instructions, CSRs, interrupts/traps, misaligned access handling.

## Repo layout

```
src/
  core.v      — FSM core
  alu.v       — ALU
  memory.v    — instruction/data memory
test/
  test_core_basic.v — basic FSM/instruction-stream testbench (waveform dump, no assertions)
  alu_test.v         — ALU-only testbench
  test_mem.v         — memory module testbench
ref/
  rv32i_ref.c              — golden C reference model / ISS
  verified_instructions.txt — instructions confirmed against the reference model so far
firmware.hex  — test program loaded into instruction memory at sim time
```

## Running the simulation

These testbenches are plain Verilog (`$dumpfile`/`$dumpvars`, no UVM/assertion framework), so any standard simulator works. With Icarus Verilog:

```bash
# core testbench
iverilog -o sim_core src/core.v src/alu.v src/memory.v test/test_core_basic.v
vvp sim_core
gtkwave sim.vcd

# ALU-only testbench
iverilog -o sim_alu src/alu.v test/alu_test.v
vvp sim_alu

# memory-only testbench
iverilog -o sim_mem src/memory.v test/test_mem.v
vvp sim_mem
```

`firmware.hex` must be present in the working directory the simulator is run from (`memory.v` loads it via a relative path), That is the repository root folder


## Verification status

Right now, correctness has been established by manually inspecting waveforms from `test_core_basic.v` and by differential-checking against the C reference model on an ad-hoc basis, tracked loosely through commit messages rather than a maintained record. That's a reasonable bring-up milestone, but it isn't exhaustive — it only covers instructions and operand values someone thought to test, and there's no current single file or suite that says definitively what has and hasn't been checked.

Planned next steps for this repo:
- Run the [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test) compliance suite against the core
- Constrained-random instruction generation with functional coverage closure, still diffed against the reference model
- Formal verification via [riscv-formal](https://github.com/YosysHQ/riscv-formal) (SymbiYosys/Yosys), once an RVFI-compliant retirement interface is added to `core.v`

## Physical Implementation Testing

- As of now the design is still being tested in software, that is being tested and run on real FPGA sillicon -> therefore this design will be tested on 2 FPGAs `ICE40UP5K` and `XC7A35T-1CPG236C`.
- Will add More findings about the FPGA impmementation in this section.

## What have I learnt

1. Even though it is a basic and minimal implementation, it has given me insight into computer architecture.
2. Got Hands on experience with RISCV and its ISA along with the build systems it uses.
3. Got indepth and hands on experience with Computer architecture and instructionsets.
4. Got hands on experience with riscv-32i assembly language.

## License

MIT — see `LICENSE`.
