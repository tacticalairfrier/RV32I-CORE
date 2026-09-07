//core module for riscv multicycle core
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0
//core module here
module core(
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off CASEINCOMPLETE */
    //debug inst
    input wire [7:0] gpio_core_in,
    input wire clkin, reset,
    //debug outputs
    output wire [7:0] gpio_core_out
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
    // reg [31:0] registerfile [0:31];
    reg [31:0] program_counter, next_program_counter;
    reg [31:0] A, B, result;
    //memory interface
    reg [31:0] address_dat, n_address_dat, data_word_IN, n_data_word_IN;
    //alu
    reg [31:0] instword;
    reg [31:0] alu_a, alu_b;
    reg [31:0] return_dest;
    reg [3:0] opcode;
    reg [2:0] state, nextstate;
    reg [1:0] data_rw, n_data_rw;
    //a nop reg, when its high the instruction is supposed to be a nop
    reg write_enable;
    //wire nettypes
    wire [31:0] curr_inst, data_word_OUT;
    wire [31:0] result_alu;
    wire [31:0] gpio_core_out_wire;
    wire [31:0] rs1_latch, rs2_latch;
    wire [4:0] rs1, rs2, rd;
    wire read_enable;
    //
    wire [31:0] offset, loadset, branchdest;
    wire [3:0] ALUopc;
    wire [1:0] Memop;
    //
    // the outside world's window into the cpu
    assign gpio_core_out = gpio_core_out_wire[7:0];
    assign rs2 = instword[24:20];
    assign rs1 = instword[19:15];
    assign rd = instword[11:7];
    // assign read_enable = (state == FETCH||state == DECODE);
    // assign write_enable = (state == WRITEBACK||state == FETCH);
    assign read_enable = (state == FETCH);
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
        .datwordout(data_word_OUT),
        .gpio_in({24'h0000000, gpio_core_in}),
        .gpio_out(gpio_core_out_wire)
    );
    alu ALU_0 (
        .oper_a(alu_a),
        .oper_b(alu_b),
        .opcode(ALUopc),
        .result(result_alu)
    );
    registerfile REG_0(
        .rd_in(return_dest),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .clkin(clkin),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .rs1_mod(rs1_latch),
        .rs2_mod(rs2_latch)
    );
    controller C_0(
        .loadset(loadset),
        .offset(offset),
        .ALUopc(ALUopc),
        .rs2_src(rs2_latch),
        .instword(instword),
        .state(state),
        .lastresult(result[0]),
        .branchdest(branchdest),
        .dataRW(Memop)
    );
    //fsm
    always@(posedge clkin)begin
        if(!reset)begin
            program_counter <= 32'h0;
            state <= RESET;
            instword <= 32'h00000000;
            // registerfile [0] <= 32'h00000000;
            // nop  <= `FALSE;
        end
        else begin
            state <= nextstate;
            program_counter <= next_program_counter;
            result <= result_alu;
            // nop <= n_nop;
            data_rw <= n_data_rw;
            address_dat <= n_address_dat;
            data_word_IN <= n_data_word_IN;
            if(nextstate==FETCH) instword <= curr_inst;
        end
    end
    always@(*)begin
        //preventing latch inferrence
        A = 32'h0;
        B = 32'h0;
        alu_a = 32'h00000000;
        alu_b = 32'h00000000;
        return_dest = 32'h00000000;
        nextstate = state;
        n_data_rw = data_rw;
        next_program_counter = program_counter;
        n_address_dat = address_dat;
        n_data_word_IN = data_word_IN;
        write_enable = `FALSE;
        if(!reset)begin
            nextstate = FETCH;
            next_program_counter = 0;
            n_data_rw = 2'b00;
        end
        else begin
            case(state)
            RESET: nextstate = FETCH;
            FETCH: nextstate = DECODE;
            DECODE:begin
                //result at decode is either 0 or a 1 when true n_nop goes high
                //decoder puts the feilds into correct thing
                A = program_counter;
                B = 4;
                nextstate = EXECUTE;
                n_data_rw = Memop;
                //default nextstae is execute 
                case(instword[6:0])
                JAL: begin
                    A = program_counter;
                    B = offset;
                end
                //jalr logic needs a change jalr does pc+4 now and the pc+rs1 in exec
                JALR: begin //
                    A = rs1_latch;
                    B = offset;
                end
                BRANCH: begin
                    // a and b are rs1 and rs2 rspectively using r-type instruction format
                    A = rs1_latch;
                    B = rs2_latch;
                end
                //only load and store are allowed to take the fsm into memory
                LOAD: begin
                    //data rw is true because ur loading data inside
                    // n_data_rw = 2'b10;
                    //A is the rs1 and b is the immediate instruction field using i-type field
                    A = rs1_latch;
                    B = offset; //sign-extended
                    //not taking f3 field here as its always going to be an add instruction
                    //THE logic for fetching from memory comes in the decode phase
                end
                STORE: begin
                    // n_data_rw = 2'b01; ///latch
                    //decode for the s-type instruction
                    A = rs1_latch;
                    B = offset;
                end
                //fence and fence.tso instructions will be decoded but they do 
                //absolutely nothing so treating as nop
                FEN:;
                //ecall reserved address = 0x1000
                EC: begin
                    // n_data_rw = 2'b01; //memory in write
                end
                endcase
                //raises the nop flag when all are zero
                //first use of alu done right after the decode state
                alu_a = A;
                alu_b = B;
            end
            EXECUTE:begin
                //program counter increment by default
                A = program_counter;
                B = 4;
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
                        A = program_counter;
                        B = branchdest;
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
                        n_data_word_IN = loadset;
                        nextstate = MEMORY;
                    end
                    ARM_IMM:begin
                        next_program_counter = result;
                        A = rs1_latch;
                        B = offset;
                        nextstate = WRITEBACK;
                    end
                    ARM_RR: begin
                        next_program_counter = result;
                        A = rs1_latch;
                        B = rs2_latch;
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
                //the alu is passed the newly computed values of the registers A, B and OPC
                alu_a = A;
                alu_b = B;
                //updating the nextprogramcounter
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
                nextstate = FETCH;
                write_enable = `TRUE;
                case(instword[6:0])
                    LUI: return_dest = offset;
                    AUIPC: return_dest = result;
                    JAL: return_dest = result;
                    JALR: return_dest = result;
                    LOAD: begin
                        case(instword[14:12])
                        3'h0: return_dest = {{24{data_word_OUT[7]}}, data_word_OUT[7:0]};
                        3'h1: return_dest = {{16{data_word_OUT[15]}}, data_word_OUT[15:0]};
                        3'h2: return_dest = data_word_OUT;
                        3'h4: return_dest = {24'h000000, data_word_OUT[7:0]};
                        3'h5: return_dest = {16'h0000, data_word_OUT[15:0]};
                        endcase
                    end
                    ARM_IMM: return_dest = result;
                    ARM_RR: return_dest = result;
                    default: write_enable = `FALSE;
                endcase
            end
                //alu use will not happen in the writeback and memory state
                //registerfile always stays synced to the clock posedge and thus stays syncronous
                //IN this stage only can the registerfile be written
                //the registerfile can be read in any other states
                //this is just for WRITING on the registerfile
            endcase
        end
        end
endmodule
