module ahb_lite_slave (
    input wire         HCLK,
    input wire         HRESETn,
    input wire [31:0]  HADDR,
    input wire [1:0]   HTRANS,
    input wire         HWRITE,
    input wire [2:0]   HSIZE,
    input wire [31:0]  HWDATA,
    input wire         HREADY,  // from slave
    
    output reg [31:0]  HRDATA,
    output reg         HREADYOUT,
    output reg         HRESP
);

    // Internal memory
    reg [31:0] memory [0:1023]; //1kb memory(1024)
    
    // Internal signals
    reg [31:0] haddr_reg;
    reg [1:0]  htrans_reg;
    reg        hwrite_reg;
    reg [2:0]  hsize_reg;
    
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            haddr_reg  <= 32'h0;
            htrans_reg <= 2'b00;
            hwrite_reg <= 1'b0;
            hsize_reg  <= 3'b000;
            HRDATA     <= 32'h0;
            HREADYOUT  <= 1'b1;  // Always ready by default
            HRESP      <= 1'b0;  // OKAY response
        end 
        else if (HREADY) begin
            // Capture address phase signals
            haddr_reg  <= HADDR;
            htrans_reg <= HTRANS;
            hwrite_reg <= HWRITE;
            hsize_reg  <= HSIZE;
            
            // Handle data phase
            if (htrans_reg[1] && HREADYOUT) begin  // Only for valid transfers
                if (hwrite_reg) begin
                    // Write operation
                    if (haddr_reg < 1024) begin
                        case (hsize_reg)
                            3'b000: memory[haddr_reg][7:0]   <= HWDATA[7:0];    // Byte
                            3'b001: memory[haddr_reg][15:0]  <= HWDATA[15:0];   // Half-word
                            default: memory[haddr_reg]       <= HWDATA;         // Word
                        endcase
                        HRESP <= 1'b0; // OKAY
                    end
                    else begin
                        HRESP <= 1'b1; // ERROR - out of bounds
                    end
                end 
                else begin
                    // Read operation
                    if (haddr_reg < 1024) begin
                        HRDATA <= memory[haddr_reg];
                        HRESP <= 1'b0; // OKAY
                    end 
                    else begin
                        HRDATA <= 32'hDEADBEEF;
                        HRESP <= 1'b1; // ERROR
                end
              end
          end
        end
    end
endmodule
