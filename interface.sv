
`timescale 1ns/1ps

// General Interface
interface main_if(input bit clk);

  // Signals
  logic init_signal;
  logic complete_signal;
  logic [7:0] distance_value;
  logic [3:0] x_motion, y_motion;
  logic [7:0] R_val, S1_val, S2_val;
  logic [7:0] addr_R;
  logic [9:0] addr_S1, addr_S2;

  // Driver clocking block
  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output R_val;
    output S1_val;
    output S2_val;
    output init_signal;
    input distance_value;   
    input x_motion;  
    input y_motion;  
    input complete_signal;  
    input addr_R;  
    input addr_S1;
    input addr_S2;  
  endclocking

  // Modport for driver
  modport drv (clocking driver_cb, input clk);

endinterface : main_if


`default_nettype none

// Memory Estimator Interface
interface mem_est_if(input bit clk);

  // Signals
  logic start_signal; 
  logic [3:0] x_vector;
  logic [3:0] y_vector;
  integer exp_x_vector;
  integer exp_y_vector;
  logic [7:0] addr_R;
  logic [9:0] addr_S1;
  logic [9:0] addr_S2;
  logic [7:0] R_mem_val;
  logic [7:0] S1_mem_val;
  logic [7:0] S2_mem_val;
  logic [7:0] best_distance;
  logic comp_signal;
  logic [7:0] R_mem_data[`RMEM_MAX-1:0];
  logic [7:0] S_mem_data[`SMEM_MAX-1:0];

  // Driver clocking block
  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    output R_mem_data;
    output S_mem_data;
    output R_mem_val;
    output S1_mem_val;
    output S2_mem_val;
    output exp_x_vector;
    output exp_y_vector;
    input best_distance;
    input x_vector, y_vector;
    input addr_R;
    input addr_S1;
    input addr_S2;
    input comp_signal;
  endclocking
  
  // Monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    input R_mem_data;
    input S_mem_data;
    input R_mem_val;
    input S1_mem_val;
    input S2_mem_val;
    input exp_x_vector;
    input exp_y_vector;
    input x_vector, y_vector;
    input addr_R;
    input addr_S1;
    input addr_S2;
    input comp_signal;
    input best_distance;
  endclocking
  
  // Modport for driver
  modport DRIVER (clocking driver_cb, input clk, start_signal);
  
  // Modport for monitor
  modport MONITOR (clocking monitor_cb, input clk, start_signal);

endinterface
