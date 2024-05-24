`timescale 1ns/1ps

class transaction_obj;
    rand logic           start_signal;
    rand logic [7:0]     ref_data, search_data1, search_data2;
         logic           process_completed;
         logic [7:0]     best_distance;
         logic [3:0]     motion_vector_x, motion_vector_y;
         logic [7:0]     addr_ref;
         logic [9:0]     addr_search1, addr_search2;

    function void display(string display_name);
        $display("*******************************************************");
        $display("   **********   %s  **********   ", display_name);
        $display("*******************************************************");
        $display("- Time          = %0d ns" , $time);
        $display("- Reference     = %0h, Search1 = %0h, Search2 = %0h", ref_data, search_data1, search_data2);
        $display("- Start Signal  = %0d" , start_signal);
        $display("- Completed     = %0d" , process_completed);
        $display("- Address Ref   = %0h" , addr_ref);
        $display("- Address S1    = %0h" , addr_search1);
        $display("- Address S2    = %0h" , addr_search2);
        $display("- Best Distance = %0h" , best_distance);
        $display("- Motion X      = %0h" , motion_vector_x);
        $display("- Motion Y      = %0h" , motion_vector_y);
        $display("*******************************************************");
    endfunction
endclass : transaction_obj


class generator_class;
    // Declaring transaction class 
    rand transaction_obj trans_obj;
    // Repeat count to specify the number of items to generate
    int trans_count = 4150;
    // Mailboxes to generate and send the packet to driver
    mailbox gen_to_drv_mbox, drv_to_gen_mbox;
    // Event to indicate the end of transaction generation
    event gen_end_event;

    function new(mailbox gen_to_drv_mbox, drv_to_gen_mbox);
        // Getting the mailbox handle from env to share the transaction packet
        // between the generator and driver, sharing the same mailbox
        this.gen_to_drv_mbox = gen_to_drv_mbox;
        this.drv_to_gen_mbox = drv_to_gen_mbox;
    endfunction : new

    // Run task: Generates the specified number of transaction packets and puts them into the mailbox
    task run();
        for(int i = 0; i < trans_count; i++) begin
            trans_obj = new();
            if (i < 10) begin
                if (!trans_obj.randomize() with {start_signal == 0;}) 
                    $fatal("Generator:: Transaction randomization failed");
            end else if (i >= 10 && i <= 4120) begin
                if (!trans_obj.randomize() with {start_signal == 1;}) 
                    $fatal("Generator:: Transaction randomization failed");
            end else if (i > 4120) begin
                $display("Case 3 transaction count %0d", i);
                if (!trans_obj.randomize() with {start_signal == 0;}) 
                    $fatal("Generator:: Transaction randomization failed");
            end 
            gen_to_drv_mbox.put(trans_obj);
        end
        -> gen_end_event; // Triggering indicates the end of generation
    endtask : run

    task wrap_up();
        // Empty for now
    endtask : wrap_up
endclass : generator_class


`timescale 1ns/1ps

class generator_class;

    // Transaction class handle
    rand transaction_obj trans_obj;

    // Number of transactions to generate (set to 1 for single transaction)
    int num_trans = 1;

    // Mailbox handle for communication with driver
    mailbox gen_to_drv_mbox;

    // Event to signal end of generation
    event end_event;

    // Constructor: Initializes mailbox and event handles
    function new(mailbox gen_to_drv_mbox, event end_event);
        this.gen_to_drv_mbox = gen_to_drv_mbox;
        this.end_event = end_event;
    endfunction

    // Main task: Generates transactions and sends them to the driver
    task main();
        $display("***** [GEN_INFO]: Generator Main Task Started *****");
        repeat (num_trans) begin
            trans_obj = new();
            if (!trans_obj.randomize()) 
                $fatal("[GEN_ERROR] :: Randomization failed"); // Randomize Transaction class
            trans_obj.generate_ref_mem(); // Generate reference memory from search memory
            trans_obj.display();
            gen_to_drv_mbox.put(trans_obj); // Put transaction packet into mailbox
        end
        -> end_event; // Signal that generation is ended
    endtask
endclass
