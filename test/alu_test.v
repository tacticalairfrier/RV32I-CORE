`timescale 1ns / 1ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module test_alu;
localparam SLL = 4'h8,
SRR = 4'h9,
SRA = 4'ha,
EQL = 4'hb,
SLT = 4'hc,
SLTU = 4'hd,
ADD = 4'h7,
SUB = 4'h6,
AND = 4'h5, 
OR = 4'h4,
XOR = 4'h3;
// module alu(
//     input wire [31:0] oper_a, oper_b,
//     input wire [3:0] opcode,
//     output reg [31:0] result,
//     //flags C,Z,N,O -> negitive, overflow
//     output reg [1:0] flags, 
// );
reg [31:0] oper_a_tb, oper_b_tb;
reg [3:0] opcode;
wire [31:0] result;
wire [1:0] flags;
integer i;
alu t_alu_0(
    .oper_a(oper_a_tb),
    .oper_b(oper_b_tb),
    .result(result),
    .opcode(opcode),
    .flags(flags)
);
//using fixed values 0x67676767 and 0xab6969cd
initial begin
    $dumpfile("sim.vcd");
    $dumpvars(0,test_alu);
    //cycling through every opcode
    oper_a_tb = 32'h67676767;
    oper_b_tb = 32'hab6969cd;
    opcode = XOR;
    for(i=0;i<=13;i=i+1)begin
        #10
        opcode = opcode +1;
    end
    $finish;
end
endmodule