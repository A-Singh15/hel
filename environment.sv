
`timescale 1ns/1ps

`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "evaluation.sv"

class test_environment;
    // Instances of Generator, Driver, Monitor, and Scoreboard
    generator   gen_inst;
    driver      drv_inst;
    monitor     mon_inst;
    scoreboard  scb_inst;
    analysis    eval_inst; // Instance of the analysis class
    
    // Mailboxes for communication between components
    mailbox     gen_to_drv, drv_to_gen, mon_to_scb, drv_to_scb, mon_to_eval;
    
    // Virtual interface to the test
    virtual     test_if virt_if;

    // Constructor to initialize the environment with a virtual interface
    function new(input virtual test_if virt_if);
        this.virt_if = virt_if;
    endfunction : new

    // Function to build the environment by creating instances and mailboxes
    function void build();
        gen_to_drv = new();
        drv_to_gen = new();
        mon_to_scb = new();
        drv_to_scb = new();
        mon_to_eval = new();
        
        gen_inst = new(gen_to_drv, drv_to_gen);
        drv_inst = new(gen_to_drv, drv_to_gen, drv_to_scb, virt_if);
        scb_inst = new(drv_to_scb, mon_to_scb);
        mon_inst = new(mon_to_scb, virt_if);
        eval_inst = new(virt_if, mon_to_eval); // Instantiate the analysis class
    endfunction : build

    // Task to run the environment by running all components
    task run();
        fork
            gen_inst.run();
            drv_inst.run();
            mon_inst.run();
            scb_inst.run();
            eval_inst.sample_evaluation(); // Run the analysis task
        join_none
    endtask : run

    // Task to wrap up the environment by wrapping up all components
    task wrap_up();
        fork
            gen_inst.wrap_up();
            drv_inst.wrap_up();
            mon_inst.wrap_up();
            scb_inst.wrap_up();
            eval_inst.sample_evaluation(); // Ensure analysis completes
        join
    endtask : wrap_up

endclass : test_environment


class simulation_environment;
    // Instances of Generator, Driver, Monitor, Scoreboard, and Analysis
    generator gen_inst;
    driver drv_inst;
    monitor mon_inst;
    scoreboard scb_inst;
    analysis eval_inst;
    
    // Mailboxes for communication between components
    mailbox gen_to_drv, mon_to_scb, mon_to_eval;
    
    // Events for synchronization
    event gen_done;
    event mon_done;
    
    // Virtual interface handle
    virtual analysis_interface virt_mem_if;

    // Constructor to initialize the environment with a virtual interface
    function new(virtual analysis_interface virt_mem_if);
        this.virt_mem_if = virt_mem_if;
        gen_to_drv = new();
        mon_to_scb = new();
        mon_to_eval = new();
        gen_inst = new(gen_to_drv, gen_done);
        drv_inst = new(virt_mem_if, gen_to_drv);
        mon_inst = new(virt_mem_if, mon_to_scb, mon_to_eval);
        scb_inst = new(mon_to_scb);
        eval_inst = new(virt_mem_if, mon_to_eval);
    endfunction

    // Task to initialize default values before the test
    task pre_test();
        $display("========== [SIM_ENV] Initializing Driver ==========");
        drv_inst.start();  // Initialize default values
    endtask

    // Task to run the main tasks of all components
    task run_test();
        fork
            gen_inst.main();
            drv_inst.main();
            mon_inst.main();
            scb_inst.main();
            eval_inst.sample_evaluation();
        join_any
    endtask

    // Task to wait for completion and print the evaluation report
    task post_test();
        wait(gen_done.triggered);
        wait(gen_inst.trans_count == drv_inst.num_transactions);
        wait(gen_inst.trans_count == scb_inst.num_transactions);
        $display (" Coverage Report = %0.2f %% 
", eval_inst.evaluation_metric);  // Print evaluation report
        scb_inst.summary();  // Print summary
    endtask 

    // Task to run the complete test sequence
    task run();
        pre_test();
        $display("========== [SIM_ENV] Pre-test done, Starting Test ==========");
        run_test();
        post_test();
        $finish;
    endtask

endclass;