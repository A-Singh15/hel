
module monitor(interface intf);
  task monitor(output transaction tr);
    // Implement monitoring logic
    tr.data = intf.data_out;
    // Add other monitoring logic
  endtask
endmodule
