`include "uvm_macros.svh" 
import uvm_pkg::*; 
`include "Interface.sv"
 import tb_pkg::*; 

module tb_top;
    logic HCLK;
    logic HRESETn;
    
    // Instantiate interface
    ahb_lite_if ahb_if(HCLK);
    
    // Instantiate DUT
    ahb_lite_slave dut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HADDR(ahb_if.HADDR),
        .HTRANS(ahb_if.HTRANS),
        .HWRITE(ahb_if.HWRITE),
        .HSIZE(ahb_if.HSIZE),
        .HWDATA(ahb_if.HWDATA),
        .HREADY(ahb_if.HREADY),
        .HRDATA(ahb_if.HRDATA),
        .HREADYOUT(ahb_if.HREADY),
        .HRESP(ahb_if.HRESP)
    );
    
    // Clock generation
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end
    
    // Reset generation
    initial begin
        HRESETn = 0;
        ahb_if.HRESETn = 0;
        #20;
        HRESETn = 1;
        ahb_if.HRESETn = 1;
    end
    
    initial begin
     uvm_config_db#(virtual ahb_lite_if)::set(null, "uvm_test_top.env.agent.*", "ahb_lite_vif", ahb_if);
        
        // Run test
        run_test("random_test");
    end
    
    // End simulation after timeout
    initial begin
        #10000;
        $display("Simulation timeout - stopping test");
        $finish;
    end
endmodule
