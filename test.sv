`timescale 1ns/1ps

`include "environment.sv"

program testbench(main_if main_interface); 

  // Instance of the environment class
  environment env;
  
  // Initial block to set up and run the environment
  initial begin
    test_env = new(main_interface);  // Create a new environment instance with the given interface
    test_env.gen_inst.trans_count = `TRANSACTION_COUNT;  // Set the total number of transactions to be generated
    test_env.build();  // Build the environment
    test_env.run();  // Start the run task of the environment
    test_env.wrap_up();  // Wrap up the environment
  end
endprogram
