class ahb_lite_seq_item extends uvm_sequence_item;
  `uvm_object_utils(ahb_lite_seq_item)
    
    // Address Phase
    rand bit [31:0]  haddr;
    rand bit [1:0]   htrans;
    rand bit         hwrite;
    rand bit [2:0]   hsize;
    rand bit [31:0]  hwdata;
    
    // Data Phase (response from slave)
    bit [31:0] hrdata;
    bit        hready;
    bit        hresp;
    
    // Timing control
    rand int cycles_before_ready;
    
    // Constraints
    constraint valid_transfers {
        htrans inside {2'b00, 2'b10, 2'b11}; // IDLE, NONSEQ, SEQ
        hsize inside {3'b000, 3'b001, 3'b010}; // Byte, Half-word, Word
        cycles_before_ready inside {[0:3]};
    }
    
  function new(string name = "ahb_lite_seq_item");
        super.new(name);
    endfunction
    
    function string convert2string();
        return $sformatf("HTRANS=%0b HWRITE=%0b HADDR=0x%0h HWDATA=0x%0h HSIZE=%0d HRDATA=0x%0h HREADY=%0b HRESP=%0b", 
                        htrans, hwrite, haddr, hwdata, hsize, hrdata, hready, hresp);
    endfunction
    
    function void do_copy(uvm_object rhs);
        ahb_lite_seq_item rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("DO_COPY", "Cast failed")
            return;
        end
        super.do_copy(rhs);
        this.haddr  = rhs_.haddr;
        this.htrans = rhs_.htrans;
        this.hwrite = rhs_.hwrite;
        this.hsize  = rhs_.hsize;
        this.hwdata = rhs_.hwdata;
        this.hrdata = rhs_.hrdata;
        this.hready = rhs_.hready;
        this.hresp  = rhs_.hresp;
    endfunction
endclass
