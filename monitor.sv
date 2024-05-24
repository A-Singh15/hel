
`timescale 1ns/1ps

class observer;

    // Virtual interface handle
    virtual main_if.test virt_if;
    data_packet packet;
    mailbox observer_to_scorer;

    // Constructor to initialize the observer with a mailbox and virtual interface
    function new(mailbox observer_to_scorer, input virtual main_if.test virt_if);
        this.observer_to_scorer = observer_to_scorer;
        this.virt_if = virt_if;
        packet = new();
    endfunction : new

    // Task to continuously monitor the DUT
    task monitor_task();
        forever begin
            data_packet pkt = new();
            @(posedge virt_if.clk);
            pkt.distance = virt_if.cb.distance_value;  
            pkt.x_motion = virt_if.cb.x_motion; 
            pkt.y_motion = virt_if.cb.y_motion; 
            pkt.is_complete = virt_if.cb.complete_signal; 
            pkt.addr_R = virt_if.cb.addr_R; 
            pkt.addr_S1 = virt_if.cb.addr_S1;
            pkt.addr_S2 = virt_if.cb.addr_S2;
            observer_to_scorer.put(pkt);
        end
    endtask : monitor_task
    
    // Empty wrap-up task for potential future use
    task finalize();
    endtask : finalize

endclass : observer


class data_observer;

    // Loop variable
    int i;

    // Virtual interface handle
    virtual mem_est_if mem_virt_if;
    
    // Mailbox handles for communication with scorer and evaluator
    mailbox observer_to_scorer;
    mailbox observer_to_evaluator;
    
    // Constructor to initialize the data observer with a virtual interface and mailboxes
    function new(virtual mem_est_if mem_virt_if, mailbox observer_to_scorer, mailbox observer_to_evaluator);
        this.mem_virt_if = mem_virt_if;
        this.observer_to_scorer = observer_to_scorer;
        this.observer_to_evaluator = observer_to_evaluator;
    endfunction
    
    // Main task to monitor DUT activity, capture data, and communicate with scorer and evaluator
    task main_task;
        $display("============= Data Observer Main Task =============
");
        forever begin
            data_packet data, eval_data;
            data = new();
            wait(mem_virt_if.start_signal == 1); // Wait for start signal from DUT
            @(posedge mem_virt_if.MONITOR.clk);
            data.R_memory = mem_virt_if.R_mem_data; // Capture R memory state
            data.S_memory = mem_virt_if.S_mem_data; // Capture S memory state
            @(posedge mem_virt_if.MONITOR.clk);
            data.exp_x_vector = `MONITOR_INTERFACE.exp_x_vector;
            data.exp_y_vector = `MONITOR_INTERFACE.exp_y_vector;
            wait(`MONITOR_INTERFACE.comp_signal); // Wait for completion signal from DUT
            $display("[OBSERVER_INFO] :: Process Completed");
            data.best_dist = `MONITOR_INTERFACE.best_distance;
            data.x_vector = `MONITOR_INTERFACE.x_vector;
            data.y_vector = `MONITOR_INTERFACE.y_vector;

            // Adjust x_vector and y_vector for signed values
            if (data.x_vector >= 8)
                data.x_vector = data.x_vector - 16;
            if (data.y_vector >= 8)
                data.y_vector = data.y_vector - 16;
                
            $display("[OBSERVER_INFO] :: DUT Output Packet x_vector: %d and y_vector: %d", data.x_vector, data.y_vector);

            // Copy data for evaluator
            eval_data = new data; 
            
            // Send data to scorer and evaluator
            observer_to_scorer.put(data); 
            observer_to_evaluator.put(eval_data); 
        end
    endtask
    
endclass
