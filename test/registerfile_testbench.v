`timescale 1ns / 1ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//testbench for testing how the 
module testbench;
reg clkin;
reg [4:0] rs1, rs2, rd;
reg write_enable, read_enable;
reg [31:0] return_rd;
reg [31:0] rs1_mod, rs2_mod;
integer i;
//generating the clock pulse
always #10 clkin = ~clkin;
//registerfile is connected
registerfile REG(
    .rd_in(return_rd),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_enable(write_enable),
    .read_enable(read_enable),
    .rs1_mod(rs1_mod),
    .rs2_mod(rs2_mod),
    .clkin(clkin)
);
initial clkin = `FALSE;
initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,testbench);
    $dumpvars(0,REG.registerfile_rs1[4]);
    $dumpvars(0,REG.registerfile_rs2[4]);
    write_enable = `FALSE;
    read_enable = `FALSE;
    rd = 5'b00100;
    return_rd = 32'habcd1234;
    #10;
    write_enable = `TRUE;
    //WRITING sm to the registerfile
    #15;
    write_enable = `FALSE;
    #15;
    read_enable = `TRUE;
    rs1 = 5'b00100;
    rs2 = 5'b00100;
    #20;
    read_enable = `FALSE;
    #20;
    $finish;
end
endmodule