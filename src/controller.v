`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//controller module
module controller(
    output wire [31:0] offset,
    output wire [5:0] INSopc,
    output wire [4:0] ALUopc,
    input wire [31:0] rs2_src,
    input wire [31:0] instword,
    input wire [31:0] program_counter, result,
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
    //instruction type decoded -> r,i,s,b,u,j ->
    assign INSopc[0] = (opcode == ARM_RR); //r
    assign INSopc[1] = ((opcode == LOAD)||(opcode == ARM_IMM)||(opcode == JALR)); //i
    assign INSopc[2] = (opcode == STORE); //s
    assign INSopc[3] = (opcode == BRANCH); //b
    assign INSopc[4] = ((opcode == LUI)||(opcode == AUIPC)); //u
    assign INSopc[5] = (opcode == JAL); //j
    //FENCE AND ECALL HANDLED SEPARATELY
    //immediate variables
    wire [31:0] Rtypesrc  = rs2_src&{32{INSopc[0]}};
    wire [31:0] Utypeoffset = {instword[31:12], 12'h000}&{32{INSopc[4]}};
    wire [31:0] branchoffset = {{19{instword[31]}} ,instword[31], instword[7], instword[30:25], instword[11:8], `FALSE}&{32{INSopc[3]}};
    wire [31:0] jaloffset = {{11{instword[31]}}, instword[31], instword[19:12], instword[20], instword[30:21], `FALSE}&{32{INSopc[5]}};
    wire [31:0] immoffset = {{20{instword[31]}}, instword[31:20]}&{32{INSopc[1]}};
    wire [31:0] storeoffset = {{20{instword[31]}} ,instword[31:25], instword[11:7]}&{32{INSopc[2]}};
    assign offset = Rtypesrc|Utypeoffset|branchoffset|jaloffset|immoffset|storeoffset;
    //function variables
    wire [6:0] funct7 = instword[31:25];
    wire [6:0] opcode = instword[6:0];
    wire [2:0] funct3 = instword[14:12];
    wire [2:0] branchcase;
    assign branchcase[0] = ((funct3 == 3'b000) || (funct3 == 3'b001));
    assign branchcase[1] = ((funct3 == 3'b100) || (funct3 == 3'b101));
    assign branchcase[2] = ((funct3 == 3'b110) || (funct3 == 3'b111));
    //branchopc
    wire [3:0] brancheql = (branchcase[0])?(EQL):(3'b000);
    wire [3:0] branchslt = (branchcase[2])?(SLT):(3'b000);
    wire [3:0] branchsltu = (branchcase[3])?(SLTU):(3'b000);
    //deciding the alu opcode for the decode cycle -> add for everyone other than branch
    /* opcode map for the decode stage
    ADD -> all other instructions other than branch
    pc+4 addition here except load and store
    load and store calculate required memory address 
    therefore only jal, jalr, branch, load and store 
    dont update nextprogramcounter at execute*/
    wire [3:0] BranchOpc = brancheql|branchslt|branchsltu;
    wire [3:0] DecodeOpc = (INSopc[3])?(BranchOpc):(ADD);
    wire [3:0] DecodeMux = (state == DECODE)?(DecodeOpc):(ADD);
    //deciding the alu opcode for the execute cycle -> the real arithmetic opcode for the alu
    // branch load and store update nextprogramcounter at memory
    wire [3:0] ExectuteMux = (state == EXECUTE)?(ExecuteOpc):(ADD);
    assign ALUopc = DecodeMux|ExectuteMux;

endmodule
