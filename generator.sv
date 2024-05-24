`timescale 1ns/1ps

// Ensure transaction_class is declared or imported correctly
virtual class transaction_class;
    // Signals for transactions
    rand logic start;
    rand logic [7:0] R, S1, S2;
    logic completed;
    logic [7:0] BestDist;
    logic [3:0] motionX, motionY;
    logic [7:0] AddressR;
    logic [9:0] AddressS1, AddressS2;

    // Display function for transaction details
    function void display_trans(string name);
        $display("**-------------------------------------------------------**");
        $display("**   -----------   %s  ----------   **", name);
        $display("**-------------------------------------------------------**");
        $display("** Time        = %0d ns", $time);
        $display("** R           = %0h, S1 = %0h, S2 = %0h", R, S1, S2);
        $display("** start       = %0d", start);
        $display("** completed   = %0d", completed);
        $display("** AddressR    = %0h", AddressR);
        $display("** AddressS1   = %0h", AddressS1);
        $display("** AddressS2   = %0h", AddressS2);
        $display("** BestDist    = %0h", BestDist);
        $display("** motionX     = %0h", motionX);
        $display("** motionY     = %0h", motionY);
        $display("**-------------------------------------------------------**");
    endfunction

endclass : transaction_class

class generator_class;

  // Transaction object
  rand transaction_class trans_obj;

  // Number of transactions to be generated
  int trans_count = 4150;

  // Mailboxes for communication between generator and driver
  mailbox gen_to_drv_mbox, drv_to_gen_mbox;

  // Event to signal end of generation
  event generation_done;

  // Constructor: Initializes mailboxes
  function new(mailbox gen_to_drv_mbox, drv_to_gen_mbox);
    this.gen_to_drv_mbox = gen_to_drv_mbox;
    this.drv_to_gen_mbox = drv_to_gen_mbox;
  endfunction : new

  // Run task: Generates transactions and sends them to the driver
  task run_generator();
    for(int i = 0; i < trans_count; i++) begin
      trans_obj = new();
      if (i < 10) begin
        if(!trans_obj.randomize() with {start == 0;}) 
          $fatal("Generator: Transaction randomization failed");
      end else if (i >= 10 || i <= 4120) begin
        if(!trans_obj.randomize() with {start == 1;}) 
          $fatal("Generator: Transaction randomization failed");
      end else if (i > 4120) begin
        if(!trans_obj.randomize() with {start == 0;}) 
          $fatal("Generator: Transaction randomization failed");
      end 
      gen_to_drv_mbox.put(trans_obj);
    end
    -> generation_done; // Triggering event to signal end of generation
  endtask : run_generator

  // Wrap-up task: Empty for now
  task wrap_up_generator();
  endtask : wrap_up_generator

endclass : generator_class
