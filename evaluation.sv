`timescale 1ns/1ps

class coverage_evaluation;

  // Coverage metric
  real coverage_metric;

  // Virtual interface to memory
  virtual ME_interface memory_interface;

  // Mailbox for receiving transactions from the monitor
  mailbox monitor_to_coverage;

  // Transaction object
  DataObject transaction;

  // Covergroup for measuring coverage
  covergroup coverage_group;
    option.per_instance = 1;

    // Coverpoint for BestDist
    best_distance: coverpoint transaction.best_distance; // Automatic bins

    // Coverpoint for Expected_motionX with specified bins
    expected_motion_x: coverpoint transaction.expected_motion_x {
      bins negative_values[] = {[-8:-1]}; // Negative values
      bins zero_value = {0};       // Zero value
      bins positive_values[] = {[1:7]};   // Positive values
    }

    // Coverpoint for Expected_motionY with specified bins
    expected_motion_y: coverpoint transaction.expected_motion_y {
      bins negative_values[] = {[-8:-1]}; // Negative values
      bins zero_value = {0};       // Zero value
      bins positive_values[] = {[1:7]};   // Positive values
    }

    // Coverpoint for Actual_motionX with specified bins
    actual_motion_x: coverpoint transaction.motion_x {
      bins negative_values[] = {[-8:-1]}; // Negative values
      bins zero_value = {0};       // Zero value
      bins positive_values[] = {[1:7]};   // Positive values
    }

    // Coverpoint for Actual_motionY with specified bins
    actual_motion_y: coverpoint transaction.motion_y {
      bins negative_values[] = {[-8:-1]}; // Negative values
      bins zero_value = {0};       // Zero value
      bins positive_values[] = {[1:7]};   // Positive values
    }
    cross expected_motion_cross: cross expected_motion_x, expected_motion_y;
    cross actual_motion_cross: cross actual_motion_x, actual_motion_y;
  endgroup
  
  // Constructor to initialize the coverage class
  function new(virtual ME_interface memory_interface, mailbox monitor_to_coverage);
    this.memory_interface = memory_interface;
    this.monitor_to_coverage = monitor_to_coverage;
    coverage_group = new();
  endfunction
   
  // Task to continuously sample coverage
  task evaluate_coverage();
    begin
      forever begin
        monitor_to_coverage.get(transaction);        // Get a transaction from the mailbox
        coverage_group.sample();    // Sample the covergroup
        coverage_metric = coverage_group.get_coverage(); // Update coverage metric
      end
    end
  endtask
  
endclass

`define SMEM_MAX 1024
`define RMEM_MAX 256
`define TRANSACTION_COUNT 1500
`define DRIV_IF memory_interface.ME_DRIVER.ME_driver_cb
`define MON_IF memory_interface.ME_MONITOR.ME_monitor_cb

module ME_assertions(
    input clock, 
    input start, 
    input [7:0] best_distance, 
    input [3:0] motion_x, 
    input [3:0] motion_y, 
    input completed
);

  integer tmp_motion_x, tmp_motion_y;

  // Convert 4-bit signed motion vectors to 5-bit signed integers
  always @(*) begin
      if (motion_x >= 8)
          tmp_motion_x = motion_x - 16;
      else
          tmp_motion_x = motion_x;

      if (motion_y >= 8)
          tmp_motion_y = motion_y - 16;
      else
          tmp_motion_y = motion_y;
  end

  always @(posedge clock) begin
    // Assertion 1: Ensure that 'completed' signal is not asserted when 'start' is high
    assert_property: assert property (@(posedge clock) (start -> !completed)) else
      $error("Assertion failed: start -> !completed at time %0t", $time);

    // Assertion 2: Ensure that 'completed' signal is asserted when 'start' is low
    assert_property2: assert property (@(posedge clock) ((!start && !$past(start)) -> completed)) else
      $error("Assertion failed: (!start && !$past(start)) -> completed at time %0t", $time);

    // Assertion 3: Ensure that 'best_distance' is always within the valid range of 0x00 to 0xFF
    assert_property3: assert property (@(posedge clock) disable iff (!start)
      ((best_distance >= 8'h00) && (best_distance <= 8'hFF))) else
      $error("Assertion failed: best_distance out of range at time %0t", $time);

    // Assertion 4: Ensure that 'motion_x' and 'motion_y' are valid motion vectors
    assert_property4: assert property (@(posedge clock) disable iff (!completed || !start)
      ((tmp_motion_x >= -8) && (tmp_motion_x <= 7) && (tmp_motion_y >= -8) && (tmp_motion_y <= 7))) else
      $error("Assertion failed at time %0t: motion_x = %0d, motion_y = %0d", $time, tmp_motion_x, tmp_motion_y);
  end

endmodule
