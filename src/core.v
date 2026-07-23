//core module for riscv multicycle core
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//core module here
module core(
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off CASEINCOMPLETE */
    //debug inst
    input wire clkin, reset,
    //debug outputs
    output wire [2:0] state_out,
    output wire [1:0] flags
    );
    //5 Stages of the classic risc pipeline taken as states in an fsm
    localparam FETCH = 3'd0, DECODE = 3'd1, EXECUTE = 3'd2, MEMORY = 3'd3, WRITEBACK = 3'D4, RESET = 3'd5;
    ///localparam for opcodes of the alu
    localparam SLL = 4'h8, SRR = 4'h9, SRA = 4'ha, EQL = 4'hb, SLT = 4'hc, SLTU = 4'hd, ADD = 4'h7, SUB = 4'h6, AND = 4'h5, OR = 4'h4, XOR = 4'h3;
    //localparams for the riscv standard opcodes
    localparam LUI = 7'h37, AUIPC = 7'h17, JAL = 7'h6f, JALR = 7'h67, BRANCH = 7'h63, LOAD = 7'h03, STORE = 7'h23, ARM_IMM = 7'h13, ARM_RR = 7'h33, FEN = 7'h0f, EC = 7'h73;
    //fsm operator regs
    //alu oper_a is always rs1, and oper_b is always rs2
    //the registerfile for the core, 32 bits wide, 31 deep 0x0 will be tied to 0
    reg [31:0] registerfile [0:31];
    reg [31:0] program_counter, next_program_counter;
    reg [31:0] A, B, result;
    //memory interface
    reg [31:0] address_dat, n_address_dat, data_word_IN, n_data_word_IN;
    //alu
    reg [31:0] instword;
    reg [31:0] alu_a, alu_b;
    reg [3:0] opcode, OPC;
    reg [2:0] state, nextstate;
    reg [1:0] data_rw, n_data_rw;
    //a nop reg, when its high the instruction is supposed to be a nop
    reg n_nop, nop;
    //wire nettypes
    wire [31:0] curr_inst, data_word_OUT;
    wire [31:0] result_alu;
    // the outside world's window into the cpu
    assign state_out = state;
    //to be removed 
    //initialising the modules 
    memory MEM_0 (
        //directly linking the program counter to the memory
        .address_inst(next_program_counter),
        .address_dat(n_address_dat),
        .datawordin(n_data_word_IN),
        .clkin(clkin),
        .dat_rw(data_rw),
        .instword(curr_inst),
        .datwordout(data_word_OUT)
    );
    alu ALU_0 (
        .oper_a(alu_a),
        .oper_b(alu_b),
        .opcode(opcode),
        .result(result_alu),
        .flags(flags)
    );
    //fsm
    always@(posedge clkin)begin
        if(!reset)begin
            program_counter <= 32'h0;
            state <= RESET;
            instword <= 32'h00000000;
            nop  <= `FALSE;
        end
        else begin
            state <= nextstate;
            program_counter <= next_program_counter;
            result <= result_alu;
            nop <= n_nop;
            data_rw <= n_data_rw;
            address_dat <= n_address_dat;
            data_word_IN <= n_data_word_IN;
            if(nextstate==FETCH) begin
                instword <= curr_inst;
                //check the pc and pc latched logic
                // pc_latched <= program_counter;
            end 
            //simple thing done here, the result for memory must only be the memory address
        end
    end
    always@(*)begin
        //preventing latch inferrence
        A = 32'h0;
        B = 32'h0;
        OPC = ADD;
        alu_a = 32'h00000000;
        alu_b = 32'h00000000;
        opcode = ADD;
        nextstate = state;
        registerfile [0] = 32'h00000000;
        n_nop = nop;
        n_data_rw = data_rw;
        next_program_counter = program_counter;
        //
        n_address_dat = address_dat;
        n_data_word_IN = data_word_IN;
        if(!reset)begin
            nextstate = FETCH;
            next_program_counter = 0;
            n_nop = `FALSE;
            n_data_rw = 2'b00;
        end
        else begin
            case(state)
            RESET: nextstate = FETCH;
            FETCH:begin 
                //fetch's alu use is to calculate whether the instruction is a nop or not
                nextstate = DECODE;
                alu_a = instword;
                alu_b = 32'h00000000;
                opcode = EQL;
                end
            DECODE:begin
                //result at decode is either 0 or a 1 when true n_nop goes high
                //decoder puts the feilds into correct thing
                A = program_counter;
                B = 4;
                OPC = ADD;
                nextstate = EXECUTE;
                n_nop = `FALSE;
                if(result[0]) n_nop = `TRUE;
                //default nextstae is execute 
                case(instword[6:0])
                JAL: begin
                    // A = {{11{instword[31]}}, instword[31], instword[30], instword[30:21], instword[20], instword[19:12], `FALSE};
                    A = {{11{instword[31]}}, instword[31], instword[19:12], instword[20], instword[30:21], `FALSE};
                    B = program_counter;
                    OPC = ADD;
                end
                JALR: begin
                    A = registerfile[instword[19:15]];
                    B = {{20{instword[31]}}, instword[31:20]};
                    OPC = ADD;
                end
                BRANCH: begin
                    // a and b are rs1 and rs2 rspectively using r-type instruction format
                    A = registerfile[instword[19:15]];
                    B = registerfile[instword[24:20]];
                    case(instword[14:12])
                    //beq -> take the branch if equal to 
                    3'h0: OPC = EQL;
                    //bne -> take the branch if not equal
                    3'h1: OPC = EQL;
                    //blt -> take the branch if rs1 is less than rs2 in a signed comparison
                    3'h4: OPC = SLT;
                    //bge -> take the branch if rs1 is greater than rs2 using a signed comparison
                    3'h5: OPC = SLT;
                    //bltu -> take the branch is rs1 is less than rs2 using unsigned comparison
                    3'h6: OPC = SLTU;
                    //bgeu -> take the branch if rs1 is greater than rs2 using an unsigned comparison
                    3'h7: OPC = SLTU;
                    endcase
                end
                //only load and store are allowed to take the fsm into memory
                LOAD: begin
                    //data rw is true because ur loading data inside
                    n_data_rw = 2'b10;
                    //A is the rs1 and b is the immediate instruction field using i-type field
                    A = registerfile[instword[19:15]];
                    B = {{20{instword[31]}}, instword[31:20]}; //sign-extended
                    //not taking f3 field here as its always going to be an add instruction
                    OPC =  ADD;
                    nextstate = EXECUTE;
                    //THE logic for fetching from memory comes in the decode phase
                end
                STORE: begin
                    n_data_rw = 2'b01; ///latch
                    //decode for the s-type instruction
                    A = registerfile[instword[19:15]];
                    B = {{20{instword[31]}} ,instword[31:25], instword[11:7]};
                    OPC = ADD;
                    nextstate = EXECUTE;
                end
                //fence and fence.tso instructions will be decoded but they do 
                //absolutely nothing so treating as nop
                FEN: n_nop = `TRUE;
                //ecall reserved address = 0x1000
                EC: begin
                    n_data_rw = 2'b01; //memory in write
                end
                endcase
                //raises the nop flag when all are zero
                //first use of alu done right after the decode state
                alu_a = A;
                alu_b = B;
                opcode = OPC;
            end
            EXECUTE:begin
                //program counter increment by default
                A = program_counter;
                B = 4;
                OPC = ADD;
                nextstate = WRITEBACK;
                //first part of execute will be that this guy takes the A,B AND OPC and feeds it into the alu
                //states can be skipped
                //the important constraint of the multicycle approach is to use the alu exactly once per state
                //as long as a b and opcode are kept the same, the result will be same
                case(instword[6:0])
                    LUI: next_program_counter = result;
                    AUIPC: begin
                        next_program_counter = result;
                        A = {instword[31:12], 12'h000};
                        B = program_counter;
                    end
                    JAL: next_program_counter = result;
                    JALR: next_program_counter = {result[31:1], `FALSE};
                    BRANCH:begin
                        if(instword[14:12] == 3'h0 || instword[14:12] == 3'h4 || instword[14:12] == 3'h6)begin
                            //for all true conditions -> beq, blt, bltu
                            if(result[0]) begin
                                A = program_counter;
                                //b is the offset to be added to the programcounter
                                B = {{19{instword[31]}} ,instword[31], instword[7], instword[30:25], instword[11:8], `FALSE};
                            end
                        end
                        else begin
                            //for all false conditions -> bne, bge, bgeu
                            if(!result[0]) begin
                                A = program_counter;
                                //b is the offset to be added to the programcounter
                                B = {{19{instword[31]}} ,instword[31], instword[7], instword[30:25], instword[11:8], `FALSE};
                            end
                        end
                        nextstate = MEMORY;
                    end
                    LOAD:begin
                        // next_program_counter = result;
                        nextstate = MEMORY;
                        n_address_dat = result;
                    end 
                    STORE:begin
                        //case statement
                        n_address_dat = result; /// latch needed, 
                        case(instword[14:12])
                        3'h0:n_data_word_IN = {24'h000000, registerfile[instword[24:20]][7:0]}; //latch needed
                        3'h1:n_data_word_IN = {16'h0000, registerfile[instword[24:20]][15:0]};
                        3'h2:n_data_word_IN = registerfile[instword[24:20]];
                        endcase
                        nextstate = MEMORY;
                    end
                    ARM_IMM:begin
                        next_program_counter = result;
                        A = registerfile[instword[19:15]];
                        B = {{20{instword[31]}}, instword[31:20]};
                        case(instword[14:12])
                            ///case block is just useful for setting the opcode
                            3'h0: OPC = ADD;
                            3'h1: OPC = SLL;
                            3'h2: OPC = SLT;
                            3'h3: OPC = SLTU;
                            3'h4: OPC = XOR;
                            3'h5: begin
                                //F7 decoding into opcode
                                if(instword[31:25] == 7'h00) OPC = SRR;
                                else if(instword[31:25] == 7'h20) OPC = SRA;
                            end
                            3'h6: OPC = OR;
                            3'h7: OPC = AND;
                        endcase
                        nextstate = WRITEBACK;
                    end
                    ARM_RR: begin
                        next_program_counter = result;
                        A = registerfile[instword[19:15]];
                        B = registerfile[instword[24:20]];
                        case(instword[14:12])
                            3'h0:begin
                                if(instword[31:25] == 7'h00) OPC = ADD;
                                else if(instword[31:25] == 7'h20) OPC = SUB;
                            end
                            3'h1: OPC = SLL;
                            3'h2: OPC = SLT;
                            3'h3: OPC = SLTU;
                            3'h4: OPC = XOR;
                            3'h5: begin
                                if(instword[31:25] == 7'h00) OPC = SRR;
                                else if(instword[31:25] == 7'h20) OPC = SRA;
                            end
                            3'h6: OPC = OR;
                            3'h7: OPC = AND;
                        endcase
                        nextstate = WRITEBACK;
                    end
                    FEN: nextstate = WRITEBACK;
                        //treating fence as an nop here
                    EC:begin
                        next_program_counter = result;
                        nextstate = MEMORY;
                        if(instword[31:25] == 7'h01) n_data_word_IN = 2; //ebreak
                        else n_data_word_IN = 1; // ecall 
                        n_address_dat = 12'hffc;
                    end 
                        //calling ecall as an nop here 
                        //will need to add some functionality
                    //second use of the alu
                endcase
                //Initial part of decode is done 
                //some operations need the alu more than once i.e first for shifting to the left and then calculating the rd 
                //program counter next updated here
                //if the nop flag is high, then program counter is updated and the fsm is sent to fetch
                //nop takes direct control of the alu in order to land on the new state
                if(nop)begin
                    n_nop = `TRUE;
                    next_program_counter = result;
                    nextstate = WRITEBACK;
                end
                else begin
                    //the alu is passed the newly computed values of the registers A, B and OPC
                    alu_a = A;
                    alu_b = B;
                    opcode = OPC;
                    //updating the nextprogramcounter
                end
                //the calculation done in the execute cycle will most likely be for the program counter   
            end
            MEMORY:begin
                //all memory acctions are done in the fsm,
                //nothing here
                //memory cant be read from or written to from any other block
                next_program_counter = result;
                nextstate = WRITEBACK;
                //handling only 2 states coz only 2 states can bring here  
            end
            WRITEBACK:begin
                //alu use will not happen in the writeback and memory state
                nextstate = FETCH;
                case(instword[6:0])
                    LUI: registerfile[instword[11:7]] = {instword[31:12], 12'h000};
                    //lui path fetch -> decode ->execute->writeback
                    AUIPC: registerfile[instword[11:7]] = result;
                    JAL: registerfile[instword[11:7]] = result;
                    JALR: registerfile[instword[11:7]] = result;
                    LOAD: begin
                        case(instword[14:12])
                        3'h0: registerfile[instword[11:7]] = {{24{data_word_OUT[7]}}, data_word_OUT[7:0]};
                        3'h1: registerfile[instword[11:7]] = {{16{data_word_OUT[15]}}, data_word_OUT[15:0]};
                        3'h2: registerfile[instword[11:7]] = data_word_OUT;
                        3'h4: registerfile[instword[11:7]] = {24'h000000, data_word_OUT[7:0]};
                        3'h5: registerfile[instword[11:7]] = {16'h000000, data_word_OUT[7:0]};
                        endcase
                    end
                    ARM_IMM: registerfile[instword[11:7]] = result;
                    ARM_RR: registerfile[instword[11:7]] = result;
                endcase
                //registerfile cleanup
                registerfile[0] = 32'h0000_0000;
                //registerfile always stays asynchronous
                //IN this stage only can the registerfile be written
                //the registerfile can be read in any other states
                //this is just for WRITING on the registerfile
            end
            endcase
        end
        end
endmodule
