`default_nettype none 
`define TRUE 1'b1
`define FALSE 1'b0

module alu(
    input wire [31:0] oper_a, oper_b,
    input wire [3:0] opcode,
    output reg [31:0] result,
    //flags C,Z,N,O -> negitive, overflow
    output reg [1:0] flags, 
);
//assign the opcodes using localparams
//keeping the related operations close by in the opcode to save on the decode logic
//list of possible actions here
//shifts
//sll, srr, sra
//add sub
// slt, sltu, equality
// xor or and 
// total of 11 opc
localparam 
//keeping the shifters and equality with leading 1
SLL = 4'h8,
SRR = 4'h9,
SRA = 4'ha,
EQL = 4'hb,
SLT = 4'hc,
SLTU = 4'hd
ADD = 4'h7,
SUB = 4'h6,
AND = 4'h5, 
OR = 4'h4,
XOR = 4'h3;
always@(*)begin
    flags = 2'b00;
    case(opcode)
    //unsigned operations arent negitive/positive i.e bitwise so no allocation to them
    XOR: result = oper_a ^ oper_b;
    OR: result = oper_a | oper_b;
    AND: result = oper_a & oper_b;
    ADD:begin
        {flags[0], result} = oper_a + oper_b;
        flags[1] = result[31];
    end
    SUB:begin
        result = oper_a - oper_b;
        flags[1] = result[31];
    end
    SLL:begin
        result = oper_a << oper_b[4:0];
        flags[1] = result[31];
    end
    SRR: result = oper_a >> oper_b[4:0];
    SRA: begin
        result = oper_a >>> oper_b[4:0];
        flags[1] = result[31];
    end
    EQL: result = (oper_a==oper_b);
    SLT: result = ($signed(oper_a) < $signed(oper_b));
    SLTU: result = (oper_a < oper_b);
    endcase
end
endmodule