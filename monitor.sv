`timescale 1ns/1ps
`include "transaction_class.sv"

class monitor_class;
    virtual main_if test intf;
    transaction_class packet;
    mailbox mon2scb;

    function new(mailbox mon2scb, input virtual main_if test intf);
        this.mon2scb = mon2scb;
        this.intf = intf;
        packet = new();
    endfunction

    task run();
        forever begin
            transaction_class trans = new();
            @(posedge intf.clk);
            trans.BestDist = intf.cb.BestDist;  
            trans.motionX = intf.cb.motionX; 
            trans.motionY = intf.cb.motionY; 
            trans.completed = intf.cb.completed; 
            trans.AddressR = intf.cb.AddressR; 
            trans.AddressS1 = intf.cb.AddressS1;
            trans.AddressS2 = intf.cb.AddressS2;
            mon2scb.put(trans);
        end
    endtask

    task wrap_up();
        // Empty for now
    endtask
endclass
