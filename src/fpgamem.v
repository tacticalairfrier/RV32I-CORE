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
wire [13:0] INTaddress = address [15:2];
wire [1:0] INTtype = address [1:0];
// wire WR_EN = (storeloadec[2]|storeloadec[0])&isMemory; //write enable fires when the fsm state is memory and instruction type was store
`ifdef TARGET_SIM_ICE40UP5K
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
`elsif TARGET_ICE40UP5K //ice40up5k target
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
`elsif TARGET_SIM_GW2AR_LV18QN88_I7 //tang nano 2k sim target 
`elsif TARGET_GW2AR_LV18QN88_I7 //tang nano 20k target
`elsif TARGET_GENERIC //general fpga target
`else // general purpose fpga bram inferrence
`endif
endmodule