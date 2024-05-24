`timescale 1ns/1ps

`include "environment.sv"

program testbench(main_if main_interface); 

  // Instance of the environment class
  environment env;
  
  // Initial block to set up and run the environment
  initial begin
    env = new(main_interface);  // Create a new environment instance with the given interface
    env.gen_inst.trans_count = `TRANSACTION_COUNT;  // Set the total number of transactions to be generated
    env.build();  // Build the environment
    env.run();  // Start the run task of the environment
    env.wrap_up();  // Wrap up the environment
  end
endprogram
