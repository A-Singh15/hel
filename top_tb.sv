`timescale 1ns/1ps
`include "interfaces.sv"
`include "transaction_class.sv"
`include "driver.sv"
`include "monitor.sv"
`include "generator.sv"
`include "evaluation.sv"
`include "environment.sv"
`include "test.sv"


module top_tb();
    bit clk;
    always #10 clk = ~clk;

    initial begin
        $display("********** TB Start **********");
        mem_intf.start = 1'b0;
        repeat(2) @(posedge clk);   
        mem_intf.start = 1'b1;
    end

    main_if mem_intf(clk);
    ref_memory memR_u(.clk(clk), .address_ref(mem_intf.address_ref), .ref_data(mem_intf.R));
    search_memory memS_u(.clk(clk), .address_search1(mem_intf.address_search1), .address_search2(mem_intf.address_search2), .search_data1(mem_intf.S1), .search_data2(mem_intf.S2));
    
    test_program Motion_Estimator(mem_intf);

    initial begin
        $vcdpluson();
        $dumpfile("dump.vcd");
        $dumpvars;
    end

    top dut(
        .clk(mem_intf.clk),
        .start_signal(mem_intf.start),
        .best_distance(mem_intf.BestDist),
        .motion_vector_x(mem_intf.motionX),
        .motion_vector_y(mem_intf.motionY),
        .address_ref(mem_intf.address_ref),
        .address_search1(mem_intf.address_search1),
        .address_search2(mem_intf.address_search2),
        .ref_data(mem_intf.R),
        .search_data1(mem_intf.S1),
        .search_data2(mem_intf.S2),
        .process_completed(mem_intf.completed)
    );

    bind dut ME_assertions assertion_ME(
        .clk(mem_intf.clk),
        .start(mem_intf.start),
        .BestDist(mem_intf.BestDist),
        .motionX(mem_intf.motionX),
        .motionY(mem_intf.motionY),
        .completed(mem_intf.completed)
    );
endmodule
