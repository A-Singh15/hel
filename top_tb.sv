`timescale 1ns/10ps

`include "evaluation.sv"
`include "interfaces.sv"
`include "test.sv"

module top_testbench();
  bit               clk;  
  always #10 clk = ~clk;  // Clock Generation
  
  initial begin 
    $display("***** Simulation Start *****");
    main_intf.start_signal = 1'b0;
    repeat(2)
    @(posedge clk);   
    main_intf.start_signal = 1'b1;
  end
  
  main_interface main_intf(clk);  // Interface Instantiation
  ref_memory ref_mem_inst(.clk(clk), .address_ref(main_intf.address_ref), .ref_data(main_intf.ref_data));
  search_memory search_mem_inst(.clk(clk), .address_search1(main_intf.address_search1), .address_search2(main_intf.address_search2), .search_data1(main_intf.search_data1), .search_data2(main_intf.search_data2));
  
  assign ref_mem_inst.ref_memory_array = main_intf.ref_mem_array;
  assign search_mem_inst.search_memory_array = main_intf.search_mem_array;

  testbench motion_estimator_tb(main_intf);  // Test

  initial begin
    $vcdpluson();
    $dumpfile("dump.vcd"); $dumpvars;
  end

  top_level dut(  // DUT Instantiation
    .clk(main_intf.clk), 
    .start_signal(main_intf.start_signal), 
    .best_distance(main_intf.best_distance), 
    .motion_vector_x(main_intf.motion_vector_x), 
    .motion_vector_y(main_intf.motion_vector_y), 
    .address_ref(main_intf.address_ref), 
    .address_search1(main_intf.address_search1), 
    .address_search2(main_intf.address_search2), 
    .ref_data(main_intf.ref_data), 
    .search_data1(main_intf.search_data1), 
    .search_data2(main_intf.search_data2), 
    .process_completed(main_intf.process_completed)
  );

  bind dut assertion_evaluation assert_eval (  // Binding Assertion to Top module
      .clk(main_intf.clk), 
      .start_signal(main_intf.start_signal), 
      .best_distance(main_intf.best_distance), 
      .motion_vector_x(main_intf.motion_vector_x), 
      .motion_vector_y(main_intf.motion_vector_y),  
      .process_completed(main_intf.process_completed)
  );
endmodule


`timescale 1ns/10ps

module top_testbench();

  wire [7:0] best_distance;
  wire [3:0] motion_vector_x, motion_vector_y;

  reg clk;
  reg start_signal;

  reg [7:0] ref_mem_array[0:255]; 
  reg [7:0] search_mem_array[0:1023];
  integer expected_motion_x, expected_motion_y;
  integer i, j;
  integer signed x, y;
  wire [7:0] ref_data, search_data1, search_data2;
  wire [7:0] address_ref;
  wire [9:0] address_search1, address_search2;
  wire process_completed;

  // Device Under Test (DUT)
  top_level dut (
    .best_distance(best_distance),
    .motion_vector_x(motion_vector_x),
    .motion_vector_y(motion_vector_y),
    .clk(clk),
    .start_signal(start_signal),
    .address_ref(address_ref),
    .address_search1(address_search1),
    .address_search2(address_search2),
    .ref_data(ref_data),
    .search_data1(search_data1),
    .search_data2(search_data2),
    .process_completed(process_completed)
  );

  // Memory Instances
  ref_memory ref_mem_inst(.clk(clk), .address_ref(address_ref), .ref_data(ref_data));
  search_memory search_mem_inst(.clk(clk), .address_search1(address_search1), .address_search2(address_search2), .search_data1(search_data1), .search_data2(search_data2));

  // Clock Generation
  always #10 clk = ~clk;

  initial begin
    $vcdpluson;
    $monitor ("***** Time=%5d ns, clk=%b, start_signal=%b, best_distance=%b, motion_vector_x=%d, motion_vector_y=%d, count=%d *****", $time, clk, start_signal, best_distance, motion_vector_x, motion_vector_y, dut.ctrl_u.count);

    // Randomize search memory
    foreach (search_mem_array[i]) begin
        search_mem_array[i] = $urandom_range(0, 255);
    end

    // Randomize expected motion vectors
    expected_motion_x = $urandom_range(0, 15) - 8;    
    expected_motion_y = $urandom_range(0, 15) - 8;

    // Extract reference memory from search memory for expected motion vectors
    foreach (ref_mem_array[i]) begin
        ref_mem_array[i] = search_mem_array[32*8 + 8 + (((i/16) + expected_motion_y) * 32) + ((i%16) + expected_motion_x)];
        $display("Time=%5d ns, expected_motion_x=%0d, expected_motion_y=%0d, ref_mem_array[%d]=%0h", $time, expected_motion_x, expected_motion_y, i, ref_mem_array[i]);
    end

    // Initialize memories
    foreach (ref_mem_inst.ref_memory_array[i]) begin
        ref_mem_inst.ref_memory_array[i] = ref_mem_array[i];
    end
    foreach (search_mem_inst.search_memory_array[i]) begin
        search_mem_inst.search_memory_array[i] = search_mem_array[i];
    end

    // Initialize signals
    clk = 1'b0;
    start_signal = 1'b0;

    @(posedge clk); #10;
    start_signal = 1'b1;

    for (i = 0; i < 4112; i = i + 1) begin
        if (dut.comp_u.newBest == 1'b1) begin
            $display("***** New Result Detected! *****");
            $display("Iteration %0d: New Results Detected", i);
        end
        @(posedge clk); #10;
    end

    start_signal = 1'b0;

    @(posedge clk); #10;

    if (motion_vector_x >= 8)
        x = motion_vector_x - 16;
    else
        x = motion_vector_x;

    if (motion_vector_y >= 8)
        y = motion_vector_y - 16;
    else
        y = motion_vector_y;

    // Print test results
    if (best_distance == 8'b11111111) begin
        $display("***** Reference Memory Not Found in the Search Window! *****");
    end else begin
        if (best_distance == 8'b00000000) begin
            $display("***** Perfect Match Found for Reference Memory in the Search Window *****");
            $display("BestDist = %d, motion_x = %d, motion_y = %d, expected_motion_x = %d, expected_motion_y = %d", best_distance, x, y, expected_motion_x, expected_motion_y);
        end else begin
            $display("***** Non-perfect Match Found for Reference Memory in the Search Window *****");
            $display("BestDist = %d, motion_x = %d, motion_y = %d, expected_motion_x = %d, expected_motion_y = %d", best_distance, x, y, expected_motion_x, expected_motion_y);
        end
    end

    if (x == expected_motion_x && y == expected_motion_y) begin
        $display("***** DUT Motion Outputs Match Expected Motions *****");
        $display("DUT motion_x = %d, DUT motion_y = %d, expected_motion_x = %d, expected_motion_y = %d", x, y, expected_motion_x, expected_motion_y);
    end else begin
        $display("***** DUT Motion Outputs Do Not Match Expected Motions *****");
        $display("DUT motion_x = %d, DUT motion_y = %d, expected_motion_x = %d, expected_motion_y = %d", x, y, expected_motion_x, expected_motion_y);
    end

    $display("***** All Tests Completed *****");

    $finish;
  end

  // Dump file for offline viewing
  initial begin
    $dumpfile("top.dump");
    $dumpvars(0, top_testbench);
  end

endmodule
