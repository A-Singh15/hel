`timescale 1ns/1ps

`include "environment.sv"

program test_program(main_if test_if); 

  // Instance of the environment class
  environment env;
  
  // Initial block to set up and run the environment
  initial begin
    env = new(test_if);  // Create a new environment instance with the given interface
    env.generator_inst.trans_count = `TRANSACTION_COUNT;  // Set the total number of transactions to be generated
    env.run_env();  // Start the run task of the environment
  end
endprogram
