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
    input wire [31:0] gpio_in,
    input wire [1:0] dat_rw,
    input wire clkin,
    output reg [31:0] instword,
    output wire [31:0] datwordout,
    output wire [31:0] gpio_out
);
//4 kilobyte instuction memory i.e ~1000 instructions can be stored approx
//4 kb data memory to have apt sram
// reg [7:0] ins_mem [0:4095]; //4095
// reg [7:0] dat_mem [0:4095];
reg [31:0] ins_mem [0:1023];
reg [31:0] dat_mem [0:1023];
reg [31:0] gpio_mmio_in; //ONLY FOR READS
reg [31:0] gpio_mmio_out; //ONLY FOR WRITES
reg [31:0] mem_write_reg;
reg [31:0] gpio_write_reg;
wire [3:0] memcode;
//continuous assignments
assign memcode = {address_dat[12], address_dat[2], dat_rw};
assign gpio_out = gpio_mmio_out;
assign datwordout = (memcode == 4'b0010||memcode == 4'b0110)?(mem_write_reg):(gpio_write_reg);
//map 0x0000->0x0fff = general data, 0x1000->0x1004 = gpio_in, gpio_out 
//putting the firmware inside the ins_mem
//not possible in asic only for yosys/vivado
initial begin
    //readmemh for firmware
    $readmemh("firmware.hex", ins_mem);
end
always@(posedge clkin)begin
    //defining the instword output right now
    //lil endian thing changed back into big endian for just the instruction memory
    // instword <= {ins_mem[address_inst+3], ins_mem[address_inst+2], ins_mem[address_inst+1], ins_mem[address_inst]};
    instword <= ins_mem[{2'b00, address_inst[31:2]}];    //dat_rw data given as is\
    //gpio mmio input latches on every clock cycle to the gpio input wires
    //rw = 1 means write requested
    //dat_rw = 10 = read
    //dat_rw = 01 = write
    // {dat_mem[address_dat+3], dat_mem[address_dat+2], dat_mem[address_dat+1], dat_mem[address_dat]}
    // {dat_mem[address_dat+3], dat_mem[address_dat+2], dat_mem[address_dat+1], dat_mem[address_dat]};
    if(dat_rw == 2'b01) dat_mem[address_dat[11:2]] <= datawordin; //write
    if(dat_rw == 2'b10) mem_write_reg <= dat_mem[address_dat[31:2]]; //read
    //rw = 0 means read requested
    // case(memcode)
    //     4'b0001, 4'b0101: dat_mem[{2'b00, address_dat[31:2]}] <= datawordin; //write
    //     4'b0010, 4'b0110: mem_write_reg <= dat_mem[{2'b00, address_dat[31:2]}]; //read
    //     4'b1010: gpio_write_reg <= gpio_mmio_in; //read from gpio
    //     4'b1101: gpio_mmio_out <= datawordin; //write to gpio
    //     default: ;
    // endcase
end
always@(posedge clkin)begin
    gpio_mmio_in <= gpio_in;
    if(memcode == 4'b1010) gpio_write_reg <= gpio_mmio_in; //read from gpio
    if(memcode == 4'b1101) gpio_mmio_out <= datawordin; //write to gpio
end
// always@(*)begin
//     if(memcode == 4'b0010||memcode == 4'b0110) datwordout = mem_write_reg;
//     if(memcode == 4'b1010) datwordout = gpio_write_reg;
// end
endmodule
