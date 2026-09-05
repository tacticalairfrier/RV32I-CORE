`default_nettype none
`define TRUE 1'b1
`define FALSE 1'b0

module top(
    input wire clock_source,
    output wire [2:0] led,
    output wire [7:0] gpio_out
);
wire reset;
wire clkin;
pll clkgen(
    .clock_in(clock_source),
    .clock_out(clkin),
    .locked(reset)
);
core C_RV_00(
    .clkin(clkin),
    .reset(reset),
    .gpio_core_out(gpio_out)
);
  SB_RGBA_DRV RGB_DRIVER (
    .RGBLEDEN(`TRUE),
    .RGB0PWM (`FALSE),
    .RGB1PWM (~reset),
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