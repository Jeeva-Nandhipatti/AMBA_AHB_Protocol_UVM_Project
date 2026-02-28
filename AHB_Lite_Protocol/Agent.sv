class ahb_lite_agent extends uvm_agent;
    `uvm_component_utils(ahb_lite_agent)
    
    ahb_lite_sequencer   sequencer;
    ahb_lite_driver      driver;
    ahb_lite_monitor     monitor;
    
    uvm_analysis_port #(ahb_lite_seq_item) item_collected_port;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        monitor = ahb_lite_monitor::type_id::create("monitor", this);
        sequencer = ahb_lite_sequencer::type_id::create("sequencer", this);
        driver = ahb_lite_driver::type_id::create("driver", this);
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect monitor analysis port to agent analysis port
        monitor.item_collected_port.connect(item_collected_port);
        
        // Connect driver to sequencer
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass
