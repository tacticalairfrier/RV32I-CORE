`timescale 1 ns/1 ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module test_rv32i_basic;
reg clkin, reset;
wire [2:0] state;
wire [1:0] flags;
integer i;
core RV32I_00(
    .clkin(clkin),
    .reset(reset),
    .state_out(state),
    .flags(flags)
);
always #5 clkin = ~clkin;
initial begin
    clkin = `FALSE;
    reset = `FALSE;
    #40 reset = `TRUE;
end
initial begin
    $dumpfile("sim.vcd");
    //dumping of all the variables that exist here
    $dumpvars(0, test_rv32i_basic);
    for(i=0;i<32;i=i+1)begin
        $dumpvars(0, RV32I_00.registerfile[i]);
    end
    for(i=0;i<40;i=i+1)begin
        $dumpvars(0, RV32I_00.MEM_0.dat_mem[i]);
    end
    #3000;
    $finish;
end
endmodule