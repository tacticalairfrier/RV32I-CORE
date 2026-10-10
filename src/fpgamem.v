`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module fpgamem(
    input wire [31:0] datain,
    output wire [31:0] dataout,
    input wire [15:0] address,
    input wire [2:0] storetype, storeloadec,
    input wire clkin, WR_EN //fsm memory state
);
//ice40up5k specific ram localparams
//for byte writes
localparam  MASKUPPER   = 4'b1100,
            MASKLOWER   = 4'b0011,
            MASKDISABLE = 4'b0000,
            MASKENABLE  = 4'b1111;
// wire WR_EN = (storeloadec[2]|storeloadec[0])&isMemory; //write enable fires when the fsm state is memory and instruction type was store
`ifdef TARGET_SIM_ICE40UP5K
wire [13:0] INTaddress = address [15:2];
wire [1:0] INTtype = address [1:0];
wire internalwren = WR_EN&(storeloadec[2]|storeloadec[0]);
//LOGIC for determining the wren signals across banks
//sw, sh , sb writemasks
wire [7:0] swwm = {MASKENABLE, MASKENABLE};
wire [7:0] shwm = (INTtype[1])?({MASKENABLE, MASKDISABLE}):({MASKDISABLE, MASKENABLE});
wire [7:0] sbwm = (INTtype[1])?((INTtype[0])?({MASKUPPER, MASKDISABLE}):({MASKLOWER, MASKDISABLE})):((INTtype[0])?({MASKDISABLE, MASKUPPER}):({MASKDISABLE, MASKLOWER}));
wire [7:0] writemask =  {8{storetype[2]}}&swwm|
                        {8{storetype[1]}}&shwm|
                        {8{storetype[0]}}&sbwm;
//setting the data in for each bank here
wire [31:0] storeworddata = datain;
wire [31:0] storehalfdata = {datain[15:0], datain[15:0]};
wire [31:0] storebytedata = {datain[7:0], datain[7:0], datain[7:0], datain[7:0]};
wire [31:0] databankin =    {32{storetype[2]}}&storeworddata|
                            {32{storetype[1]}}&storehalfdata|
                            {32{storetype[0]}}&storebytedata;
//memory bank initialization
    SB_SPRAM256KA bank0(
        .ADDRESS(INTaddress),
        .DATAIN(databankin[15:0]),
        .MASKWREN(writemask[3:0]),
        .WREN(internalwren),
        .CHIPSELECT(|storeloadec),
        .CLOCK(clkin),
        .STANDBY(`FALSE),
        .SLEEP(`FALSE),
        .POWEROFF(`TRUE),
        .DATAOUT(dataout[15:0]) //bank0 holds the lower 2 bytes 
    );
    SB_SPRAM256KA bank1(
        .ADDRESS(INTaddress),
        .DATAIN(databankin[31:16]),
        .MASKWREN(writemask[7:4]),
        .WREN(internalwren),
        .CHIPSELECT(|storeloadec),
        .CLOCK(clkin),
        .STANDBY(`FALSE),
        .SLEEP(`FALSE),
        .POWEROFF(`TRUE),
        .DATAOUT(dataout[31:16]) //bank1 holds the upper 2 bytes
    );
`endif 
`ifdef TARGET_ICE40UP5K //ice40up5k target
wire [13:0] INTaddress = address [15:2];
wire [1:0] INTtype = address [1:0];
//LOGIC for determining the wren signals across banks
wire internalwren = WR_EN&(storeloadec[2]|storeloadec[0]);
//sw, sh , sb writemasks
wire [7:0] swwm = {MASKENABLE, MASKENABLE};
wire [7:0] shwm = (INTtype[1])?({MASKENABLE, MASKDISABLE}):({MASKDISABLE, MASKENABLE});
wire [7:0] sbwm = (INTtype[1])?((INTtype[0])?({MASKUPPER, MASKDISABLE}):({MASKLOWER, MASKDISABLE})):((INTtype[0])?({MASKDISABLE, MASKUPPER}):({MASKDISABLE, MASKLOWER}));
wire [7:0] writemask =  {8{storetype[2]}}&swwm|
                        {8{storetype[1]}}&shwm|
                        {8{storetype[0]}}&sbwm;
//setting the data in for each bank here
wire [31:0] storeworddata = datain;
wire [31:0] storehalfdata = {datain[15:0], datain[15:0]};
wire [31:0] storebytedata = {datain[7:0], datain[7:0], datain[7:0], datain[7:0]};
wire [31:0] databankin =    {32{storetype[2]}}&storeworddata|
                            {32{storetype[1]}}&storehalfdata|
                            {32{storetype[0]}}&storebytedata;
//memory bank initialization
    SB_SPRAM256KA bank0(
        .ADDRESS(INTaddress),
        .DATAIN(databankin[15:0]),
        .MASKWREN(writemask[3:0]),
        .WREN(internalwren),
        .CHIPSELECT(|storeloadec),
        .CLOCK(clkin),
        .STANDBY(`FALSE),
        .SLEEP(`FALSE),
        .POWEROFF(`TRUE),
        .DATAOUT(dataout[15:0]) //bank0 holds the lower 2 bytes 
    );
    SB_SPRAM256KA bank1(
        .ADDRESS(INTaddress),
        .DATAIN(databankin[31:16]),
        .MASKWREN(writemask[7:4]),
        .WREN(internalwren),
        .CHIPSELECT(|storeloadec),
        .CLOCK(clkin),
        .STANDBY(`FALSE),
        .SLEEP(`FALSE),
        .POWEROFF(`TRUE),
        .DATAOUT(dataout[31:16]) //bank1 holds the upper 2 bytes
    );
`endif
`ifdef TARGET_GENERIC //general fpga target and generic simulations
wire [11:0] INTaddress = address [13:2];
wire [1:0] INTtype = address [1:0]; //writemask, where each bit represents a byte inside the memory word
//using the same logic for writemasking as the ice40 uses
wire [3:0] swwm = 4'b1111;
wire [3:0] shwm = (INTtype[1])?(4'b1100):(4'b0011);
wire [3:0] sbwm = (INTtype[1])?((INTtype[0])?(4'b1000):(4'b0100)):((INTtype[0])?(4'b0010):(4'b0001));
wire [3:0] writemask =  {4{storetype[2]}}&swwm|
                        {4{storetype[1]}}&shwm|
                        {4{storetype[0]}}&sbwm;
wire [31:0] storeworddata = datain;
wire [31:0] storehalfdata = {datain[15:0], datain[15:0]};
wire [31:0] storebytedata = {datain[7:0], datain[7:0], datain[7:0], datain[7:0]};
wire [31:0] databankin =    {32{storetype[2]}}&storeworddata|
                            {32{storetype[1]}}&storehalfdata|
                            {32{storetype[0]}}&storebytedata;
//official memory
wire internalwren = WR_EN&(storeloadec[2]|storeloadec[0]);
reg [31:0] readregister;
reg [31:0] memword [0:4095];
assign dataout = readregister;
always@(posedge clkin)begin
    if(internalwren)begin
        if(writemask[3]) memword[INTaddress][31:24] <= databankin[31:24];
        if(writemask[2]) memword[INTaddress][23:16] <= databankin[23:16];
        if(writemask[1]) memword[INTaddress][15:8] <= databankin[15:8];
        if(writemask[0]) memword[INTaddress][7:0] <= databankin[7:0];
    end
    else readregister <= memword[INTaddress];
end
`endif
endmodule