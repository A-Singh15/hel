`timescale 1ns/1ps

class driver_class;

  // Number of transactions processed by the driver
  int num_transactions = 0;

  // Virtual interface handle
  virtual consolidated_if test_if;

  // Transaction object
  transaction_class trans_obj;

  // Mailboxes for communication between generator, driver, and scoreboard
  mailbox gen_to_drv_mbox, drv_to_gen_mbox, drv_to_scb_mbox;
  
  // Constructor: Initializes mailboxes and virtual interface
  function new(mailbox gen_to_drv_mbox, drv_to_gen_mbox, drv_to_scb_mbox, virtual consolidated_if test_if);
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
