module SPI_Master_CS
  #(parameter SPI_MODE = 0,
    parameter CLKS_PER_HALF_BIT = 2,
    parameter MAX_BYTES_PER_CS = 2,
    parameter CS_INACTIVE_CLKS = 1)
  (
   // Control/Data Signals,
   input        i_Rst_L,     // FPGA Reset
   input        i_Clk,       // FPGA Clock
   
   // TX (MOSI) Signals
   input [$clog2(MAX_BYTES_PER_CS+1)-1:0] i_TX_Count,  // # bytes per CS low
   input [7:0]  i_TX_Byte,       // Byte to transmit on MOSI
   input        i_TX_DV,         // Data Valid Pulse with i_TX_Byte
   output       o_TX_Ready,      // Transmit Ready for next byte
   
   // RX (MISO) Signals
   output reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] o_RX_Count,  // Index RX byte
   output       o_RX_DV,     // Data Valid pulse (1 clock cycle)
   output [7:0] o_RX_Byte,   // Byte received on MISO

   // SPI Interface
   output o_SPI_Clk,
   input  i_SPI_MISO,
   output o_SPI_MOSI,
   output o_SPI_CS_n
   );

  localparam IDLE        = 2'b00;
  localparam ASSERT_CS   = 2'b01;
  localparam TRANSFER    = 2'b10;
  localparam DEASSERT_CS = 2'b11;

  reg [1:0] r_SM_CS;
  reg r_CS_n;
  reg [$clog2(MAX_BYTES_PER_CS)-1:0] r_TX_Count;
  reg [31:0] r_CS_Inactive_Timer;
  wire w_Master_Ready;

  // Instantiate Master
  SPI_Master 
    #(.SPI_MODE(SPI_MODE),
      .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT)
      ) SPI_Master_Inst
   (
   // Control/Data Signals,
   .i_Rst_L(i_Rst_L),     // FPGA Reset
   .i_Clk(i_Clk),         // FPGA Clock
   
   // TX (MOSI) Signals
   .i_TX_Byte(i_TX_Byte),         // Byte to transmit
   .i_TX_DV(i_TX_DV),             // Data Valid Pulse 
   .o_TX_Ready(w_Master_Ready),   // Transmit Ready for Byte
   
   // RX (MISO) Signals
   .o_RX_DV(o_RX_DV),       // Data Valid pulse (1 clock cycle)
   .o_RX_Byte(o_RX_Byte),   // Byte received on MISO

   // SPI Interface
   .o_SPI_Clk(o_SPI_Clk),
   .i_SPI_MISO(i_SPI_MISO),
   .o_SPI_MOSI(o_SPI_MOSI)
   );

  always @(posedge i_Clk or negedge i_Rst_L)
  begin
    if (~i_Rst_L)
    begin
      r_SM_CS <= IDLE;
      r_CS_n  <= 1'b1;    // Resets to high (inactive)
      r_TX_Count <= 0;
      r_CS_Inactive_Timer <= 0;
    end
    else
    begin
      case (r_SM_CS)      
      IDLE:
        begin
          if (r_CS_n & i_TX_DV) // Start of transmission if CS is high and data is valid
          begin
            r_TX_Count <= i_TX_Count; // Register TX Count
            r_CS_n     <= 1'b0;       // Drive CS low for first byte transmission
            r_SM_CS    <= TRANSFER;  // Move to transfer state
          end
        end

      TRANSFER:
        begin
          if (w_Master_Ready) 
          begin
            if (r_TX_Count > 0)
            begin
              r_TX_Count <= r_TX_Count - 1'b1; // Decrement count for each byte sent

              if (r_TX_Count == 1) 
              begin 
                r_SM_CS <= DEASSERT_CS; // Deassert CS after last byte is sent
              end 
              else
              begin
                r_SM_CS <= DEASSERT_CS; // Pulse CS between bytes
              end
            end 
          end 
        end 

      DEASSERT_CS:
        begin
          r_CS_n <= 1'b1; // Deassert CS
          if (r_CS_Inactive_Timer < CS_INACTIVE_CLKS)
          begin
            r_CS_Inactive_Timer <= r_CS_Inactive_Timer + 1;
          end
          else
          begin
            r_CS_Inactive_Timer <= 0;
            if (r_TX_Count > 0)
            begin
              r_CS_n <= 1'b0; // Assert CS again for the next byte
              r_SM_CS <= TRANSFER;
            end
            else
            begin
              r_SM_CS <= IDLE; // Return to IDLE if no more bytes
            end
          end
        end

      default:
        begin
          r_CS_n <= 1'b1;                 // Set CS high in default case 
          r_SM_CS <= IDLE;
        end 
      endcase 
    end 
  end 

  assign o_SPI_CS_n = r_CS_n;           // Output the CS signal as active low

  assign o_TX_Ready = (r_SM_CS == IDLE) | (r_SM_CS == TRANSFER && w_Master_Ready && r_TX_Count > 0);

endmodule // SPI_Master_With_Single_CS
