# Define project-specific variables
TOP=top
PCF_FILE=constraints
BOARD_FREQ=12
CPU_FREQ=12
FPGA_VARIANT=up5k
FPGA_PACKAGE=sg48
NTHREADS=$(shell nproc)
VERILOG_FILE=top.v core.v alu.v memory.v
# riscv assembly compile
compile: code.S
	riscv64-unknown-elf-as -march=rv32 -mabi=ilp32 code.S -o code.o
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0x0 -e _main code.o -o firmware.elf
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width 4 firmware.elf firmware.hex
build: firmware.hex
	time yosys -DCPU_FREQ=$(CPU_FREQ) -p "synth_ice40 -abc9 -device u -dsp -top $(TOP) -json $(TOP).json" $(VERILOG_FILE)
	time nextpnr-ice40 --force --json $(TOP).json --pcf $(PCF_FILE).pcf --asc $(TOP).asc --freq $(BOARD_FREQ) --$(FPGA_VARIANT) --package $(FPGA_PACKAGE) --opt-timing --threads $(NTHREADS)
	time icetime -p $(PCF_FILE).pcf -P $(FPGA_PACKAGE) -r $(TOP).timings -d $(FPGA_VARIANT) -t $(TOP).asc
	time icepack -s $(TOP).asc $(TOP).bin

flash:
	time iceprog $(TOP).bin

clean:
	rm -rf $(TOP).blif $(TOP).asc $(TOP).bin $(TOP).json $(TOP).timings firmware.elf firmware.hex code.o
