# RV32I-CORE

A multicycle RV32I RISC-V CPU core written in Verilog, built from scratch as a hands-on exercise in computer architecture and RTL design — golden-model-first, with a hand-written C reference model used for differential checking against the RTL.

> **Status: early bring-up, not verified for general use.** A subset of the instruction set has been exercised against the reference model and confirmed working. The rest of the RV32I opcode map is decoded and implemented in RTL but has not yet been run through a compliance suite or formal tool. See [Verification status](#verification-status) before relying on this core for anything beyond experimentation.

## Architecture

- **Multicycle FSM core.** Every instruction moves through some subset of six states: `RESET → FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK → FETCH`. Simpler instructions (e.g. register-immediate ALU ops) skip `MEMORY`; loads, stores, and branches route through it.
- **Harvard memory layout.** Separate instruction and data memories, each 4 KB (`ins_mem` / `dat_mem` in `memory.v`).
- **Little-endian** byte ordering for both instruction fetch and load/store.
- **31-entry register file** (`registerfile[0:31]`), with `x0` forced to zero on every write.
- Program firmware is loaded into instruction memory via `$readmemh` from `firmware.hex` at elaboration time (simulation-only path).

### Memory word width — synthesizability fix

`ins_mem` / `dat_mem` were originally modeled as byte-wide arrays (one array element per byte, reassembled into 32-bit words on access). That's fine for simulation, but it doesn't map onto FPGA block RAM: BRAM primitives are word-addressed, and a byte-array model forces the synthesis tool into wide, inefficient byte-enable muxing logic instead of inferring a clean BRAM instance — on some toolchains it fails to infer BRAM at all and falls back to distributed/LUT RAM.

Both memories have since been changed to 32-bit wide word arrays, with `firmware.hex` generated for that width using `--verilog-data-width 4` (`objcopy`/`elf2hex`, depending on which is in your flow). This lets the synthesis tool cleanly infer BRAM on both target FPGAs instead of falling back to the byte-array model. Byte-addressed loads/stores (`LB`, `SB`, `SH`) are still supported — the byte/halfword slicing now happens on the read/write path into a word, rather than the memory array itself being byte-granular.

If you're regenerating `firmware.hex` from source, make sure your hex-generation step matches this width, or the core will load garbage instructions.

### Modules

| File | Purpose |
|---|---|
| `src/core.v` | Top-level multicycle FSM: fetch, decode, execute, memory, writeback |
| `src/alu.v` | Combinational ALU — add/sub, shifts (logical + arithmetic), compare (signed/unsigned), bitwise ops |
| `src/memory.v` | Instruction + data memory, word-addressed (32-bit wide), byte/halfword access on the load/store path |

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
  memory.v    — instruction/data memory (32-bit word-wide, BRAM-synthesizable)
test/
  test_core_basic.v — basic FSM/instruction-stream testbench (waveform dump, no assertions)
  alu_test.v         — ALU-only testbench
  test_mem.v         — memory module testbench
ref/
  rv32i_ref.c              — golden C reference model / ISS
  verified_instructions.txt — instructions confirmed against the reference model so far (stale, see above)
memdump/
  memory.txt      — RTL's word-wise memory dump for a run
  memory_ref.txt  — C reference model's word-wise memory dump for the same run (diffed against memory.txt)
  trace.txt       — C reference model's full per-cycle pc/instruction/register trace + final memory image
firmware.hex  — test program loaded into instruction memory at sim time (32-bit word width, generated with --verilog-data-width 4)
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

`firmware.hex` must be present in the working directory the simulator is run from (`memory.v` loads it via a relative path) — that is the repository root folder. Make sure it was generated at 32-bit word width (`--verilog-data-width 4`); a byte-width hex file will not load correctly into the current memory model.

## `memdump/`

Output artifacts from a differential-testing run, used to compare the RTL against the golden C reference model:

| File | Contents |
|---|---|
| `memory.txt` | Word-wise (32-bit) memory dump produced by the **RTL** simulation at the end of a run. Unwritten/unreached locations show as `x` (unknown) rather than a defined value. |
| `memory_ref.txt` | Word-wise memory dump produced by the **C reference model** (`rv32i_ref.c`) for the same run. This is the file `memory.txt` is diffed against. |
| `trace.txt` | Full per-cycle execution trace from the **C reference model**: the loaded instruction memory image, followed by, for every retired instruction, the `pc`, the raw instruction word, and a full register-file snapshot after that instruction executes. Ends with the model's final byte-wise memory image. |

`memory.txt` vs `memory_ref.txt` is the actual pass/fail check for a run — a mismatch anywhere means the RTL diverged from the reference model. `trace.txt` is the debug aid for *where* it diverged: the register-file snapshots let you walk instruction-by-instruction through the reference model's execution and compare against the RTL waveform to find the exact cycle where behavior split.

## Verification status

This core was built golden-model-first: `ref/rv32i_ref.c` is a hand-written C reference model / ISS, and every instruction that's been exercised so far has been differentially checked against it, not just eyeballed for "looks about right." Correctness so far rests on two legs — waveform inspection from `test_core_basic.v`, and instruction-by-instruction diffing of RTL execution against the reference model, concretely captured in `memdump/`: the RTL's memory dump (`memory.txt`) is compared word-for-word against the reference model's memory dump (`memory_ref.txt`) for the same run, and when the two disagree, the reference model's full per-cycle pc/instruction/register trace (`trace.txt`) is used to pin down the exact instruction where RTL execution diverged from the golden model.

That's a real verification discipline, not just ad-hoc poking — but it's still bring-up-stage, not sign-off-stage. Right now the diff-and-trace comparison itself is a manual step (run the sim, generate both dumps, diff them, eyeball the trace on a mismatch) rather than an automated regression check, and coverage is bounded by which instructions and operand values someone thought to run through the reference model, tracked loosely through commit history rather than a maintained record — so there's no single file or suite yet that states definitively what has and hasn't been checked. Closing that gap — scripting the dump/diff/trace-lookup into an automatic pass/fail, and making coverage legible and exhaustive — is exactly what the next steps below are for.

Planned next steps for this repo:
- Run the [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test) compliance suite against the core
- Constrained-random instruction generation with functional coverage closure, still diffed against the reference model
- Formal verification via [riscv-formal](https://github.com/YosysHQ/riscv-formal) (SymbiYosys/Yosys), once an RVFI-compliant retirement interface is added to `core.v`
  
## Physical Implementation

Bring-up on real FPGA silicon is underway, targeting two devices:
`ICE40UP5K` and `XC7A35T-1CPG236C`. The memory-width change above was made
specifically to get clean BRAM inference on both of these targets.

### Bring-up findings (preliminary)

- **Basys3 (XC7A35T-1CPG236C):** 1684 LUTs. BRAM successfully inferred for
  both imem and dmem.
- **iCE40UP5K:** 3063 LUTs. BRAM inferred for both imem and dmem as well.
  The register file (sync-write, async-read) is a no-op for Vivado, which
  maps it to cheap LUTRAM/distributed RAM without complaint. yosys/nextpnr
  targeting iCE40 does not infer LUTRAM as readily for that async-read
  pattern, so the async-read 31-entry register file was instead getting
  expanded into a wide mux tree plus discrete FFs, driving LUT usage up to
  ~4200. Cutting to RV32E (16 registers) shrank the async-read mux width
  enough to bring this down to 3063 LUTs. Settled on RV32E on this target
  for the time being.
- Wrote a small LED-blink program in assembly and tested it on both boards
  (`assembly/blink.asm`).

Resource utilization, timing closure, and full BRAM inference reports will
be added here as bring-up progresses.

## What I've learnt

1. Even a basic, minimal implementation gives real insight into computer architecture — decisions that look trivial on paper (like memory array width) have concrete synthesis consequences.
2. Hands-on experience with the RISC-V ISA and its associated build/toolchain ecosystem.
3. In-depth, practical experience with computer architecture and instruction set design.
4. Hands-on experience with RV32I assembly.

## License

MIT — see `LICENSE`.
