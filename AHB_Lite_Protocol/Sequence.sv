class ahb_lite_base_sequence extends uvm_sequence #(ahb_lite_seq_item);
    `uvm_object_utils(ahb_lite_base_sequence)
    
    function new(string name = "ahb_lite_base_sequence");
        super.new(name);
    endfunction
    
    virtual task pre_body();
        if (starting_phase != null) begin
            starting_phase.raise_objection(this);
        end
    endtask
    
    virtual task post_body();
        if (starting_phase != null) begin
            starting_phase.drop_objection(this);
        end
    endtask
endclass

// Simple single write sequence
class random_write_sequence extends ahb_lite_base_sequence;
    `uvm_object_utils(random_write_sequence)
    
    rand int num_transactions;

    function new(string name = "random_write_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info("SEQ", $sformatf("Starting %0d random writes", num_transactions), UVM_LOW)
        
        repeat (num_transactions) begin
            req = ahb_lite_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                htrans != 2'b00; // No IDLE cycles
                hwrite == 1'b1;  // Only writes
                haddr inside {[0:1023]};
            }) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            finish_item(req);
        end
    endtask
endclass

// Simple single read sequence
class random_read_sequence extends ahb_lite_base_sequence;
    `uvm_object_utils(random_read_sequence)
    
    rand int num_transactions;
    
    function new(string name = "random_read_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info("SEQ", $sformatf("Starting %0d random read transactions", num_transactions), UVM_LOW)
        
        repeat (num_transactions) begin
            req = ahb_lite_seq_item::type_id::create("req");
            start_item(req);
            
            if (!req.randomize() with {
                htrans inside {[2'b10:2'b11]}; // Only NONSEQ and SEQ
                hwrite == 1'b0;                // Read operations only  
                haddr  inside {[0:1023]};      // Within memory range
                hsize  inside {0, 1, 2};       // Valid sizes
            }) begin
                `uvm_error("SEQ", "Read transaction randomization failed")
            end
            finish_item(req);
            
            `uvm_info("SEQ", $sformatf("Read: addr=0x%0h, data=0x%0h, size=%0d", 
                                      req.haddr, req.hrdata, req.hsize), UVM_HIGH)
        end
    endtask
endclass


// Mixed read/write sequence
class random_mixed_sequence extends ahb_lite_base_sequence;
    `uvm_object_utils(random_mixed_sequence)
    
    rand int num_transactions;
    
    function new(string name = "random_mixed_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info("SEQ", $sformatf("Starting %0d random mixed R/W transactions", num_transactions), UVM_LOW)
        
        repeat (num_transactions) begin
            req = ahb_lite_seq_item::type_id::create("req");
            start_item(req);
            
            if (!req.randomize() with {
                htrans inside {[2'b10:2'b11]}; // Valid transfers only
                hwrite dist {0:/50, 1:/50};    // 50% read, 50% write
                haddr  inside {[0:1023]};      // Within memory range
                hsize  inside {0, 1, 2};       // Valid sizes
                if (hwrite == 1) {
                    hwdata inside {[1:32'hFFFF_FFFF]}; // Non-zero for writes
                }
            }) begin
                `uvm_error("SEQ", "Mixed transaction randomization failed")
            end
            finish_item(req);
            
            if (req.hwrite) begin
                `uvm_info("SEQ", $sformatf("Write: addr=0x%0h, data=0x%0h", 
                                          req.haddr, req.hwdata), UVM_HIGH)
            end else begin
                `uvm_info("SEQ", $sformatf("Read: addr=0x%0h, data=0x%0h", 
                                          req.haddr, req.hrdata), UVM_HIGH)
            end
        end
    endtask
endclass
