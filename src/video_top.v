module TopModule (
    input i_clk,        // System clock
    input i_rst_n,      // Active low reset
    output o_lcd_CS,    // Chip select for LCD
    output o_lcd_A0,    // Register select (1 for data, 0 for command)
    output o_lcd_SDA,   // Serial data
    output o_lcd_CLK,   // Serial clock for LCD
    output o_lcd_RES,   // Active low reset for LCD
    output [7:0] debug_byte, // Debug output for checking transmitted byte
    output debug_reg
);

    // Signals for sending data to the controller
    wire [23:0] i_data = 24'hFF_00_00;  // Sending 0'h0 to the controller (16-bit data)
    wire o_cfg_finished;                // Signal for when configuration is finished

    // Instantiate the ST7735s_Controller
    ST7735s_Controller st7735s_controller_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_data(i_data),
        .i_data_valid(1'b1),
        .o_cfg_finished(o_cfg_finished),
        .o_lcd_CS(o_lcd_CS),
        .o_lcd_A0(o_lcd_A0),
        .o_lcd_SDA(o_lcd_SDA),
        .o_lcd_CLK(o_lcd_CLK),
        .o_lcd_RES(o_lcd_RES),
        .debug_byte(debug_byte),
        .debug_reg(debug_reg)
    );

endmodule
