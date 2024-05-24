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


class transaction_data;
    // Memory arrays for reference and search data
    logic [7:0] ref_memory[`RMEM_MAX-1:0];
    rand logic [7:0] search_memory[`SMEM_MAX-1:0];

    // Motion vectors and best distance metrics
    rand integer expected_motion_x;
    rand integer expected_motion_y;
    integer motion_x;
    integer motion_y;
    logic [7:0] best_distance;

    // Random index for introducing mismatches
    rand int rand_mismatch_index;
  
    // Constraints for expected motion vectors
    constraint motion_vector_constraints { 
        expected_motion_x dist {[-8:0]:=10, [1:7]:=10};
        expected_motion_y dist {[-8:0]:=10, [1:7]:=10};
    };

    // Constraints for mismatch index distribution
    constraint mismatch_index_constraints {
        soft rand_mismatch_index dist {[0:255] := 10, [256:511] := 10, [512:767] := 10}; 
    };

    // Constraints for search memory values
    constraint search_memory_constraints {
        foreach(search_memory[i]) search_memory[i] inside {[0:`SMEM_MAX-1]};
    };

    // Display function to output transaction details
    function void display();
        $display("================================================= [TRANSACTION_INFO] :: Search Memory Generated =================================================");
        for (int j = 0; j < `SMEM_MAX; j++) begin
            if (j % 32 == 0) $display("  ");
            $write("%h  ", search_memory[j]);
            if (j == 1023) $display("  ");
        end

        $display("================================================= [TRANSACTION_INFO] :: Reference Memory Generated =================================================");
        for (int j = 0; j < `RMEM_MAX; j++) begin
            if (j % 16 == 0) $display("  ");
            $write("%h ", ref_memory[j]);
            if (j == 255) $display("  ");
        end

        $display("\n[TRANSACTION_INFO] :: Random Mismatch Index : %0d", rand_mismatch_index);     
        $display("[TRANSACTION_INFO] :: Expected Motion X : %0d", expected_motion_x);
        $display("[TRANSACTION_INFO] :: Expected Motion Y : %0d", expected_motion_y);
    endfunction

    // Function to generate reference memory based on search memory and motion vectors
    function void generate_ref_memory();
        foreach (ref_memory[i]) begin
            // Generate a full match by default
            ref_memory[i] = search_memory[32 * 8 + 8 + (((i / 16) + expected_motion_y) * 32) + ((i % 16) + expected_motion_x)];
      
            // Introduce a partial match at the random mismatch index
            if (i == rand_mismatch_index)   
                ref_memory[i] = $urandom_range(0, 255);
        end

        // Shuffle ref_memory to create no match if rand_mismatch_index is above a threshold
        if (rand_mismatch_index >= 400) begin
            ref_memory.shuffle();
        end
    endfunction
endclass : transaction_data


class generator_class;
    // Declaring transaction class 
    rand transaction_obj trans_obj;
    rand transaction_data trans_data;
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
        for (int i = 0; i < trans_count; i++) begin
            trans_obj = new();
            trans_data = new();
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
            if (!trans_data.randomize()) $fatal("Generator:: Data randomization failed");
            trans_data.generate_ref_memory(); // Generate reference memory from search memory
            trans_data.display();
            gen_to_drv_mbox.put(trans_obj);
        end
        -> gen_end_event; // Triggering indicates the end of generation
    endtask : run

    task wrap_up();
        // Empty for now
    endtask : wrap_up
endclass : generator_class
