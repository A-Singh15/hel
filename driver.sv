`timescale 1ns/1ps

class driver_class;
    // Counter for the number of transactions
    int transaction_count = 0;
    
    // Virtual interface handle
    virtual test_interface virt_if;
    
    // Transaction object and mailboxes for communication
    transaction_obj trans_obj;
    mailbox gen_to_drv_mbox, drv_to_gen_mbox, drv_to_scb_mbox;

    // Constructor: Initializes the driver with mailboxes and virtual interface
    function new(mailbox gen_to_drv_mbox, drv_to_gen_mbox, drv_to_scb_mbox, input virtual test_interface virt_if);
        this.gen_to_drv_mbox = gen_to_drv_mbox;
        this.drv_to_gen_mbox = drv_to_gen_mbox;
        this.drv_to_scb_mbox = drv_to_scb_mbox;
        this.virt_if = virt_if;
        trans_obj = new();
    endfunction : new

    // Reset task: Resets the interface signals to default values
    task reset();
        $display("***** [DRIVER] Reset Initiated *****");
        virt_if.clk_block.start_signal <= 0;
        virt_if.clk_block.ref_data <= 0;
        virt_if.clk_block.search_data1 <= 0;
        virt_if.clk_block.search_data2 <= 0;
        $display("***** [DRIVER] Reset Completed *****");
    endtask : reset

    // Run task: Drives transactions from generator to DUT
    task run();
        forever begin
            transaction_obj trans_obj_local;
            @(posedge virt_if.clk);
            gen_to_drv_mbox.get(trans_obj_local);
            virt_if.clk_block.start_signal <= trans_obj_local.start_signal;
            virt_if.clk_block.ref_data <= trans_obj_local.ref_data;
            virt_if.clk_block.search_data1 <= trans_obj_local.search_data1;
            virt_if.clk_block.search_data2 <= trans_obj_local.search_data2;
            drv_to_scb_mbox.put(trans_obj_local);
            transaction_count++;
        end
    endtask : run

    // Wrap-up task: Completes the simulation upon certain conditions
    task wrap_up();
        wait (virt_if.clk_block.best_distance == 1);
        @virt_if.clk_block;
        $display("***** [DRIVER] Simulation Completion Triggered *****");
        $finish;
    endtask : wrap_up

endclass : driver_class


`timescale 1ns/1ps

class driver_class;
    
    // Number of transactions and loop variable
    int total_transactions, loop_index;

    // Virtual interface handle
    virtual evaluation_interface eval_if;

    // Mailbox for communication from generator to driver
    mailbox trans_mailbox;

    // Constructor: Initializes the driver with virtual interface and mailbox
    function new(virtual evaluation_interface eval_if, mailbox trans_mailbox);
        this.eval_if = eval_if;
        this.trans_mailbox = trans_mailbox;
    endfunction : new

    // Start task: Resets memory values before starting operations
    task start;
        $display("\n***** [DRIVER] Initialization Started *****");
        wait(!eval_if.start_signal);
        $display("\n***** [DRIVER] Default Values Set *****");
        for(loop_index = 0; loop_index < `SEARCH_MEM_MAX; loop_index++)
            eval_if.search_memory[loop_index] <= 0;
        for(loop_index = 0; loop_index < `REF_MEM_MAX; loop_index++)
            eval_if.ref_memory[loop_index] <= 0;
        wait(eval_if.start_signal);
        $display("\n***** [DRIVER] All Memories Initialized *****");
    endtask : start

    // Drive task: Drives transactions into DUT through the interface
    task drive;
        transaction_obj trans;
        forever begin
            trans_mailbox.get(trans);
            $display("\n***** [DRIVER] Driving Transaction %0d *****", total_transactions);
            eval_if.ref_memory = trans.ref_memory;  // Drive ref_memory to interface
            eval_if.search_memory = trans.search_memory;  // Drive search_memory to interface
            eval_if.start_signal = 1;
            @(posedge eval_if.clk_block.clk);
            eval_if.expected_motion_x <= trans.expected_motion_x;  // Drive Expected Motion X to interface
            eval_if.expected_motion_y <= trans.expected_motion_y;  // Drive Expected Motion Y to interface
            $display("\n***** [DRIVER] Packet Expected Motion X: %d and Expected Motion Y: %d *****", trans.expected_motion_x, trans.expected_motion_y);
            wait(eval_if.process_completed == 1);  // Wait for DUT to signal completion
            eval_if.start_signal = 0;
            $display("\n***** [DRIVER] DUT Signaled Completion *****");
            total_transactions++;
            @(posedge eval_if.clk_block.clk);
        end
    endtask : drive

    // Main task: Starts the driver and continuously drives transactions
    task main;
        $display("\n***** [DRIVER] Main Task Initiated *****");
        forever begin
            fork
                drive();
            join_none
        end
    endtask : main

endclass : driver_class
