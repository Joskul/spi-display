module ST7735s_Controller (
    input i_clk,             // System clock
    input i_rst_n,           // Active low reset
    input [23:0] i_data,     // 3 bytes of data to be sent to LCD (24 bits)
    input i_data_valid,
    output o_cfg_finished,   // Done signal for operation completion
    output o_rx_ready,       // Ready to receive

    output o_lcd_CS,         // Chip select for LCD
    output o_lcd_A0,         // Register select (1 for data, 0 for command)
    output o_lcd_SDA,        // Serial data (COPI)
    output o_lcd_CLK,        // Serial clock for LCD
    output o_lcd_RES,        // Active low reset

    output [7:0] debug_byte, // Debug output to monitor transmitted byte
    output debug_reg
);

reg [23:0] r_data_reg;     // Local register to store input data
reg [1:0] r_data_state;    // 2-bit state: 00 -> First byte, 01 -> Second byte, 10 -> Third byte
reg r_tx_dv;               // Data valid for transmission
wire r_tx_ready;           // Transmission ready signal from SPI
wire r_rx_dv;              // Data valid from SPI (not used here)
wire [7:0] r_rx_byte;      // Received byte from SPI (not used here)
reg [8:0] r_command;       // Command register

// Configuration wires
wire r_cfg_finished;
reg r_resend;              // Resend configuration pulse
reg r_cfg_adv;             // Advance configuration

reg r_busy;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        r_resend <= 1'b1; // Set resend high on reset
    end else begin
        r_resend <= 1'b0; // Clear resend after configuration
    end
end

// State machine to handle the transmission of 3 bytes of data
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        r_tx_dv <= 0;
        r_command <= 9'b0;  // Default to config
        r_data_state <= 2'b00; // Start with first byte
        r_data_reg <= 24'b0;   // Initialize the local register
        r_cfg_adv <= 0;       // Initialize configuration advance signal
        r_busy <= 0;
    end else if (!r_cfg_finished) begin
        r_busy <= 1;
        r_cfg_adv <= r_tx_ready; // Pulse to advance configuration
        if (r_tx_ready) begin
            r_command <= r_cfg_cmd;  // Configuration data
            r_tx_dv <= 1;             // Ready to transmit
        end else begin
            r_tx_dv <= 0;
        end
    end else begin
        if (!r_busy && i_data_valid) begin
            r_data_reg <= i_data; // Latch input data
            r_busy <= 1'b1;       // Mark module as busy
        end

        // Handle data transmission
        if (r_busy && r_tx_ready) begin
            case (r_data_state)
                2'b00: begin
                    r_command <= {1'b1, r_data_reg[23:16]}; // Send 1st byte
                    r_data_state <= 2'b01;                 // Move to next byte
                end
                2'b01: begin
                    r_command <= {1'b1, r_data_reg[15:8]};  // Send 2nd byte
                    r_data_state <= 2'b10;                 // Move to next byte
                end
                2'b10: begin
                    r_command <= {1'b1, r_data_reg[7:0]};   // Send 3rd byte
                    r_data_state <= 2'b00;                 // Reset state after last byte sent
                    
                    // De-assert CS after sending the last byte and mark module as ready 
                    r_busy <= 1'b0;                        // Mark module as ready 
                end
            endcase
            
            r_tx_dv <= 1'b1;  // Set data valid for SPI transmission
            
        end else begin
            r_tx_dv <= 1'b0;      // Clear data valid if not ready 
        end 
    end 
end

// Register select signal for command/data mode 
reg r_cmd_mode;
always @(posedge i_clk or negedge i_rst_n) begin 
    if (!i_rst_n) begin 
        r_cmd_mode <= 0;    // Default to command mode 
    end else begin 
        r_cmd_mode <= r_command[8]; 
    end 
end 
assign o_lcd_A0 = r_cmd_mode;

// SPI Master instantiation 
SPI_Master #(
    .SPI_MODE(0),           // Adjust according to your LCD's SPI mode 
    .CLKS_PER_HALF_BIT(2)  // Adjust the clock speed as necessary
) spi_master_inst (
    .i_Rst_L(i_rst_n),
    .i_Clk(i_clk),
    .i_TX_Byte(r_command[7:0]),
    .i_TX_DV(r_tx_dv),
    .o_TX_Ready(r_tx_ready),
    .o_RX_DV(),            // Not used 
    .o_RX_Byte(),         // Not used 
    .o_SPI_Clk(o_lcd_CLK),
    .i_SPI_MISO(1'b0),      // SPI_MISO is not used (it's a master)
    .o_SPI_MOSI(o_lcd_SDA)
//   .o_SPI_CS_n(o_lcd_CS)
);

// Configuration LUT for sending initial commands 
wire [8:0] r_cfg_cmd;
wire [7:0] r_cfg_addr;
ST7735s_Registers LUT (
    .clk(i_clk),
    .resend(r_resend),
    .advance(r_cfg_adv),
    .command(r_cfg_cmd),
    .finished(r_cfg_finished),
    .debug_addr(r_cfg_addr)
);

// Output signals 
assign o_cfg_finished = r_cfg_finished;
// assign o_lcd_CS = (r_busy && r_tx_dv && i_rst_n);
assign o_lcd_CS = r_tx_dv;
assign o_lcd_RES = i_rst_n;   // Active low reset based on resend signal 
assign o_rx_ready = !r_busy;

assign debug_byte = r_command[7:0]; 
// assign debug_byte = r_cfg_addr; 
assign debug_reg  = r_cmd_mode;
// assign debug_reg = r_cfg_adv;

endmodule 