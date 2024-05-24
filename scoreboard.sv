`timescale 1ns/1ps

class results_tracker;
    // Variables for various counters and data packets
    int unsigned  expected_sum;
    data_packet  packet_in, packet_out;
    mailbox      driver_to_tracker, monitor_to_tracker;
    integer      ref_memory_file;
    integer      random_vectors;
    reg [7:0]    reference_memory[0:255]; 
    reg [3:0]    motion_vectors[0:1];
    integer signed expected_motion_x, expected_motion_y;
    integer signed actual_motion_x, actual_motion_y;

    // Loop variable
    integer signed  index_x, index_y;
    
    // Functional coverage group
    covergroup coverage_group;
        // Coverpoints for the coverage group
        coverpoint packet_in.ref_value {
                bins zero_val       = {0};
                bins one_val        = {1};
                bins two_to_five    = {2, 3, 4, 5};
                bins power_of_two   = {1, 2, 4, 8, 16, 32, 64, 128};
                bins upper_half     = {[128:255]};
                bins lower_half     = {[0:127]};
                bins full_range[]   = {[0:255]};
            }
        coverpoint packet_in.search_value1 {
                bins zero_val       = {0};
                bins one_val        = {1};
                bins two_to_five    = {2, 3, 4, 5};
                bins power_of_two   = {1, 2, 4, 8, 16, 32, 64, 128};
                bins upper_half     = {[128:255]};
                bins lower_half     = {[0:127]};
                bins full_range[]   = {[0:255]};
            }
        coverpoint packet_in.search_value2 {
                bins zero_val       = {0};
                bins one_val        = {1};
                bins two_to_five    = {2, 3, 4, 5};
                bins power_of_two   = {1, 2, 4, 8, 16, 32, 64, 128};
                bins upper_half     = {[128:255]};
                bins lower_half     = {[0:127]};
                bins full_range[]   = {[0:255]};
            }
        coverpoint packet_in.init_signal {
                bins init_on        = {1};
                bins init_off       = {0};
            }
    endgroup

    // Constructor to initialize the results tracker with mailboxes and coverage group
    function new(mailbox driver_to_tracker, monitor_to_tracker);
        this.driver_to_tracker = driver_to_tracker;
        this.monitor_to_tracker = monitor_to_tracker;
        this.expected_sum = 0;
        packet_in  = new();
        packet_out = new();
        coverage_group = new;
    endfunction : new

    // Task to run the results tracker and process data
    task run_task();
        foreach (reference_memory[i]) begin
            reference_memory[i] = '0;
        end
        foreach (motion_vectors[i]) begin
            motion_vectors[i] = '0;
        end
        ref_memory_file = $fopen ("./ref_memory.txt", "r");
        if (ref_memory_file) begin
            $display("******* Reference Memory File Opened *******");
        end else begin
            $display("******* Reference Memory File Not Opened *******");
        end
        $readmemh("ref_memory.txt", reference_memory);
        $fclose(ref_memory_file);
        
        random_vectors = $fopen ("./motion_vectors.txt", "r");
        if (random_vectors) begin
            $display("******* Random Motion Vectors File Opened *******");
        end else begin
            $display("******* Random Motion Vectors File Not Opened *******");
        end
        $readmemh("motion_vectors.txt", motion_vectors);
        $fclose(random_vectors);
        
        foreach (reference_memory[i]) begin
            $display("Reading Reference Memory -- reference_memory[%0d] = %0h", i, reference_memory[i]);
        end
        foreach (motion_vectors[i]) begin
            $display("Reading Random Vectors -- motion_vectors[%0d] = %0h", i, motion_vectors[i]);
        end
        expected_motion_x = motion_vectors[0];
        expected_motion_y = motion_vectors[1];
        $display("******* Reference Vectors -- expected_motion_x = %0h, expected_motion_y = %0h *******", expected_motion_x, expected_motion_y);

        forever begin
            packet_out = new();
            monitor_to_tracker.get(packet_out);
            if (packet_out.is_complete == 1'b1) begin
                packet_out.display("[Results Tracker]");
                if (packet_out.motion_x >= 8)
                    index_x = packet_out.motion_x - 16;
                else
                    index_x = packet_out.motion_x;
    
                if (packet_out.motion_y >= 8)
                    index_y = packet_out.motion_y - 16;
                else
                    index_y = packet_out.motion_y;

                //****************** Reports ******************
                if (packet_out.best_distance == 8'b11111111) begin
                    $display("Reference Memory Not Found in the Search Window!");
                end else begin
                    if (packet_out.best_distance == 8'b00000000) begin
                        $display("Perfect Match Found for Reference Memory: BestDist = %0d, motion_x = %0d, motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                                  packet_out.best_distance, index_x, index_y, expected_motion_x, expected_motion_y);
                    end else begin
                        $display("Non-perfect Match Found: BestDist = %0d, motion_x = %0d, motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                                  packet_out.best_distance, index_x, index_y, expected_motion_x, expected_motion_y);
                    end
                end

                if (index_x == expected_motion_x && index_y == expected_motion_y) begin
                    $display("DUT Motion Matches Expected: DUT motion_x = %0d, DUT motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                              index_x, index_y, expected_motion_x, expected_motion_y);
                end else begin
                    $display("DUT Motion Does Not Match Expected: DUT motion_x = %0d, DUT motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                              index_x, index_y, expected_motion_x, expected_motion_y);
                end

                $display("******* All Tests Completed *******");

                coverage_group.sample();
            end
        end
    endtask : run_task
    
    // Empty wrap-up task for potential future use
    task finalize();
    endtask : finalize

endclass : results_tracker


class scorekeeper;

    // Mailbox for receiving transactions from the monitor
    mailbox monitor_to_scorekeeper; 
    
    // Counters for different types of matches and transactions
    int total_transactions, perfect_matches, no_matches, partial_matches;
    
    // Variables for motion values
    integer motion_x, motion_y;

    // Constructor to initialize the scorekeeper with the mailbox
    function new(mailbox monitor_to_scorekeeper);
        this.monitor_to_scorekeeper = monitor_to_scorekeeper; 
    endfunction
    
    // Main task to process transactions and evaluate results
    task main_task;
        data_packet transaction; 
        partial_matches = 0;
        perfect_matches = 0;
        no_matches = 0;
        $display("********** [SCOREKEEPER] :: Main Task Starts **********");
        forever begin
            monitor_to_scorekeeper.get(transaction); // Get transaction from monitor
            $display("[SCOREKEEPER] :: Expected motion_x: %d, Expected motion_y: %d", transaction.expected_motion_x, transaction.expected_motion_y);
            
            // Adjust motion_x and motion_y for signed values
            if (transaction.motion_x >= 8)
                motion_x = transaction.motion_x - 16;
            else
                motion_x = transaction.motion_x;

            if (transaction.motion_y >= 8)
                motion_y = transaction.motion_y - 16;
            else
                motion_y = transaction.motion_y;

            $display("\n********** [SCOREKEEPER_RESULTS] **********");

            // Evaluate the transaction based on best_distance value
            if (transaction.best_distance == 8'hFF) begin
                $display("[SCOREKEEPER] :: Reference Memory Not Found in the Search Window!");
                no_matches++;
            end else begin
                if (transaction.best_distance == 8'h00) begin
                    $display("[SCOREKEEPER] :: Perfect Match Found for Reference Memory"); 
                    $display("[SCOREKEEPER] :: best_distance = %0d, motion_x = %0d, motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                              transaction.best_distance, motion_x, motion_y, transaction.expected_motion_x, transaction.expected_motion_y);
                    perfect_matches++;
                end else begin
                    $display("[SCOREKEEPER] :: Partial Match Found: best_distance = %0d, motion_x = %0d, motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                              transaction.best_distance, motion_x, motion_y, transaction.expected_motion_x, transaction.expected_motion_y);
                    partial_matches++;
                end
            end

            // Compare DUT motion values with expected values
            if (motion_x == transaction.expected_motion_x && motion_y == transaction.expected_motion_y) begin
                $display("[SCOREKEEPER] :: Motion As Expected :: DUT motion_x = %0d, DUT motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                          motion_x, motion_y, transaction.expected_motion_x, transaction.expected_motion_y);
            end else begin
                $display("[SCOREKEEPER] :: Motion Not As Expected :: DUT motion_x = %0d, DUT motion_y = %0d, Expected motion_x = %0d, Expected motion_y = %0d", 
                          motion_x, motion_y, transaction.expected_motion_x, transaction.expected_motion_y);
            end

            $display("========================================================================================================================\n");  
            total_transactions++;
            $display("[SCOREKEEPER] :: Number of Transaction Packets: %d", total_transactions);
            $display("------------------------------------------------------------------------------------------------------------------------\n");
        end
    endtask

    // Summary function: Displays a summary of the test results
    function void summary();
        $display("-----------------------------------------");
        $display("| Test Results                          |");
        $display("-----------------------------------------");
        $display("| Total Packets          | %6d       |", total_transactions);
        $display("| Perfect Matches        | %6d       |", perfect_matches);
        $display("| Partial Matches        | %6d       |", partial_matches);
        $display("| No Matches             | %6d       |", no_matches);
        $display("-----------------------------------------");
    endfunction
  
endclass
