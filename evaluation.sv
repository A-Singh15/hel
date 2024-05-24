`timescale 1ns/1ps

class coverage_class;
  real coverage_metric;
  virtual main_if mem_if;
  mailbox monitor_to_coverage;
  transaction_class transaction;
  covergroup coverage_group;
    coverpoint transaction.best_distance;
    coverpoint transaction.expected_motion_x {
      bins negative_vals[] = {[-8:-1]};
      bins zero_val = {0};
      bins positive_vals[] = {[1:7]};
    }
    coverpoint transaction.expected_motion_y {
      bins negative_vals[] = {[-8:-1]};
      bins zero_val = {0};
      bins positive_vals[] = {[1:7]};
    }
    coverpoint transaction.motion_vector_x {
      bins negative_vals[] = {[-8:-1]};
      bins zero_val = {0};
      bins positive_vals[] = {[1:7]};
    }
    coverpoint transaction.motion_vector_y {
      bins negative_vals[] = {[-8:-1]};
      bins zero_val = {0};
      bins positive_vals[] = {[1:7]};
    }
    cross cp_expected_motion_x_y: cp_expected_motion_x, cp_expected_motion_y;
    cross cp_motion_vector_x_y: cp_motion_vector_x, cp_motion_vector_y;
  endgroup

  function new(virtual main_if mem_if, mailbox monitor_to_coverage);
    this.mem_if = mem_if;
    this.monitor_to_coverage = monitor_to_coverage;
    coverage_group = new();
  endfunction

  task run_coverage();
    forever begin
      monitor_to_coverage.get(transaction);
      coverage_group.sample();
      coverage_metric = coverage_group.get_coverage();
    end
  endtask
endclass
