// Base test class
class ahb_lite_base_test extends uvm_test;
    `uvm_component_utils(ahb_lite_base_test)
    
    ahb_lite_env env;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create environment
        env = ahb_lite_env::type_id::create("env", this);
        
    endfunction
    
    
    virtual function void report_phase(uvm_phase phase);
        uvm_report_server server;
        int error_count;
        
        super.report_phase(phase);
        server = get_report_server();
        error_count = server.get_severity_count(UVM_ERROR);
        
        if (error_count == 0) begin
            `uvm_info("TEST", "** TEST PASSED **", UVM_NONE)
        end else begin
            `uvm_error("TEST", $sformatf("** TEST FAILED - %0d ERRORS **", error_count))
        end
    endfunction
endclass


class random_test extends ahb_lite_base_test;
    `uvm_component_utils(random_test)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        random_write_sequence write_seq;
        random_read_sequence read_seq;
        random_mixed_sequence mixed_seq;
        
        phase.raise_objection(this);
        `uvm_info("TEST", "Starting random test", UVM_LOW)
        
        // Random writes
        write_seq = random_write_sequence::type_id::create("write_seq");
        if (!write_seq.randomize() with { num_transactions == 10; })
            `uvm_error("TEST", "Write seq randomization failed")
        write_seq.start(env.agent.sequencer);
        #50;
        
        // Random reads
        read_seq = random_read_sequence::type_id::create("read_seq");
        if (!read_seq.randomize() with { num_transactions == 10; })
            `uvm_error("TEST", "Read seq randomization failed")
        read_seq.start(env.agent.sequencer);
        #50;
        
        // Mixed operations
        mixed_seq = random_mixed_sequence::type_id::create("mixed_seq");
        if (!mixed_seq.randomize() with { num_transactions == 16; })
            `uvm_error("TEST", "Mixed seq randomization failed")
        mixed_seq.start(env.agent.sequencer);
        
        #100;
        phase.drop_objection(this);
    endtask
endclass
