//every memory bit lives here
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//3 things in memory
//1 data memory
//2 instruction memory
//all the mmio peripherals will live here
module memory(
    input wire [31:0] address_inst,
    input wire [31:0] address_dat,
    input wire [31:0] datawordin,
    input wire clkin,
    input wire dat_rw,
    output reg [31:0] instword,
    output reg [31:0] datwordout
);
//4 kilobyte instuction memory i.e ~1000 instructions can be stored approx
//4 kb data memory to have apt sram
reg [7:0] ins_mem [0:4095];
reg [7:0] dat_mem [0:4095];
//putting the firmware inside the ins_mem
//ts not possible in asic onli for da yosys/vivado
initial begin
    //readmemh 
    $readmemh("firmware.hex", ins_mem);
end
always@(posedge clkin)begin
    //defining the instword output right now
    //lil endian thing changed back into big endian for just the instruction memory
    instword <= {ins_mem[address_inst+3], ins_mem[address_inst+2], ins_mem[address_inst+1], ins_mem[address_inst]};
    //dat_rw data given as is
    //rw = 1 means write requested
    if(dat_rw) {dat_mem[address_dat+3], dat_mem[address_dat+2], dat_mem[address_dat+1], dat_mem[address_dat]} <= datawordin;
    else datwordout <= {dat_mem[address_dat+3], dat_mem[address_dat+2], dat_mem[address_dat+1], dat_mem[address_dat]};
    //rw = 0 means read requested
end
endmodule
