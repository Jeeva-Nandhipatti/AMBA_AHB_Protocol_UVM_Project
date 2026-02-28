class ahb_lite_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ahb_lite_scoreboard)
    
    uvm_analysis_imp #(ahb_lite_seq_item, ahb_lite_scoreboard) item_collected_export;
    
    // Memory model for expected data
    bit [31:0] expected_memory [bit [31:0]];

    int transactions_checked = 0;
    int mismatches = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        expected_memory.delete(); // Clear memory
    endfunction
    
    virtual function void write(ahb_lite_seq_item transaction);
        `uvm_info("SCOREBOARD", $sformatf("Received transaction: %s", transaction.convert2string()), UVM_HIGH)
        
        transactions_checked++;
        
        if (transaction.hwrite) begin
            // Write transaction - store expected data
            case (transaction.hsize)
                3'b000: expected_memory[transaction.haddr] = {24'h0, transaction.hwdata[7:0]};    // Byte
                3'b001: expected_memory[transaction.haddr] = {16'h0, transaction.hwdata[15:0]};   // Half-word
                default: expected_memory[transaction.haddr] = transaction.hwdata;                 // Word
            endcase
            `uvm_info("SCOREBOARD", $sformatf("Stored expected data: addr=0x%0h, data=0x%0h", 
                                              transaction.haddr, expected_memory[transaction.haddr]), UVM_MEDIUM)
        end else begin
            // Read transaction - check against expected data
            if (expected_memory.exists(transaction.haddr)) begin
                bit [31:0] expected_data = expected_memory[transaction.haddr];
                if (transaction.hrdata !== expected_data) begin
                    `uvm_error("SCOREBOARD", $sformatf("Data mismatch! Addr=0x%0h, Expected=0x%0h, Actual=0x%0h",
                                                      transaction.haddr, expected_data, transaction.hrdata))
                    mismatches++;
                end else begin
                    `uvm_info("SCOREBOARD", $sformatf("Data match! Addr=0x%0h, Data=0x%0h", 
                                                     transaction.haddr, transaction.hrdata), UVM_MEDIUM)
                end
            end else if (transaction.htrans inside {2'b10, 2'b11}) begin
                // Valid read to uninitialized address
                `uvm_warning("SCOREBOARD", $sformatf("Read from uninitialized address: 0x%0h, Got: 0x%0h",
                                                    transaction.haddr, transaction.hrdata))
            end
        end
        
        // Check HRESP for errors
        if (transaction.hresp && transaction.htrans inside {2'b10, 2'b11}) begin
            `uvm_warning("SCOREBOARD", $sformatf("Slave returned ERROR response for addr=0x%0h", transaction.haddr))
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCOREBOARD", $sformatf("Scoreboard Summary: %0d transactions checked, %0d mismatches", 
                                         transactions_checked, mismatches), UVM_LOW)
        if (mismatches == 0) begin
            `uvm_info("SCOREBOARD", "TEST PASSED - All data matches!", UVM_NONE)
        end else begin
            `uvm_error("SCOREBOARD", $sformatf("TEST FAILED - %0d mismatches found!", mismatches))
        end
    endfunction
endclass
