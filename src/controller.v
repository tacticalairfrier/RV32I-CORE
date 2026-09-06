`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//controller module
module controller(
    output wire [31:0] A,
    output wire [31:0] B,
    output wire [4:0] ALUopc,
    input wire [31:0] instword,
    input wire [31:0] rs1_src,
    input wire [31:0] rs2_src,
    input wire [2:0] state
);
    //controller module intentionally stays purely combinational
    //copying over the localparams from the core.v module
    localparam FETCH = 3'd0, DECODE = 3'd1, EXECUTE = 3'd2, MEMORY = 3'd3, WRITEBACK = 3'D4, RESET = 3'd5;
    localparam SLL = 4'h8, SRR = 4'h9, SRA = 4'ha, EQL = 4'hb, SLT = 4'hc, SLTU = 4'hd, ADD = 4'h7, SUB = 4'h6, AND = 4'h5, OR = 4'h4, XOR = 4'h3;
    localparam LUI = 7'h37, AUIPC = 7'h17, JAL = 7'h6f, JALR = 7'h67, BRANCH = 7'h63, LOAD = 7'h03, STORE = 7'h23, ARM_IMM = 7'h13, ARM_RR = 7'h33, FEN = 7'h0f, EC = 7'h73;
    /*  the main aim for this controller logic is to reduce the bloat caused by the massive case
    statements in the core.v module, changes here will be added iteratively and will be verified
    as such */
    //decoding the instruction type -> r,i,s,b,u,j first
    // r-type instructions

endmodule
