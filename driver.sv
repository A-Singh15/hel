
module driver(interface intf);
  task drive(input transaction tr);
    // Implement driving logic
    intf.data_in = tr.data;
    // Add other driving logic
  endtask
endmodule
