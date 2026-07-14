//core module for riscv multicycle core
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//core module here

module core(
    //debug inst
    input wire clkin, reset,
    //debug outputs
    output wire [2:0] state_out;
    output wire [1:0] flags;
    );
    //5 Stages of the classic risc pipeline taken as states in an fsm
    localparam FETCH = 3'd0, DECODE = 3'd1, EXECUTE = 3'd2, MEMORY = 3'd3, WRITEBACK = 3'D4;
    //fsm operator regs
    //alu oper_a is always rs1, and oper_b is always rs2
    //the registerfile for the core, 32 bits wide, 31 deep 0x0 will be tied to 0
    reg [31:0] registerfile [0:31];
    reg [31:0] program_counter;
    //memory interface
    reg [31:0] address_inst, address_dat, data_word;
    //alu
    reg [31:0] a_rs1, b_rs2;
    wire [31:0] result;
    reg [3:0] opcode;
    reg [2:0] state;
    wire [1:0] flags
    reg data_rw;
    //wire nettypes
    wire [31:0] instword, datword;
    // the outside world's window into the cpu
    assign state_out = state;

endmodule