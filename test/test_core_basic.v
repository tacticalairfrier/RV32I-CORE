`timescale 1 ns/1 ps
`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module test_rv32i_basic;
reg clkin, reset;
wire [2:0] state;
wire [1:0] flags;
integer i;
integer j;
core RV32I_00(
    .clkin(clkin),
    .reset(reset),
    .state_out(state),
    .flags(flags)
);
always #5 clkin = ~clkin;
initial begin
    clkin = `FALSE;
    reset = `FALSE;
    #40 reset = `TRUE;
end
initial begin
    $dumpfile("sim.vcd");
    //dumping of all the variables that exist here
    $dumpvars(0,test_rv32i_basic);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[1]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[1]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[2]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[2]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[3]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[3]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[4]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[4]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[5]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[5]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[6]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[6]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[7]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[7]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[8]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[8]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[9]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[9]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[10]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[10]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[11]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[11]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[12]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[12]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[13]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[13]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[14]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[14]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[15]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[15]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[16]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[16]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[17]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[17]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[18]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[18]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[19]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[19]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[20]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[20]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[21]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[21]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[22]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[22]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[23]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[23]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[24]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[24]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[25]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[25]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[26]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[26]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[27]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[27]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[28]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[28]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[29]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[29]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[30]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[30]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs1[31]);
    $dumpvars(0,RV32I_00.REG_0.registerfile_rs2[31]);
    for(i=0;i<40;i=i+1)begin
        $dumpvars(0, RV32I_00.MEM_0.dat_mem[i]);
    end
    j = $fopen("test/memory.txt", "w");
    #6600;
    //dumping the first 80 memory addresses directly into memory.txt
    for(i=0;i<20;i=i+1)begin
        $fdisplay(j,"%h",RV32I_00.MEM_0.dat_mem[i]);
    end
    $fclose(j);
    $finish;
end
endmodule
