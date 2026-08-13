`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module top(
    output wire [2:0] led,
    output wire [7:0] gpio_out
);
reg [23:0] reset_cnt = 24'hfff_fff;
reg reset;
wire [2:0] state;
wire [1:0] flags;
wire clkin;
SB_HFOSC #(
    .CLKHF_DIV("0b10"))
u_SB_HFOSC(
    .CLKHFPU(`TRUE), 
    .CLKHFEN(`TRUE), 
    .CLKHF(clkin)
);
core C_RV_00(
    .clkin(clkin),
    .reset(reset),
    .state_out(state),
    .flags(flags),
    .gpio_core_out(gpio_out)
    );
always@(posedge clkin)begin
    if(reset_cnt>0)begin
        reset_cnt <= reset_cnt-1;
        reset <= `FALSE;
    end
    else begin
        reset <= `TRUE;
    end
end
  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(`TRUE),
    .RGB0PWM (state == 3'b111),
    .RGB1PWM (state == 3'b000),
    .RGB2PWM (|gpio_out),
    .CURREN  (`TRUE),
    .RGB0    (led[0]), //Actual Hardware connection
    .RGB1    (led[1]),
    .RGB2    (led[2])
  );
  defparam RGB_DRIVER.RGB0_CURRENT = "0b000001";
  defparam RGB_DRIVER.RGB1_CURRENT = "0b000001";
  defparam RGB_DRIVER.RGB2_CURRENT = "0b000001";
endmodule