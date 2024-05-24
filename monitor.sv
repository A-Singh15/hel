`timescale 1ns/1ps

`include "transaction_class.sv"

class monitor_class;
  virtual main_if vif;
  transaction_class trans_obj;
  mailbox mon2scb;

  function new(mailbox mon2scb, input virtual main_if vif);
    this.mon2scb = mon2scb;
    this.vif = vif;
    trans_obj = new();
  endfunction

  task run();
    forever begin
      transaction_class trans;
      @(posedge vif.clk);
      trans_obj = new();
      trans_obj.BestDist = vif.BestDist;
      trans_obj.motionX = vif.motionX;
      trans_obj.motionY = vif.motionY;
      trans_obj.completed = vif.completed;
      trans_obj.AddressR = vif.AddressR;
      trans_obj.AddressS1 = vif.AddressS1;
      trans_obj.AddressS2 = vif.AddressS2;
      mon2scb.put(trans_obj);
    end
  endtask

  task wrap_up();
    // empty for now
  endtask
endclass
