`timescale 1ns/1ps

`include "transaction_class.sv"

class driver_class;
  int num_transactions = 0;
  virtual main_if vif;
  transaction_class trans_obj;
  mailbox gen2drv, drv2gen, drv2scb;

  function new(mailbox gen2drv, drv2gen, drv2scb, input virtual main_if vif);
    this.gen2drv = gen2drv;
    this.drv2gen = drv2gen;
    this.drv2scb = drv2scb;
    this.vif = vif;
    trans_obj = new();
  endfunction

  task reset();
    $display("--------- [DRIVER] Reset Started ---------");
    vif.start <= 0;
    vif.R <= 0;
    vif.S1 <= 0;
    vif.S2 <= 0;
    $display("--------- [DRIVER] Reset Ended ---------");
  endtask

  task run();
    forever begin
      transaction_class trans;
      @(posedge vif.clk);
      gen2drv.get(trans);
      vif.start <= trans.start;
      vif.R <= trans.R;
      vif.S1 <= trans.S1;
      vif.S2 <= trans.S2;
      drv2scb.put(trans);
      num_transactions++;
    end
  endtask

  task wrap_up();
    wait (vif.BestDist == 1);
    @vif;
    $display("------------------------------------------------------------------");
    $display("********  best distance = 1;   **********");
    $display("*****  Finishing simulation  **********");
    $display("------------------------------------------------------------------");
    $finish;
  endtask
endclass
