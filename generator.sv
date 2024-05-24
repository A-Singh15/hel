`timescale 1ns/1ps

class generator_class;

  // Transaction object
  rand transaction_class trans_obj;

  // Number of transactions to be generated
  int trans_count = 10;

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
