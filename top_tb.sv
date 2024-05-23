
module top_tb;

  // Instantiate the testbench
  testbench tb();

  initial begin
    // Simulation time limit
    #1000;
    $finish;
  end

endmodule
