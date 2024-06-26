`timescale 1ns/1ps

// Define the data_packet class
class data_packet;
    // Define the fields as per your requirements
    logic [7:0] distance;
    logic [3:0] x_motion;
    logic [3:0] y_motion;
    logic is_complete;
    logic [7:0] addr_R;
    logic [9:0] addr_S1;
    logic [9:0] addr_S2;
    logic [7:0] R_memory;
    logic [7:0] S_memory;
    integer exp_x_vector;
    integer exp_y_vector;
    logic [7:0] best_dist;
    logic [3:0] x_vector;
    logic [3:0] y_vector;

    // Constructor
    function new();
    endfunction
endclass

class observer;

    // Virtual interface handle
    virtual consolidated_if virt_if;
    data_packet packet;
    mailbox observer_to_scorer;

    // Constructor to initialize the observer with a mailbox and virtual interface
    function new(mailbox observer_to_scorer, input virtual consolidated_if virt_if);
        this.observer_to_scorer = observer_to_scorer;
        this.virt_if = virt_if;
        packet = new();
    endfunction : new

    // Task to continuously monitor the DUT
    task monitor_task();
        forever begin
            data_packet pkt = new();
            @(posedge virt_if.clk);
            pkt.distance = virt_if.driver_cb.BestDist;  
            pkt.x_motion = virt_if.driver_cb.motionX; 
            pkt.y_motion = virt_if.driver_cb.motionY; 
            pkt.is_complete = virt_if.driver_cb.completed; 
            pkt.addr_R = virt_if.driver_cb.AddressR; 
            pkt.addr_S1 = virt_if.driver_cb.AddressS1;
            pkt.addr_S2 = virt_if.driver_cb.AddressS2;
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
    virtual consolidated_if mem_virt_if;
    
    // Mailbox handles for communication with scorer and evaluator
    mailbox observer_to_scorer;
    mailbox observer_to_evaluator;
    
    // Constructor to initialize the data observer with a virtual interface and mailboxes
    function new(virtual consolidated_if mem_virt_if, mailbox observer_to_scorer, mailbox observer_to_evaluator);
        this.mem_virt_if = mem_virt_if;
        this.observer_to_scorer = observer_to_scorer;
        this.observer_to_evaluator = observer_to_evaluator;
    endfunction
    
    // Main task to monitor DUT activity, capture data, and communicate with scorer and evaluator
    task main_task;
        $display("============= Data Observer Main Task =============");
        forever begin
            data_packet data, eval_data;
            data = new();
            wait(mem_virt_if.start == 1); // Wait for start signal from DUT
            @(posedge mem_virt_if.MONITOR.clk);
            data.R_memory = mem_virt_if.R_mem; // Capture R memory state
            data.S_memory = mem_virt_if.S_mem; // Capture S memory state
            @(posedge mem_virt_if.MONITOR.clk);
            data.exp_x_vector = mem_virt_if.monitor_cb.Expected_motionX;
            data.exp_y_vector = mem_virt_if.monitor_cb.Expected_motionY;
            wait(mem_virt_if.monitor_cb.completed); // Wait for completion signal from DUT
            $display("[OBSERVER_INFO] :: Process Completed");
            data.best_dist = mem_virt_if.monitor_cb.BestDist;
            data.x_vector = mem_virt_if.monitor_cb.motionX;
            data.y_vector = mem_virt_if.monitor_cb.motionY;

            // Adjust x_vector and y_vector for signed values
            if (data.x_vector >= 8)
                data.x_vector = data.x_vector - 16;
            if (data.y_vector >= 8)
                data.y_vector = data.y_vector - 16;
                
            $display("[OBSERVER_INFO] :: DUT Output Packet x_vector: %d and y_vector: %d", data.x_vector, data.y_vector);

            // Copy data for evaluator
            eval_data = new data_packet(data); 
            
            // Send data to scorer and evaluator
            observer_to_scorer.put(data); 
            observer_to_evaluator.put(eval_data); 
        end
    endtask
    
endclass
