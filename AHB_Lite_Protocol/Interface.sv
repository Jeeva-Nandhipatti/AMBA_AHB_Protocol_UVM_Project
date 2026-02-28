interface ahb_lite_if (input logic HCLK);
    logic [31:0]  HADDR;
    logic [1:0]   HTRANS;
    logic         HWRITE;
    logic [2:0]   HSIZE;
    logic [31:0]  HWDATA;
    logic [31:0]  HRDATA;
    logic         HREADY;
    logic         HRESP;
    logic         HRESETn;
      
    clocking driver_cb @(posedge HCLK);
        default input #1step output #0;  // Input sampled before edge, output driven at edge
        output HADDR, HTRANS, HWRITE, HSIZE, HWDATA;
        input  HRDATA, HREADY, HRESP, HRESETn;
    endclocking
    
    clocking monitor_cb @(posedge HCLK);
        default input #1step;
        input HADDR, HTRANS, HWRITE, HSIZE, HWDATA;
        input HRDATA, HREADY, HRESP, HRESETn;
    endclocking
    
    modport master_mp (
        clocking driver_cb,    // For driving signals
        input    HCLK          // Clock input
    );
    
    modport monitor_mp (
        clocking monitor_cb,   // For monitoring signals
        input    HCLK          // Clock input  
    );
    
    modport slave_mp (
        input  HADDR, HTRANS, HWRITE, HSIZE, HWDATA, HCLK, HRESETn,
        output HRDATA, HREADY, HRESP
    );

endinterface
