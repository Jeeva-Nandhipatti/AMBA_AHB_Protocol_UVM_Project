class ahb_lite_env extends uvm_env;
    `uvm_component_utils(ahb_lite_env)
    
    ahb_lite_agent       agent;
    ahb_lite_scoreboard  scoreboard;
    ahb_lite_coverage    coverage;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create components
        agent = ahb_lite_agent::type_id::create("agent", this);
        scoreboard = ahb_lite_scoreboard::type_id::create("scoreboard", this);
        coverage = ahb_lite_coverage::type_id::create("coverage", this);
        
    endfunction
    
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect agent to scoreboard and coverage
        agent.item_collected_port.connect(scoreboard.item_collected_export);
        agent.item_collected_port.connect(coverage.analysis_export);
    endfunction
endclass
