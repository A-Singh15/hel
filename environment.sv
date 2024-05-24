`timescale 1ns/1ps

`include "interfaces.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "evaluation.sv"

class environment;
  // Handles for Generator, Driver, Monitor, Scoreboard, and Coverage
  generator gen;                          
  driver driv;
  monitor mon;
  scoreboard scb;
  coverage cov;                 
  
  // Mailbox handles for communication between components
  mailbox gen2driv, mon2scb, mon2cov;      
  
  // Events for synchronization
  event gen_ended;
  event mon_done;
  
  // Virtual interface handle
  virtual ME_interface mem_intf;          

  // Constructor: Initializes the virtual interface and component instances
  function new(virtual ME_interface mem_intf);
    this.mem_intf = mem_intf;   
    gen2driv = new();
    mon2scb = new();
    mon2cov = new();
    gen = new(gen2driv, gen_ended);
    driv = new(mem_intf, gen2driv);
    mon = new(mem_intf, mon2scb, mon2cov);
    scb = new(mon2scb);
    cov = new(mem_intf, mon2cov);
  endfunction
  
  // Pre-test task: Initializes default values
  task pre_test();
    $display("================================================= [ENV_INFO] Driver start ===============================================");
    driv.start();  // Initialize default values
  endtask
  
  // Test task: Executes the main tasks of all components
  task test();
    fork
      gen.main();
      driv.main();
      mon.main();
      scb.main();
      cov.cove();
    join_any
  endtask
  
  // Post-test task: Waits for completion and prints the coverage report
  task post_test();
    wait(gen_ended.triggered);
    wait(gen.trans_count == driv.no_transactions);
    wait(gen.trans_count == scb.no_transactions);
    $display (" Motion Estimator Coverage Report = %0.2f %% \n", cov.ME_Coverage);  // Print coverage report
    scb.summary();  // Print summary
  endtask 
  
  // Run task: Executes the complete test sequence
  task run;
    pre_test();
    $display("================================================= [ENV_INFO] Done with pre-test, Test Started. =================================================");
    test();
    post_test();
    $finish;
  endtask
  
endclass;

