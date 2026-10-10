//core module for riscv multicycle core
`include "config.v"
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
    //uses one hot fsm encoding instead of binary fsm encoding
    localparam FETCH = 6'b000001, DECODE = 6'b000010, EXECUTE = 6'b000100, MEMORY = 6'b001000, WRITEBACK = 6'b010000, RESET = 6'b100000;
    reg [31:0] program_counter, next_program_counter;
    reg [31:0] result;
    //memory interface
    reg [31:0] address_dat, n_address_dat, data_word_IN, n_data_word_IN;
    //alu
    reg [31:0] instword;
    // reg [31:0] alu_a, alu_b;
    reg [31:0] return_dest;
    // reg [3:0] opcode;
    reg [5:0] state, nextstate;
    reg [1:0] data_rw, n_data_rw;
    //a nop reg, when its high the instruction is supposed to be a nop
    // reg write_enable;
    //wire nettypes
    wire [31:0] curr_inst, data_word_OUT;
    wire [31:0] result_alu;
    wire [31:0] gpio_core_out_wire;
    wire [31:0] rs1_latch, rs2_latch;
    wire [4:0] rs1, rs2, rd;
    wire read_enable, write_enable;
    wire [31:0] offset, loadset, storeset, branchdest;
    wire [10:0] INSopc;
    wire [2:0] storetype, storeloadec;
    wire [3:0] ALUopc;
    wire [1:0] Memop;
    // the outside world's window into the cpu
    assign gpio_core_out = gpio_core_out_wire[7:0];
    assign rs2 = instword[24:20];
    assign rs1 = instword[19:15];
    assign rd = instword[11:7];
    // assign read_enable = (state == FETCH||state == DECODE);
    // assign write_enable = (state == WRITEBACK||state == FETCH);
    assign read_enable = state[0];
    assign write_enable = state[4]&(INSopc[1]|INSopc[2]|INSopc[3]|INSopc[7]|INSopc[8]|INSopc[5]|INSopc[0]);
    //mux logic flattening
    wire [31:0] decodeA, decodeB, bsrc; //wire stage for decode
    wire [31:0] execA, execB, naddrdat;
    wire updatepcexe = INSopc[0]|INSopc[1]|INSopc[2]|INSopc[7]|INSopc[8]|INSopc[10];
    // wire [31:0] auipcjalr = (INSopc[1])?({instword[31:12], 12'h000}):({result[31:1], `FALSE});
    wire [31:0] inpcval = (INSopc[3])?({result[31:1], `FALSE}):(program_counter);
    wire [31:0] fnpcval = (updatepcexe)?(result):(inpcval);
    assign decodeA = (INSopc[3]|INSopc[4]|INSopc[5]|INSopc[6])?(rs1_latch):(program_counter);
    assign bsrc = (INSopc[2]|INSopc[3]|INSopc[5]|INSopc[6])?(offset):(32'd4);
    assign decodeB = (INSopc[4])?(rs2_latch):(bsrc);
    wire [5:0] nsexec = (INSopc[4]|INSopc[5]|INSopc[6]|INSopc[10])?(MEMORY):(WRITEBACK);
    assign execA = (INSopc[7]|INSopc[8])?(rs1_latch):(program_counter);
    wire [31:0] selbd = (INSopc[4])?(branchdest):(32'd4);
    wire [31:0] rs2bd = (INSopc[8])?(rs2_latch):(selbd);
    wire [31:0] offsetrs2 = (INSopc[7])?(offset):(rs2bd);
    assign execB = (INSopc[1])?({instword[31:12], 12'h000}):(offsetrs2);
    wire [31:0] oldec = (INSopc[10])?(12'hffc):(address_dat);
    assign naddrdat = (INSopc[5]|INSopc[6])?(result):(oldec);
    //writeback stage combinational
    wire [31:0] writebackwrite;
    wire [31:0] reszero = (INSopc[1]|INSopc[2]|INSopc[3]|INSopc[7]|INSopc[8])?(result):(32'd0);
    wire [31:0] stores = (INSopc[5])?(storeset):(reszero);
    assign writebackwrite = (INSopc[0])?(offset):(stores);
    wire [31:0] aluA = {32{state[1]}}&decodeA|
                       {32{state[2]}}&execA;
    wire [31:0] aluB = {32{state[1]}}&decodeB|
                       {32{state[2]}}&execB;
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
        .gpio_out(gpio_core_out_wire),
        .storeloadec(storeloadec),
        .storetype(storetype)
    );
    alu ALU_0 (
        .oper_a(aluA),
        .oper_b(aluB),
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
        .dataRW(Memop),
        .INSopc(INSopc),
        .Memread(data_word_OUT),
        .storeset(storeset),
        .storetype(storetype),
        .storeloadec(storeloadec)
    );
    //fsm
    always@(posedge clkin)begin
        if(!reset)begin
            program_counter <= 32'h0;
            state <= RESET;
        end
        else begin
            state <= nextstate;
            program_counter <= next_program_counter;
            result <= result_alu;
            // nop <= n_nop;
            data_rw <= n_data_rw;
            address_dat <= n_address_dat;
            data_word_IN <= n_data_word_IN;
            if(nextstate[0]) instword <= curr_inst;
        end
    end
    always@(*)begin
        //preventing latch inferrence
        // alu_a = 32'h00000000;
        // alu_b = 32'h00000000;
        return_dest = 32'h00000000;
        nextstate = state;
        n_data_rw = data_rw;
        next_program_counter = program_counter;
        n_address_dat = address_dat;
        n_data_word_IN = data_word_IN;
        // write_enable = `FALSE;
        case(state)
            RESET:begin
                nextstate = FETCH;
                // next_program_counter = 0;
                n_data_rw = 2'b00;
            end 
            FETCH: nextstate = DECODE;
            DECODE:begin
                //result at decode is either 0 or a 1 when true n_nop goes high
                //decoder puts the feilds into correct thing
                nextstate = EXECUTE;
                n_data_rw = Memop;
                // alu_a = decodeA;
                // alu_b = decodeB;
            end
            EXECUTE:begin
                //program counter increment by default
                next_program_counter = fnpcval;
                nextstate = nsexec;
                // alu_a = execA;
                // alu_b = execB;
                n_address_dat = naddrdat;
                //first part of execute will be that this guy takes the A,B AND OPC and feeds it into the alu
                //states can be skipped
                //the important constraint of the multicycle approach is to use the alu exactly once per state
                //as long as a b and opcode are kept the same, the result will be same
                if(INSopc[6]) n_data_word_IN = loadset;
                if(INSopc[10])begin
                    if(instword[25]) n_data_word_IN = 32'd2; //ebreak
                    else n_data_word_IN = 32'd1; // ecall 
                 // n_address_dat = 12'hffc;
                end 
                //Initial part of decode is done 
                //some operations need the alu more than once i.e first for shifting to the left and then calculating the rd 
                //program counter next updated here
                //if the nop flag is high, then program counter is updated and the fsm is sent to fetch
                //nop takes direct control of the alu in order to land on the new state
                //the alu is passed the newly computed values of the registers A, B and OPC
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
                return_dest = writebackwrite;
            end
        endcase
        end
endmodule
