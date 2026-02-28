class ahb_lite_driver extends uvm_driver #(ahb_lite_seq_item);
    `uvm_component_utils(ahb_lite_driver)
    
    virtual ahb_lite_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ahb_lite_if)::get(this, "", "ahb_lite_vif", vif)) begin
            `uvm_fatal("BUILD", "Cannot get AHB-Lite interface in driver")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ahb_lite_seq_item req;
        reset_signals();
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask
    
    virtual task reset_signals();
        // Initialize all outputs to idle state
        vif.driver_cb.HADDR  <= 32'h0;
        vif.driver_cb.HTRANS <= 2'b00; // IDLE
        vif.driver_cb.HWRITE <= 1'b0;
        vif.driver_cb.HSIZE  <= 3'b000;
        vif.driver_cb.HWDATA <= 32'h0;
        
        // Wait for reset to de-assert
        wait (vif.driver_cb.HRESETn === 1'b1);
    endtask
    
    virtual task drive_transfer(ahb_lite_seq_item item);
        `uvm_info("DRIVER", $sformatf("Starting transfer: %s", item.convert2string()), UVM_MEDIUM)
        
        // Wait for HREADY before starting new transfer
        if (vif.driver_cb.HREADY !== 1'b1) begin
          @(vif.driver_cb);  // Wait for next clocking block event
        end
        
        // Drive address phase on current clock edge
        vif.driver_cb.HADDR  <= item.haddr;
        vif.driver_cb.HTRANS <= item.htrans;
        vif.driver_cb.HWRITE <= item.hwrite;
        vif.driver_cb.HSIZE  <= item.hsize;
        
        // For write transfers, drive data on next cycle
        if (item.hwrite) begin
            @(vif.driver_cb);  // Wait one clock cycle using clocking block
            vif.driver_cb.HWDATA <= item.hwdata;
            `uvm_info("DRIVER", $sformatf("Driving write data: 0x%0h", item.hwdata), UVM_MEDIUM)
        end
        
        // Wait for transfer completion and capture response
        item.hrdata = vif.driver_cb.HRDATA;
        item.hresp  = vif.driver_cb.HRESP;
        item.hready = vif.driver_cb.HREADY;
        
        `uvm_info("DRIVER", $sformatf("Completed transfer: %s", item.convert2string()), UVM_MEDIUM)
    endtask
endclass
