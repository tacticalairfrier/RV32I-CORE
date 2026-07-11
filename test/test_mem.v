`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//this memory testing function will grow until every case is covered
module test_mem;
//testing the readmemh fxn
reg [31:0] address_dat_tb, address_inst_tb, dataword_tb;
reg clk;
reg dat_rw;
wire [31:0] outword_inst_tb, datwordout_tb;
initial begin 
    clk = `FALSE;
end
always #5 clk = ~clk;
memory M_T_0(
    .address_inst(address_inst_tb),
    .address_dat(address_dat_tb),
    .datawordin(dataword_tb),
    .clkin(clk),
    .dat_rw(dat_rw),
    .instword(outword_inst_tb),
    .datwordout(datwordout_tb)
);
integer i;
initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,test_mem);
address_inst_tb = 32'h0;
for(i=0;i<32;i=i+1)begin
    $display("the word in instruction mem is this %h", outword_inst_tb);
    #10;
    address_inst_tb = address_inst_tb+4;
end
$finish;
end
endmodule