`timescale 1ns/1ps

`include "transaction_class.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "evaluation.sv"

class test_environment;
    generator_class gen_inst;
    driver_class drv_inst;
    monitor_class mon_inst;
    scoreboard_class scb_inst;
    evaluation_class eval_inst;
    
    mailbox gen_to_drv, mon_to_scb, mon_to_eval;
    virtual main_if intf;

    function new(input virtual main_if intf);
        this.intf = intf;
    endfunction

    function void build();
        gen_to_drv = new();
        mon_to_scb = new();
        mon_to_eval = new();
        
        gen_inst = new(gen_to_drv, drv_to_gen);
        drv_inst = new(gen_to_drv, drv_to_gen, drv_to_scb, intf);
        scb_inst = new(drv_to_scb, mon_to_scb);
        mon_inst = new(mon_to_scb, intf);
        eval_inst = new(intf, mon_to_eval);
    endfunction

    task run();
        fork
            gen_inst.run();
            drv_inst.run();
            mon_inst.run();
            scb_inst.run();
            eval_inst.sample_evaluation();
        join_none
    endtask

    task wrap_up();
        fork
            gen_inst.wrap_up();
            drv_inst.wrap_up();
            mon_inst.wrap_up();
            scb_inst.wrap_up();
            eval_inst.sample_evaluation();
        join
    endtask
endclass
