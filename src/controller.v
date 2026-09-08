`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//controller module
module controller(
    output wire [31:0] offset, loadset, branchdest,
    output wire [10:0] INSopc,
    output wire [3:0] ALUopc,
    output wire [1:0] dataRW,
    input wire [31:0] rs2_src,
    input wire [31:0] instword,
    input wire [5:0] state,
    input wire lastresult
);
    //controller module intentionally stays purely combinational
    //copying over the localparams from the core.v module
    // localparam DECODE = 3'd1, EXECUTE = 3'd2;
    localparam SLL = 4'h8, SRR = 4'h9, SRA = 4'ha, EQL = 4'hb, SLT = 4'hc, SLTU = 4'hd, ADD = 4'h7, SUB = 4'h6, AND = 4'h5, OR = 4'h4, XOR = 4'h3;
    localparam LUI = 7'h37, AUIPC = 7'h17, JAL = 7'h6f, JALR = 7'h67, BRANCH = 7'h63, LOAD = 7'h03, STORE = 7'h23, ARM_IMM = 7'h13, ARM_RR = 7'h33, FEN = 7'h0f, EC = 7'h73;
    /*  the main aim for this controller logic is to reduce the bloat caused by the massive case
    statements in the core.v module, changes here will be added iteratively and will be verified
    as such */
    wire [6:0] funct7 = instword[31:25];
    wire [6:0] opcode = instword[6:0];
    wire [2:0] funct3 = instword[14:12];
    wire dec = state[1];
    wire exc = state[2];
    //zerologic
    wire [7:0] zerologic;
    assign zerologic[0] = (funct3 == 3'b000);
    assign zerologic[1] = (funct3 == 3'b001);
    assign zerologic[2] = (funct3 == 3'b010);
    assign zerologic[3] = (funct3 == 3'b011);
    assign zerologic[4] = (funct3 == 3'b100);
    assign zerologic[5] = (funct3 == 3'b101);
    assign zerologic[6] = (funct3 == 3'b110);
    assign zerologic[7] = (funct3 == 3'b111);
    //instruction type decoded -> r,i,s,b,u,j ->
    // wire [5:0] INSopc;
    // assign INSopc[0] = (opcode == ARM_RR); //r
    // assign INSopc[1] = ((opcode == LOAD)||(opcode == ARM_IMM)||(opcode == JALR)); //i
    // assign INSopc[2] = (opcode == STORE); //s
    // assign INSopc[3] = (opcode == BRANCH); //b
    // assign INSopc[4] = ((opcode == LUI)||(opcode == AUIPC)); //u
    // assign INSopc[5] = (opcode == JAL); //j
    assign INSopc[0] = (opcode == LUI); //u
    assign INSopc[1] = (opcode == AUIPC); //u
    assign INSopc[2] = (opcode == JAL); //j
    assign INSopc[3] = (opcode == JALR); //i
    assign INSopc[4] = (opcode == BRANCH); //b
    assign INSopc[5] = (opcode == LOAD); //i
    assign INSopc[6] = (opcode == STORE); //s
    assign INSopc[7] = (opcode == ARM_IMM); //i
    assign INSopc[8] = (opcode == ARM_RR); //r
    assign INSopc[9] = (opcode == FEN); //
    assign INSopc[10] = (opcode == EC); // 
    //arithmetic instruction decode
    assign dataRW[0] = INSopc[6]|INSopc[10];
    assign dataRW[1] = INSopc[5];
    wire [1:0] arithcode;
    assign arithcode[0] = INSopc[8]; //rr
    assign arithcode[1] = INSopc[7]; //imm
    wire arithmetic = |arithcode;
    //FENCE AND ECALL HANDLED SEPARATELY
    //immediate variables
    wire [31:0] Rtypesrc  = rs2_src&{32{INSopc[8]}};
    wire [31:0] Utypeoffset = {instword[31:12], 12'h000}&{32{INSopc[0]|INSopc[1]}};
    wire [31:0] jaloffset = {{11{instword[31]}}, instword[31], instword[19:12], instword[20], instword[30:21], `FALSE}&{32{INSopc[2]}};
    wire [31:0] immoffset = {{20{instword[31]}}, instword[31:20]}&{32{INSopc[3]|INSopc[5]|INSopc[7]}};
    wire [31:0] storeoffset = {{20{instword[31]}} ,instword[31:25], instword[11:7]}&{32{INSopc[6]}};
    assign offset = Rtypesrc|Utypeoffset|jaloffset|immoffset|storeoffset;
    //branch logic 
    wire [31:0] branchoffset = {{19{instword[31]}} ,instword[31], instword[7], instword[30:25], instword[11:8], `FALSE};  //&{32{INSopc[3]}};
    wire [31:0] truecase = (zerologic[0]|zerologic[4]|zerologic[6])?(branchoffset):(32'd4);
    wire [31:0] falsecase = (zerologic[1]|zerologic[5]|zerologic[7])?(branchoffset):(32'd4);
    assign branchdest = (lastresult)?(truecase):(falsecase);
    //function variables
    wire [2:0] branchcase;
    //assigning branchcases
    assign branchcase[0] = ((zerologic[0]) || (zerologic[1]));
    assign branchcase[1] = ((zerologic[4]) || (zerologic[5]));
    assign branchcase[2] = ((zerologic[6]) || (zerologic[7]));
    //assigning arithcases
    wire [3:0] addicode = (arithcode[0]&(zerologic[0])&~funct7[5])?(ADD):(4'b0000); //addi
    wire [3:0] subcode = (arithcode[0]&(zerologic[0])&funct7[5])?(SUB):(4'b0000); //sub
    wire [3:0] addcode = (arithcode[1]&(zerologic[0]))?(ADD):(4'b0000); //addi
    wire [3:0] sllcode = (arithmetic&(zerologic[1]))?(SLL):(4'b0000); //sll
    wire [3:0] sltcode = (arithmetic&(zerologic[2]))?(SLT):(4'b0000); //slt
    wire [3:0] sltucode = (arithmetic&(zerologic[3]))?(SLTU):(4'b0000); //sltu
    wire [3:0] xorcode = (arithmetic&(zerologic[4]))?(XOR):(4'b0000); //xor
    wire [3:0] srrcode = (arithmetic&(zerologic[5])&~funct7[5])?(SRR):(4'b0000); //srr
    wire [3:0] sracode = (arithmetic&(zerologic[5])&funct7[5])?(SRA):(4'b0000); //sra
    wire [3:0] orcode = (arithmetic&(zerologic[6]))?(OR):(4'b0000); //or
    wire [3:0] andcode = (arithmetic&(zerologic[7]))?(AND):(4'b0000); //and
    wire [3:0] ARMopc = addcode|addicode|subcode|sllcode|sltcode|sltucode|xorcode|srrcode|sracode|orcode|andcode;
    //branchopc
    wire [3:0] brancheql = (branchcase[0])?(EQL):(4'b0000);
    wire [3:0] branchslt = (branchcase[1])?(SLT):(4'b0000);
    wire [3:0] branchsltu = (branchcase[2])?(SLTU):(4'b0000);
    //deciding the alu opcode for the decode cycle -> add for everyone other than branch
    /* opcode map for the decode stage
    ADD -> all other instructions other than branch
    pc+4 addition here except load and store
    load and store calculate required memory address 
    therefore only jal, jalr, branch, load and store 
    dont update nextprogramcounter at execute*/
    wire [3:0] BranchOpc = brancheql|branchslt|branchsltu;
    wire [3:0] DecodeOpc = ((INSopc[4])?(BranchOpc):(ADD))&{4{dec}};
    wire [3:0] ExecuteOpc = ((arithmetic)?(ARMopc):(ADD))&{4{exc}};
    wire dontcare = (~(dec|exc));
    wire [3:0] normal = {4{dontcare}}&ADD;
    // wire [3:0] DecodeMux = (state == DECODE)?(DecodeOpc):(ADD); //!
    //deciding the alu opcode for the execute cycle -> the real arithmetic opcode for the alu
    // branch load and store update nextprogramcounter at memory
    // wire [3:0] ExectuteMux = (state == EXECUTE)?(ExecuteOpc):(ADD);
    //the execute state alu opcode logic
    assign ALUopc = DecodeOpc|ExecuteOpc|normal;
    //loadset
    wire [31:0] s0 = (zerologic[0])?({24'h000000, rs2_src[7:0]}):(32'd0);
    wire [31:0] s1 = (zerologic[1])?({16'h0000, rs2_src[15:0]}):(32'd0);
    wire [31:0] s2 = (zerologic[2])?(rs2_src):(32'd0);
    assign loadset = s0|s1|s2;
endmodule
