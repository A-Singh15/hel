
`timescale 1ns/1ps

class analysis;

  // Metric for evaluation
  real evaluation_metric;

  // Interface to memory
  virtual analysis_interface memory_interface;

  // Mailbox for receiving data from the monitor
  mailbox monitor_to_analysis;

  // Data object
  DataObject data;
      
  // Group for measuring evaluation
  covergroup analysis_group;
    option.per_instance = 1;
    
    // Point for BestDist
    best_distance: coverpoint data.best_distance; // Automatic bins

    // Point for expected_motion_x with defined bins
    expected_motion_x: coverpoint data.expected_motion_x {
      bins negative_values[] = {[-8:-1]}; // Negative range
      bins zero_value  = {0};             // Zero
      bins positive_values[] = {[1:7]};   // Positive range
    }

    // Point for expected_motion_y with defined bins
    expected_motion_y: coverpoint data.expected_motion_y {
      bins negative_values[] = {[-8:-1]}; // Negative range
      bins zero_value  = {0};             // Zero
      bins positive_values[] = {[1:7]};   // Positive range
    }

    // Point for actual_motion_x with defined bins
    actual_motion_x: coverpoint data.actual_motion_x {
      bins negative_values[] = {[-8:-1]}; // Negative range
      bins zero_value  = {0};             // Zero
      bins positive_values[] = {[1:7]};   // Positive range
    }

    // Point for actual_motion_y with defined bins
    actual_motion_y: coverpoint data.actual_motion_y {
      bins negative_values[] = {[-8:-1]}; // Negative range
      bins zero_value  = {0};             // Zero
      bins positive_values[] = {[1:7]};   // Positive range
    }
    cross_exp : cross expected_motion_x, expected_motion_y;
    cross_act : cross actual_motion_x, actual_motion_y;
  endgroup
  
  // Constructor for analysis class
  function new(virtual analysis_interface memory_interface, mailbox monitor_to_analysis);
    this.memory_interface = memory_interface;
    this.monitor_to_analysis = monitor_to_analysis;
    analysis_group = new();
  endfunction
   
  // Task to sample evaluation continuously
  task sample_evaluation();
    begin
      forever begin
        monitor_to_analysis.get(data);       // Get data from the mailbox
        analysis_group.sample();             // Sample the group
        evaluation_metric = analysis_group.get_coverage(); // Update evaluation metric
      end
    end
  endtask
  
endclass


`timescale 1ns/1ps

`define MEMORY_MAX 1024
`define REFERENCE_MAX 256
`define DATA_COUNT 1500
`define DRIVER_INTERFACE memory_interface.analysis_driver.driver_cb
`define MONITOR_INTERFACE memory_interface.analysis_monitor.monitor_cb


`timescale 1ns/1ps

module assertions_module(
    input clk, 
    input start_signal, 
    input [7:0] best_distance, 
    input [3:0] motion_x, 
    input [3:0] motion_y, 
    input process_complete
);

  integer temp_motion_x, temp_motion_y;

  // Convert 4-bit signed motion vectors to 5-bit signed integers
  always @(*) begin
      if (motion_x >= 8)
          temp_motion_x = motion_x - 16;
      else
          temp_motion_x = motion_x;

      if (motion_y >= 8)
          temp_motion_y = motion_y - 16;
      else
          temp_motion_y = motion_y;
  end

  always @(posedge clk) begin
    // Check 1: 'process_complete' should not be high when 'start_signal' is high
    start_complete_check: assert property (@(posedge clk) (start_signal -> !process_complete)) else
      $error("Check failed: start_signal -> !process_complete at time %0t", $time);

    // Check 2: 'process_complete' should be high when 'start_signal' is low
    start_complete_check1: assert property (@(posedge clk) ((!start_signal && !$past(start_signal)) -> process_complete)) else
      $error("Check failed: (!start_signal && !$past(start_signal)) -> process_complete at time %0t", $time);

    // Check 3: 'best_distance' should always be within 0x00 to 0xFF
    best_distance_check: assert property (@(posedge clk) disable iff (!start_signal)
      ((best_distance >= 8'h00) && (best_distance <= 8'hFF))) else
      $error("Check failed: best_distance out of range at time %0t", $time);

    // Check 4: 'motion_x' and 'motion_y' should be valid motion vectors
    motion_vectors_check: assert property (@(posedge clk) disable iff (!process_complete || !start_signal)
      ((temp_motion_x >= -8) && (temp_motion_x <= 7) && (temp_motion_y >= -8) && (temp_motion_y <= 7))) else
      $error("Check failed at time %0t: motion_x = %0d, motion_y = %0d", $time, temp_motion_x, temp_motion_y);
  end

endmodule
