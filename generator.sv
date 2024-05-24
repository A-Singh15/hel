`timescale 1ns/1ps

class generator_class;
    rand transaction_class trans;
    int trans_count = 4150;
    mailbox gen2drv, drv2gen;
    event ended;

    function new(mailbox gen2drv, drv2gen);
        this.gen2drv = gen2drv;
        this.drv2gen = drv2gen;
    endfunction

    task run();
        for (int i = 0; i < trans_count; i++) begin
            trans = new();
            if (i < 10) begin
                if (!trans.randomize() with {start == 0;}) $fatal("Generator: Trans randomization failed");
            end else if (i >= 10 && i <= 4120) begin
                if (!trans.randomize() with {start == 1;}) $fatal("Generator: Trans randomization failed");
            end else if (i > 4120) begin
                if (!trans.randomize() with {start == 0;}) $fatal("Generator: Trans randomization failed");
            end
            gen2drv.put(trans);
        end
        -> ended;
    endtask

    task wrap_up();
        // Empty for now
    endtask
endclass
