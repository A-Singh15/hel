`timescale 1ns/1ps

class driver_class;
    int num_transactions = 0;
    virtual main_if.drv vif;
    transaction_class trans_obj;
    mailbox gen2drv, drv2gen, drv2scb;

    function new(mailbox gen2drv, drv2gen, drv2scb, input virtual main_if.drv vif);
        this.gen2drv = gen2drv;
        this.drv2gen = drv2gen;
        this.drv2scb = drv2scb;
        this.vif = vif;
        trans_obj = new();
    endfunction

    task reset();
        $display("** [DRIVER] Reset Started **");
        vif.cb.start <= 0;
        vif.cb.R <= 0;
        vif.cb.S1 <= 0;
        vif.cb.S2 <= 0;
        $display("** [DRIVER] Reset Ended **");
    endtask

    task run();
        forever begin
            transaction_class trans;
            @(posedge vif.clk);
            gen2drv.get(trans);
            vif.cb.start <= trans.start;
            vif.cb.R <= trans.R;
            vif.cb.S1 <= trans.S1;
            vif.cb.S2 <= trans.S2;
            drv2scb.put(trans);
            num_transactions++;
        end
    endtask

    task wrap_up();
        wait (vif.cb.BestDist == 1);
        @vif.cb;
        $display("** Simulation Finished **");
        $finish;
    endtask
endclass
