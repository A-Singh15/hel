`timescale 1ns/1ps

class driver_class;

  // Number of transactions processed by the driver
  int num_transactions = 0;

  // Virtual interface handle
  virtual main_if test_if;

  // Transaction object
  transaction_class trans_obj;

  // Mailboxes for communication between generator, driver, and scoreboard
  mailbox gen_to_drv_mbox, drv_to_gen_mbox, drv_to_scb_mbox;
  
  // Constructor: Initializes mailboxes and virtual interface
  function new(mailbox gen_to_drv_mbox, drv_to_gen_mbox, drv_to_scb_mbox, virtual main_if test_if);
    this.gen_to_drv_mbox = gen_to_drv_mbox;
    this.drv_to_gen_mbox = drv_to_gen_mbox;
    this.drv_to_scb_mbox = drv_to_scb_mbox;
    this.test_if = test_if;
    trans_obj = new();
  endfunction : new

  // Reset task: Initializes the interface signals to default values
  task reset_driver();
    $display("** [DRIVER] Reset Started **");
    test_if.driver_cb.start <= 0;
    test_if.driver_cb.R <= 0;
    test_if.driver_cb.S1 <= 0;
    test_if.driver_cb.S2 <= 0;
    $display("** [DRIVER] Reset Completed **");
  endtask : reset_driver
  
  // Run task: Continuously processes transactions from generator
  task run_driver();
    forever begin
      transaction_class trans_data;
      @(posedge test_if.clk);
      gen_to_drv_mbox.get(trans_data);
      test_if.driver_cb.start       <= trans_data.start;
      test_if.driver_cb.R           <= trans_data.R;
      test_if.driver_cb.S1          <= trans_data.S1;
      test_if.driver_cb.S2          <= trans_data.S2;
      drv_to_scb_mbox.put(trans_data);
      num_transactions++;
    end
  endtask : run_driver

  // Wrap-up task: Completes processing when the BestDist signal is set
  task wrap_up_driver();
    wait (test_if.driver_cb.BestDist == 1);
    @(posedge test_if.clk);
    $display("** [DRIVER] BestDist is set to 1 **");
    $display("** [DRIVER] Finishing simulation **");
    $finish;
  endtask : wrap_up_driver

endclass : driver_class

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

class transaction_class;

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
