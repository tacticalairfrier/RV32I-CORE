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
    input wire [2:0] storetype, storeloadec,
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
wire [31:0] mem_write_wire;
reg [31:0] ins_mem [0:1023];
// reg [31:0] dat_mem [0:1023];
reg [31:0] gpio_mmio_in;    //ONLY FOR READS
reg [31:0] gpio_mmio_out;   //ONLY FOR WRITES
reg [31:0] gpio_write_reg;
wire [3:0] memcode;
wire rw_correct;
fpgamem MEMBANK(
    .datain(datawordin),
    .dataout(mem_write_wire),
    .address(address_dat[15:0]),
    .storetype(storetype),
    .storeloadec(storeloadec),
    .clkin(clkin),
    .WR_EN(rw_correct)
); //fpga specific memory target
//continuous assignments
`ifdef TARGET_SIM_ICE40UP5K
//new memory map
//0x00000 -> 0x0ffff ice40 single port ram
//0x10000 -> gpiommio in, 0x10004 -> gpio memory out
assign memcode = {address_dat[16], address_dat[2], dat_rw};
assign gpio_out = gpio_mmio_out;
assign datwordout = (memcode == 4'b0010||memcode == 4'b0110)?(mem_write_wire):(gpio_write_reg);
assign rw_correct = (memcode == 4'b0001||memcode == 4'b0101);
`elsif TARGET_ICE40UP5K
assign memcode = {address_dat[16], address_dat[2], dat_rw};
assign gpio_out = gpio_mmio_out;
assign datwordout = (memcode == 4'b0010||memcode == 4'b0110)?(mem_write_wire):(gpio_write_reg);
assign rw_correct = (memcode == 4'b0001||memcode == 4'b0101);
`endif 
`ifdef TARGET_GENERIC
assign memcode = {address_dat[14], address_dat[2], dat_rw};
assign gpio_out = gpio_mmio_out;
assign datwordout = (memcode == 4'b0010||memcode == 4'b0110)?(mem_write_wire):(gpio_write_reg);
assign rw_correct = (memcode == 4'b0001||memcode == 4'b0101);
`endif 
//map 0x0000->0x0fff = general data, 0x1000->0x1004 = gpio_in, gpio_out 
//putting the firmware inside the ins_mem
//not possible in asic only for yosys/vivado
initial begin
    //readmemh for firmware
    $readmemh("firmware.hex", ins_mem);
end
always@(posedge clkin) instword <= ins_mem[{2'b00, address_inst[31:2]}];    //dat_rw data given as is\
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
