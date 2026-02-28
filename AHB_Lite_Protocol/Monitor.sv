class ahb_lite_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_lite_monitor)
    
    virtual ahb_lite_if vif;
    uvm_analysis_port #(ahb_lite_seq_item) item_collected_port;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Get virtual interface directly from config DB
        if (!uvm_config_db#(virtual ahb_lite_if)::get(this, "", "ahb_lite_vif", vif)) begin
            `uvm_fatal("BUILD", "Cannot get AHB-Lite interface in monitor")
        end
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        ahb_lite_seq_item trans;
        
        forever begin
            trans = ahb_lite_seq_item::type_id::create("trans");
            collect_transfer(trans);
            `uvm_info("MONITOR", $sformatf("Collected transaction: %s", trans.convert2string()), UVM_MEDIUM)
            item_collected_port.write(trans);
        end
    endtask
    
    virtual task collect_transfer(ahb_lite_seq_item trans);
        // Wait for a valid transfer (NONSEQ or SEQ)
        do begin
            @(vif.monitor_cb);
        end while (!(vif.monitor_cb.HTRANS inside {2'b10, 2'b11} && vif.monitor_cb.HREADY));
        
        // Capture address phase information
        trans.haddr  = vif.monitor_cb.HADDR;
        trans.htrans = vif.monitor_cb.HTRANS;
        trans.hwrite = vif.monitor_cb.HWRITE;
        trans.hsize  = vif.monitor_cb.HSIZE;
        trans.hwdata = vif.monitor_cb.HWDATA;
        
        // Wait for data phase completion
        do begin
            @(vif.monitor_cb);
        end while (!vif.monitor_cb.HREADY);
        
        // Capture data phase information
        trans.hrdata = vif.monitor_cb.HRDATA;
        trans.hresp  = vif.monitor_cb.HRESP;
        trans.hready = vif.monitor_cb.HREADY;
    endtask
endclass
