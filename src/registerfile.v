`default_nettype none
//making the registerfile module as the async reads and sync writes
//inside the ice40 consume lutram and thus the registerfile inflates the amount of luts consumed
//this registerfile is dual port read single port write synchronous memory
module registerfile(
    input wire [31:0] rd_in,
    input wire [4:0] rs1, rs2, rd,
    input wire write_enable, read_enable, clkin,
    output wire [31:0] rs1_mod, rs2_mod
);
//declaring the registerfile variables here
reg [31:0] registerfile_rs1 [1:31];
reg [31:0] registerfile_rs2 [1:31];
reg [31:0] rs1_out, rs2_out;
assign rs1_mod = (rs1 == 5'b00000)?(32'h00000000):(rs1_out);
assign rs2_mod = (rs2 == 5'b00000)?(32'h00000000):(rs2_out);
//registerfile writes per "bank"
//rs1 reads and writes
always@(posedge clkin)begin
    // if (rs1 == 5'b00000) rs1_out <= 32'h0000;
    if (read_enable) rs1_out <= registerfile_rs1[rs1];
    if (write_enable) registerfile_rs1[rd] <= rd_in;
end
//rs2 reads and writes
always@(posedge clkin)begin
    // if (rs2 == 5'b00000) rs2_out <= 32'h0000;
    if (read_enable) rs2_out <= registerfile_rs2[rs2];
    if (write_enable) registerfile_rs2[rd] <= rd_in;
end
endmodule
