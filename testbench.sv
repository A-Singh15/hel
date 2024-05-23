
module testbench;

  // Instantiate interface
  interface intf();

  // Instantiate driver, monitor, and scoreboard
  driver drv(intf);
  monitor mon(intf);
  scoreboard sb;

  // Environment setup
  initial begin
    intf.clk = 0;
    forever #5 intf.clk = ~intf.clk;
  end

  // Generate test stimuli
  initial begin
    transaction tr;
    tr.address = 8'hAA;
    tr.data = 8'h55;
    tr.valid = 1;

    // Drive the transaction
    drv.drive(tr);

    // Monitor and check results
    transaction mon_tr;
    mon.monitor(mon_tr);
    sb.compare(tr, mon_tr);
  end

  // Implement assertions and coverage
  initial begin
    // Assertions
    assert (intf.data_out == 8'h55) else $fatal("Assertion failed");

    // Coverage
    cover (intf.data_out == 8'h55);
  end

endmodule
