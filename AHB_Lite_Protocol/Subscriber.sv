class ahb_lite_coverage extends uvm_subscriber #(ahb_lite_seq_item);
    `uvm_component_utils(ahb_lite_coverage)
    
    ahb_lite_seq_item cov_trans;
    
    covergroup ahb_transaction_cg;
        option.per_instance = 1;
        
        // Address coverage
        address_cp: coverpoint cov_trans.haddr {
            bins low_addr    = {[0:32'h0000_0FFF]};
            bins mid_addr    = {[32'h0000_1000:32'h0000_FFFF]};
            bins high_addr   = {[32'h0001_0000:32'hFFFF_FFFF]};
        }
        
        // Transfer type coverage
        trans_cp: coverpoint cov_trans.htrans {
            bins idle    = {2'b00};
            bins nonseq  = {2'b10};
            bins seq     = {2'b11};
            illegal_bins illegal = {2'b01}; // BUSY not supported in AHB-Lite
        }
        
        // Read/Write coverage
        rw_cp: coverpoint cov_trans.hwrite {
            bins read  = {0};
            bins write = {1};
        }
        
        // Size coverage
        size_cp: coverpoint cov_trans.hsize {
            bins byte1 = {0};
            bins halfword = {1};
            bins word = {2};
            illegal_bins illegal_sizes = {[3:7]};
        }
        
        // Response coverage
        resp_cp: coverpoint cov_trans.hresp {
            bins okay = {0};
            bins error = {1};
        }
        
        // Cross coverage
        rw_x_size: cross rw_cp, size_cp;
        trans_x_rw: cross trans_cp, rw_cp;
        addr_x_rw: cross address_cp, rw_cp;
        
    endgroup
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ahb_transaction_cg = new;
    endfunction
    
    virtual function void write(ahb_lite_seq_item t);
        cov_trans = t;
        // Only sample valid transactions (not IDLE)
        if (t.htrans inside {2'b10, 2'b11}) begin
            ahb_transaction_cg.sample();
            `uvm_info("COVERAGE", $sformatf("Sampled coverage for transaction"), UVM_HIGH)
        end
    endfunction
    
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COVERAGE", $sformatf("Coverage Summary: %.2f%%", ahb_transaction_cg.get_coverage()), UVM_LOW)
    endfunction
endclass
