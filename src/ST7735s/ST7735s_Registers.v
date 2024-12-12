module ST7735s_Registers (
    input clk, 
    input resend, 
    input advance,
    output [8:0] command, 
    output finished,
    output [7:0] debug_addr
);

localparam [8:0] NOP       = 9'h000;  // No Operation
localparam [8:0] SWRESET   = 9'h001;  // Software Reset
localparam [8:0] RDDID     = 9'h004;  // Read Display ID
localparam [8:0] RDDST     = 9'h009;  // Read Display Status
localparam [8:0] RDDPM     = 9'h00A;  // Read Display Power Mode
localparam [8:0] RDDMADCTL = 9'h00B;  // Read Display MADCTL
localparam [8:0] RDDCOLMOD = 9'h00C;  // Read Display Pixel Format
localparam [8:0] RDDIM     = 9'h00D;  // Read Display Image Mode
localparam [8:0] RDDSM     = 9'h00E;  // Read Display Signal Mode
localparam [8:0] RDDSDR    = 9'h00F;  // Read Display Self-Diagnostic Result
localparam [8:0] SLPIN     = 9'h010;  // Sleep In
localparam [8:0] SLPOUT    = 9'h011;  // Sleep Out
localparam [8:0] PTLON     = 9'h012;  // Partial Display Mode On
localparam [8:0] NORON     = 9'h013;  // Normal Display Mode On
localparam [8:0] INVOFF    = 9'h020;  // Display Inversion Off
localparam [8:0] INVON     = 9'h021;  // Display Inversion On
localparam [8:0] GAMSET    = 9'h026;  // Gamma Set
localparam [8:0] DISPOFF   = 9'h028;  // Display Off
localparam [8:0] DISPON    = 9'h029;  // Display On
localparam [8:0] CASET     = 9'h02A;  // Column Address Set
localparam [8:0] RASET     = 9'h02B;  // Row Address Set
localparam [8:0] RAMWR     = 9'h02C;  // Memory Write
localparam [8:0] RGBSET    = 9'h02D;  // Color Setting 4k, 65k, 262k
localparam [8:0] RAMRD     = 9'h02E;  // Memory Read
localparam [8:0] PTLAR     = 9'h030;  // Partial Area
localparam [8:0] SCRLAR    = 9'h033;  // Scroll Area Set
localparam [8:0] TEOFF     = 9'h034;  // Tearing Effect Line OFF
localparam [8:0] TEON      = 9'h035;  // Tearing Effect Line ON
localparam [8:0] MADCTL    = 9'h036;  // Memory Data Access Control
localparam [8:0] VSCSAD    = 9'h037;  // Vertical Scroll Start Address of RAM
localparam [8:0] IDMOFF    = 9'h038;  // Idle Mode Off
localparam [8:0] IDMON     = 9'h039;  // Idle Mode On
localparam [8:0] COLMOD    = 9'h03A;  // Interface Pixel Format
localparam [8:0] RDID1     = 9'h0DA;  // Read ID1 Value
localparam [8:0] RDID2     = 9'h0DB;  // Read ID2 Value
localparam [8:0] RDID3     = 9'h0DC;  // Read ID3 Value
localparam [8:0] FRMCTR1   = 9'h0B1;  // Frame Rate Control in normal mode, full colors
localparam [8:0] FRMCTR2   = 9'h0B2;  // Frame Rate Control in idle mode, 8 colors
localparam [8:0] FRMCTR3   = 9'h0B3;  // Frame Rate Control in partial mode, full colors
localparam [8:0] INVCTR    = 9'h0B4;  // Display Inversion Control
localparam [8:0] PWCTR1    = 9'h0C0;  // Power Control 1
localparam [8:0] PWCTR2    = 9'h0C1;  // Power Control 2
localparam [8:0] PWCTR3    = 9'h0C2;  // Power Control 3 in normal mode, full colors
localparam [8:0] PWCTR4    = 9'h0C3;  // Power Control 4 in idle mode 8 colors
localparam [8:0] PWCTR5    = 9'h0C4;  // Power Control 5 in partial mode, full colors
localparam [8:0] VMCTR1    = 9'h0C5;  // VCOM Control 1
localparam [8:0] VMOFCTR   = 9'h0C7;  // VCOM Offset Control
localparam [8:0] WRID2     = 9'h0D1;  // Write ID2 Value
localparam [8:0] WRID3     = 9'h0D2;  // Write ID3 Value
localparam [8:0] NVFCTR1   = 9'h0D9;  // NVM Control Status
localparam [8:0] NVFCTR2   = 9'h0DE;  // NVM Read Command
localparam [8:0] NVFCTR3   = 9'h0DF;  // NVM Write Command
localparam [8:0] GMCTRP1   = 9'h0E0;  // Gamma '+'Polarity Correction Characteristics Setting
localparam [8:0] GMCTRN1   = 9'h0E1;  // Gamma '-'Polarity Correction Characteristics Setting
localparam [8:0] GCV       = 9'h0FC;  // Gate Pump Clock Frequency Variable

    // Internal signals
    reg [8:0] sreg;
    reg finished_temp;
    reg [7:0] address = 8'b0;
    
    // Assign values to outputs
    assign command = sreg; 
    assign finished = finished_temp;
    
    // When register and value is FFFF
    // a flag is asserted indicating the configuration is finished
    always @ (sreg) begin
        if(sreg == NOP) begin
            finished_temp <= 1;
        end
        else begin
            finished_temp <= 0;
        end
    end

    localparam defHEIGHT = 8'd120;
    localparam defWIDTH = 8'd160;

    reg advance_prev;  // Register to hold the previous state of `advance`

    always @(posedge clk) begin
        advance_prev <= advance;  // Register the `advance` signal
    end

    wire advance_rising_edge = advance & ~advance_prev;  // Detect rising edge
    
    // Get value out of the LUT
    always @(posedge clk) begin
        if (resend) begin
            address <= 8'b0;  // Reset the address on `resend`
        end else if (advance_rising_edge) begin
            address <= address + 1;  // Increment only on rising edge
        end
           
        case (address)
            // SWRESET Sequence
            0   : sreg <= SWRESET;        // Software Reset

            // SLPOUT Sequence
            1   : sreg <= SLPOUT;         // Sleep Out

            // DISPOFF Sequence
            2   : sreg <= DISPOFF;        // Display Off

            // FRMCTR1 Sequence
            3   : sreg <= FRMCTR1;        // Frame Rate Control 1
            4   : sreg <= 9'b1_00000000; // Data
            5   : sreg <= 9'b1_00111111; // Data
            6   : sreg <= 9'b1_00111111; // Data

            // FRMCTR2 Sequence
            7   : sreg <= FRMCTR2;        // Frame Rate Control 2
            8   : sreg <= 9'b1_00001111; // Data
            9   : sreg <= 9'h1_01;       // Data
            10  : sreg <= 9'h1_01;       // Data

            // FRMCTR3 Sequence
            11  : sreg <= FRMCTR3;        // Frame Rate Control 3
            12  : sreg <= 9'h1_05;       // Data
            13  : sreg <= 9'h1_3C;       // Data
            14  : sreg <= 9'h1_3C;       // Data
            15  : sreg <= 9'h1_05;       // Data
            16  : sreg <= 9'h1_3C;       // Data
            17  : sreg <= 9'h1_3C;       // Data

            // INVCTR Sequence
            18  : sreg <= INVCTR;         // Display Inversion Control
            19  : sreg <= 9'h1_03;       // Data

            // PWCTR1 Sequence
            20  : sreg <= PWCTR1;         // Power Control 1
            21  : sreg <= 9'h1_FC;       // Data
            22  : sreg <= 9'h1_08;       // Data
            23  : sreg <= 9'h1_10;

            // PWCTR2 Sequence
            24  : sreg <= PWCTR2;         // Power Control 2
            25  : sreg <= 9'h1_C0;       // Data

            // PWCTR3 Sequence
            26  : sreg <= PWCTR3;         // Power Control 3
            27  : sreg <= 9'h1_0D;       // Data
            28  : sreg <= 9'h1_00;       // Data

            // PWCTR4 Sequence
            29  : sreg <= PWCTR4;         // Power Control 4
            30  : sreg <= 9'h1_8D;       // Data
            31  : sreg <= 9'h1_2A;       // Data

            // PWCTR5 Sequence
            32  : sreg <= PWCTR5;         // Power Control 5
            33  : sreg <= 9'h1_8D;       // Data
            34  : sreg <= 9'h1_EE;       // Data

            // GCV Sequence
            35  : sreg <= GCV;            // Gate Pump Clock Frequency Variable
            36  : sreg <= 9'b1_1101_1000;       // Data

            // NVFCTR1 Sequence
            37  : sreg <= NVFCTR1;        // NVM Control Status
            38  : sreg <= 9'h1_40;       // Data

            // VMCTR1 Sequence
            39  : sreg <= VMCTR1;         // VCOM Control 1
            40  : sreg <= 9'h1_0F;       // Data

            // VMOFCTR Sequence
            41  : sreg <= VMOFCTR;        // VCOM Offset Control
            42  : sreg <= 9'h1_10;       // Data

            // GAMSET Sequence
            43  : sreg <= GAMSET;         // Gamma Set
            44  : sreg <= 9'h1_08;       // Data

            // MADCTL Sequence
            45  : sreg <= MADCTL;         // Memory Data Access Control
            46  : sreg <= 9'h1_60;       // Data

            // COLMOD Sequence
            47  : sreg <= COLMOD;         // Interface Pixel Format
            48  : sreg <= 9'h1_06;       // Data

            // GMCTRP1 Sequence
            49  : sreg <= GMCTRP1;        // Gamma '+' Polarity Correction
            50  : sreg <= 9'h1_02;       // Data
            51  : sreg <= 9'h1_1C;       // Data
            52  : sreg <= 9'h1_07;       // Data
            53  : sreg <= 9'h1_12;       // Data
            54  : sreg <= 9'h1_37;       // Data
            55  : sreg <= 9'h1_32;       // Data
            56  : sreg <= 9'h1_29;       // Data
            57  : sreg <= 9'h1_2C;       // Data
            58  : sreg <= 9'h1_29;       // Data
            59  : sreg <= 9'h1_25;       // Data
            60  : sreg <= 9'h1_2B;       // Data
            61  : sreg <= 9'h1_39;       // Data
            62  : sreg <= 9'h1_00;       // Data
            63  : sreg <= 9'h1_01;       // Data
            64  : sreg <= 9'h1_03;       // Data
            65  : sreg <= 9'h1_10;       // Data

            // GMCTRN1 Sequence
            66  : sreg <= GMCTRN1;        // Gamma '-' Polarity Correction
            67  : sreg <= 9'h1_03;       // Data
            68  : sreg <= 9'h1_1D;       // Data
            69  : sreg <= 9'h1_07;       // Data
            70  : sreg <= 9'h1_06;       // Data
            71  : sreg <= 9'h1_2E;       // Data
            72  : sreg <= 9'h1_2C;       // Data
            73  : sreg <= 9'h1_29;       // Data
            74  : sreg <= 9'h1_2C;       // Data
            75  : sreg <= 9'h1_2E;       // Data
            76  : sreg <= 9'h1_2E;       // Data
            77  : sreg <= 9'h1_37;       // Data
            78  : sreg <= 9'h1_3F;       // Data
            79  : sreg <= 9'h1_00;       // Data
            80  : sreg <= 9'h1_00;       // Data
            81  : sreg <= 9'h1_02;       // Data
            82  : sreg <= 9'h1_10;       // Data

            83  : sreg <= CASET;
            84  : sreg <= 9'h1_00;
            85  : sreg <= 9'h1_00;
            86  : sreg <= 9'h1_00;
            87  : sreg <= {1'b1, defHEIGHT - 8'b1};

            88  : sreg <= RASET;
            89  : sreg <= 9'h1_00;
            90  : sreg <= 9'h1_00;
            91  : sreg <= 9'h1_00;
            92  : sreg <= {1'b1, defWIDTH - 8'b1};

            // Final Initialization Commands
            93  : sreg <= INVOFF;         // Display Inversion Off
            94  : sreg <= IDMOFF;         // Idle Mode Off
            95  : sreg <= NORON;          // Normal Display Mode On
            96  : sreg <= DISPON;         // Display On

            // Pixel Writing
            97  : sreg <= RAMWR;

            default : sreg <= NOP;
        endcase
    end 

assign debug_addr = address;

endmodule               
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        