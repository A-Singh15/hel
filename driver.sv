`timescale 1ns/1ps
`include "transaction_class.sv"

class driver_class;
    int num_transactions = 0;
    virtual main_if test intf;
    transaction_class trans_obj;
    mailbox gen2drv, drv2gen, drv2scb;

    function new(mailbox gen2drv, drv2gen, drv2scb, input virtual main_if test intf);
        this.gen2drv = gen2drv;
        this.drv2gen = drv2gen;
        this.drv2scb = drv2scb;
        this.intf = intf;
        trans_obj = new();
    endfunction

    task reset();
        $display("********* [DRIVER] Reset Started *********");
        intf.cb.start <= 0;
        intf.cb.R <= 0;
        intf.cb.S1 <= 0;
        intf.cb.S2 <= 0;
        $display("********* [DRIVER] Reset Ended *********");
    endtask

    task run();
        forever begin
            transaction_class trans;
            @(posedge intf.clk);
            gen2drv.get(trans);
            intf.cb.start <= trans.start;
            intf.cb.R <= trans.R;
            intf.cb.S1 <= trans.S1;
            intf.cb.S2 <= trans.S2;
            drv2scb.put(trans);
            num_transactions++;
        end
    endtask

    task wrap_up();
        wait(intf.cb.BestDist == 1);
        @(posedge intf.clk);
        $display("******** Simulation Finished ********");
        $finish;
    endtask
endclass
